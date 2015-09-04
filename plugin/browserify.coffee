# wasn't able to override Npm in testing like I used to. This solves that.
npm = share.Npm ? Npm

Browserify = npm.require 'browserify'

# use custom envify so we can specify the env based on the meteor command used
envify = npm.require 'envify/custom'

# use exorcist transform to extract source map data
exorcist = npm.require 'exorcist'

# get 'stream' to use PassThrough to provide a Buffer as a Readable stream
stream = npm.require 'stream'

# use OS agnostic and fiber friendly versions of fs and path
fs = Plugin.fs
path = Plugin.path

# extend standard compiler class to make implementation easier.
# it will make us process the *.browserify.js files, and, provide the
# *.browserify.options.json files as InputPath instances to get the content.
# and it does the caching :)
class BrowserifyPlugin extends MultiFileCachingCompiler

  constructor: () ->
    super
      compilerName: 'CosmosBrowserify'
      defaultCacheSize: 1024*1024*10 # TODO: what size??


  # this is how it knows which files we want to process, and which are referenced
  isRoot: (file) -> file.getExtension() is 'browserify.js'


  getCacheKey: (file) ->
    return [
      file.getSourceHash()
      file.getDeclaredExports()
      file.getFileOptions()
      # TODO: modified time of npm-shrinkwrap.json file OR hash of contents
    ]


  compileResultSize: (compileResult) ->
    compileResult.source.length + compileResult.sourceMap.length


  addCompileResult: (file, compileResult) ->
    file.addJavaScript
      path: file.getPathInPackage(),
      sourcePath: file.getPathInPackage(),
      data: compileResult.source,
      sourceMap: compileResult.sourceMap


  getOptionInfo: (file, files) ->

    # generate path to options file from `file`, then get options InputFile
    packageName = file.getPackageName()

    # app file has no package, it's null, so, use empty string
    packageName ?= ''

    # replace 'js' with 'options.json'
    tail = file.getPathInPackage()[...-2] + 'options.json'

    # combine to form the weird path to the options file
    optionFileKey = "{#{packageName}}/#{tail}"

    # use it to get the InputFile representing the options file
    optionInputFile = files.get optionFileKey

    # return the results combined
    return option =
      input:optionInputFile
      ref: if optionInputFile? then [optionFileKey] else []
      package: file.getFileOptions()


  #  1. returns '' for an app file, unless altPackageName exists
  #  2. returns 'packages/packageFolderName' for package files
  #  3. when altPackageName exists and it's an app file, it's used as the packageFolderName
  getRoot: (altPackageName) ->

    root = @getPackageName()
    if root?
      index = root.indexOf(':') + 1
      root = 'packages/' + root[index...]
    else if altPackageName?
      root = 'packages/' + altPackageName
    else
      root = ''

    return root


  compileOneFile: (file, files) ->
    # bind a helper function to the file
    file.getRoot = @getRoot.bind file

    # get the option InputFile, its import path in an array, and file.getFileOptions()
    option = @getOptionInfo file, files

    try # try-catch for browserify errors

      # get options for Browserify
      browserifyOptions = @getBrowserifyOptions file, option

      # create a browserify instance passing our readable stream as input,
      # and options object for debug and the basedir
      browserify = Browserify [@getReadable(file)], browserifyOptions

      # apply browserify tranforms specified in options file, and envify
      @applyTransforms browserify, browserifyOptions

      # process bundle with exorcist to get source map
      bundle = @getBundle browserify, file

      # get source string and sourceMap string from bundle
      compileResult = @getCompileResult bundle

      # return results in object which can be cached/stored/ref'd
      return compileResult:compileResult, referencedImportPaths:option.ref

    catch e
      file.error message:e.message

    return


  applyTransforms: (browserify, browserifyOptions) ->

    # extract envify tranform's options so it isn't used in loop
    envifyOptions = browserifyOptions.transforms.envify
    delete browserifyOptions.transforms.envify

    # run each transform
    for own transformName, transformOptions of browserifyOptions.transforms
      browserify.transform transformName, transformOptions

    # run the envify transform now (so it's last)
    browserify.transform envify envifyOptions

    return


  getBundle: (browserify, file) ->

    # have browserify process the file and include all required modules.
    # we receive a readable stream as the result
    bundle = browserify.bundle()

    # set the readable stream's encoding so we read strings from it
    bundle.setEncoding('utf8')

    # # extract the source map content from the generated file to give to Meteor
    # # explicitly by piping bundle thru `exorcist`
    # get path to file in OS style, resolve against CWD with app/package root, and file path
    mapFilePath = Plugin.convertToOSPath path.resolve file.getRoot(), file.getPathInPackage() + '.map'

    # pipe thru exorcist transform with display path as the 'source map url'
    exorcisedBundle = bundle.pipe exorcist mapFilePath, file.getDisplayPath()

    # store reference to original bundle to access it elsewhere
    exorcisedBundle.originalBundle = bundle

    # store path to map file so we can delete it later
    exorcisedBundle.mapFilePath = mapFilePath

    return exorcisedBundle


  getCompileResult: (bundle) ->

    result = source: @getString bundle

    # read the generated source map from the file
    sourceMap = fs.readFileSync bundle.mapFilePath, encoding:'utf8'

    # delete source map file
    fs.unlinkSync bundle.mapFilePath

    # add source map to result
    result.sourceMap = sourceMap

    return result


  getBasedir: (file) ->

    # get app/package root folder for file, use npm-container when an app file.
    folderPath = file.getRoot('npm-container')
    # convert to OS style, resolve it against CWD, use real folder name
    Plugin.convertToOSPath path.resolve folderPath, '.npm/package'


  getBrowserifyOptions: (file, option) ->

    # empty user options to fill from file, if it exists
    userOptions = {}

    if option?.input?
      userOptions = JSON.parse option.input.getContentsAsString()

    # sane defaults for options; most important is the baseDir
    defaultOptions =
      # Browserify will look here for npm modules
      basedir: @getBasedir file

      # must be true to produce source map which we extract via exorcist and
      # provide to CompileStep
      debug: true

      # put the defaults for envify transform in here as well
      # TODO: have an option which disables using envify
      transforms:
        envify:
          NODE_ENV: if @getDebug() then 'development' else 'production'
          _:'purge'

    # merge user options with defaults (option.package is file.getFileOptions())
    _.defaults userOptions, option.package, defaultOptions

    # when they supply transforms it clobbers the envify defaults because
    # _.defaults works only on top level keys.
    # so, if there's no envify then set the default options for it
    userOptions.transforms?.envify ?= defaultOptions.transforms.envify

    return userOptions


  getDebug: ->

    debug = true

    # check args used
    for key in process.argv
      # if 'meteor bundle file' or 'meteor build path'
      if key is 'bundle' or key is 'build'
        debug = '--debug' in process.argv
        break;

    return debug


  getReadable: (file) ->

    # Browserify accepts a Readable stream as input, so, we'll use a PassThrough
    # stream to hold the Buffer
    readable = new stream.PassThrough()

    # Meteor's InputFile provides content as a Buffer or String
    # add the buffer into the stream and end the stream with one call to end()
    readable.end file.getContentsAsBuffer()

    return readable

  # async function for reading entire bundle output into a string
  # wrap to convert to a synchronous function
  getString: Meteor.wrapAsync (bundle, cb) ->

    # holds all data read from bundle
    string = ''

    # concatenate data chunk to string
    bundle.on 'data', (data) -> string += data

    # when we reach the end, call Meteor.wrapAsync's callback with string result
    bundle.once 'end', -> cb undefined, string  # undefined = error

    # when there's an error, give it to the callback
    # NOTE:
    #  after piping bundle into exorcist transform the once('error') doesn't
    #  work. fixed it by storing original bundle as a property and registering
    #  the event callback on that instead.
    bundle.originalBundle.once 'error', (error) -> cb error

Plugin.registerCompiler
  # have it watch the options files as well. we'll use their InputFile to read them, too
  extensions:['browserify.js', 'browserify.options.json'], -> new BrowserifyPlugin()

# make available to tests
share.BrowserifyPlugin = BrowserifyPlugin
