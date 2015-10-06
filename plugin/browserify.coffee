# wasn't able to override Npm in testing like I used to. This solves that.
npm = share.Npm ? Npm

Browserify = npm.require 'browserify'

# use custom envify so we can specify the env based on the meteor command used
envify = npm.require 'envify/custom'

# use exorcist transform to extract source map data
exorcistStream = npm.require 'exorcist-stream'

# use to hold file content as readable and get source map as writable
strung = npm.require 'strung'

# use OS agnostic and fiber friendly versions of fs and path
fs = Plugin.fs
path = Plugin.path

# # # NOTES FOR getNpmDir()
#
# finding the root is even more complicated in the new Build API, yay.
# let's try yet another tactic to overcome the API's missing directory information
# where are the npm modules?
# A. app file in a running app
#   1. packages/npm-container/.npm/package/node_modules
#   2. node_modules (if someone installs them in the app manually)
# B. package file in a running app
#   1. packages/packageName/.npm/package/node_modules
#   2. packages/username:packageName/.npm/package/node_modules
#   3. ~/.meteor/packages/username_packageName/version/npm/node_modules
# C. package file in a package being tested via `meteor test-packages`
#   1. .npm/package/node_modules - when called like `meteor test-packages ./`
#   2. otherwise the root is where the referenced packages are, which can be anything

# helps getNpmDir by searching even deeper into the InputFile's properties
getNpmDirForPackage = (isopackCache, name) ->
  pkg = isopackCache._packageMap._map[name]
  if pkg.kind is 'local' then pkg.packageSource.npmCacheDirectory

  else # it's a versioned package... doesn't have a packageSource object.
    builds = isopackCache._isopacks[name].unibuilds
    for build in builds when build.arch is 'os' # the 'os' one has nodeModulesPath
      return build.nodeModulesPath[...-12]

getNpmDir = (file) ->
  packageName = file.getPackageName()
  # way deep down there is some useful properties to locate the npm directory
  isopackCache = file._resourceSlot.packageSourceBatch.processor.isopackCache

  # package file, get npm dir from the package's properties
  if packageName? then getNpmDirForPackage isopackCache, packageName

  # app file, try meteorhacks:npm's npm-container package...
  else if isopackCache._packageMap._map?['npm-container']?
    getNpmDirForPackage isopackCache, 'npm-container'

  else '.' # else, they'd better have `node_modules` in the root of the app


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


  compileOneFile: (file, files) ->

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

    # create a stream to gather the source map
    sourceMapStream = strung()

    # extract the source map content from the generated file to give to Meteor
    # explicitly by piping bundle thru `exorcist-stream`
    exorcisedBundle = bundle.pipe exorcistStream sourceMapStream, file.getDisplayPath()

    # store reference to original bundle to access it elsewhere
    exorcisedBundle.originalBundle = bundle

    # store stream which gathers the source map for later use
    exorcisedBundle.sourceMapStream = sourceMapStream

    return exorcisedBundle


  getCompileResult: (bundle) ->

    result = source: @getString bundle

    # add source map to result
    result.sourceMap = bundle.sourceMapStream.string

    return result


  getBrowserifyOptions: (file, option) ->

    # empty user options to fill from file, if it exists
    userOptions = {}

    if option?.input?
      userOptions = JSON.parse option.input.getContentsAsString()

    # sane defaults for options; most important is the baseDir
    defaultOptions =
      # Browserify will look here for npm modules
      basedir: Plugin.convertToOSPath getNpmDir file

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

    # 1. Browserify accepts a Readable stream as input, so, we'll use a `strung`
    # 2. Meteor's InputFile provides content as a Buffer or String, we'll get a string
    # 3. Browserify errors when it gets an empty readable stream, so ensure content

    # get the string content
    string = file.getContentsAsString()

    # creat `strung` stream with string content
    # , or, if it's empty, then a single newline character
    strung if string?.length > 0 then string else '\n'

  # async function for reading entire bundle output into a string
  # wrap to convert to a synchronous function
  getString: Meteor.wrapAsync (bundle, cb) ->

    # create a stream to collect the source
    source = strung()

    # when source is finished collecting, provide it to the callback
    source.on 'finish', -> cb undefined, source.string

    # when there's an error on any of the streams give it to the callback
    source.on 'error', cb
    bundle.originalBundle.once 'error', cb
    bundle.sourceMapStream.once 'error', cb
    bundle.once 'error', cb

    # pipe bundle (source result) into source stream
    bundle.pipe source

Plugin.registerCompiler
  # have it watch the options files as well. we'll use their InputFile to read them, too
  extensions:['browserify.js', 'browserify.options.json'], -> new BrowserifyPlugin()

# make available to tests
share.BrowserifyPlugin = BrowserifyPlugin
