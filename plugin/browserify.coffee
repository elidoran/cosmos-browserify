Browserify = Npm.require 'browserify'

# use custom envify so we can specify the env based on the meteor command used
envify = Npm.require 'envify/custom'

# use exorcist transform to extract source map data
exorcist = Npm.require 'exorcist'

# get 'stream' to use PassThrough to provide a Buffer as a Readable stream
stream = Npm.require 'stream'

fs = Npm.require 'fs'

processFile = (step) ->

  # check for extension as filename
  checkFilename step

  # get options for Browserify
  browserifyOptions = getBrowserifyOptions step

  # create a browserify instance passing our readable stream as input,
  # and options object for debug and the basedir
  browserify = Browserify [getReadable(step)], browserifyOptions

  # extract envify tranform's options so it isn't used in loop
  envifyOptions = browserifyOptions.transforms.envify
  delete browserifyOptions.transforms.envify

  # run each transform
  for own transformName, transformOptions of browserifyOptions.transforms
    browserify.transform transformName, transformOptions

  # run the envify transform
  browserify.transform envify envifyOptions

  # have browserify process the file and include all required modules.
  # we receive a readable stream as the result
  bundle = browserify.bundle()

  # set the readable stream's encoding so we read strings from it
  bundle.setEncoding('utf8')

  # extract the source map content from the generated file to give to Meteor
  # explicitly by piping bundle thru `exorcist`
  mapFileName = step.fullInputPath+'.map'
  bundle = bundle.pipe exorcist mapFileName, step.pathForSourceMap

  try # try-catch for browserify errors
    # call our wrapped function with the readable stream as its argument
    string = getString bundle

    # read the generated source map from the file
    sourceMap = fs.readFileSync mapFileName, 'utf8'
    fs.unlinkSync mapFileName

    # now that we have the compiled result as a string we can add it using CompileStep
    # inside try-catch because this shouldn't run when there's an error.
    step.addJavaScript
      path:       step.inputPath  # name of the file
      sourcePath: step.inputPath  # use same name, we've just browserified it
      data:       string          # the actual browserified results
      sourceMap:  sourceMap
      bare:       step?.fileOptions?.bare

  catch e
    # output error via CompileStep#error()
    # convert it to a string and then remove the 'Error: ' at the beginning.
    step.error
      message:e.toString().substring 7
      sourcePath: step.inputPath


# add our function as the handler for files ending in 'browserify.js'
Plugin.registerSourceHandler 'browserify.js', processFile

# add a source handler for config files so that they are watched for changes
Plugin.registerSourceHandler 'browserify.options.json', ->

getBasedir = (step) ->

  # basedir should point to the '.npm/package' folder containing the npm modules.
  # step.fullInputPath is the full path to our browserify.js file. it may be:
  #   1. in a package
  #   2. in the app itself
  # for both of the above it also may be:
  #   1. in the root (of package or app)
  #   2. in a subfolder
  # NOTE:
  #   the app doesn't have npm support, so, no .npm/package.
  #   using meteorhacks:npm creates a package to contain the npm modules.
  #   so, if the browserify.js file is an app file, then let's look for
  #   packages/npm-container/.npm/package

  # the basedir tail depends on whether this file is in the app or a package
  # for an app file, we're going to assume they are using meteorhacks:npm
  tail = if step?.packageName? then '.npm/package' else 'packages/npm-container/.npm/package'

  #   CompileStep has the absolute path to the file in `fullInputPath`
  #   CompileStep has the package/app relative path to the file in `inputPath`
  #   basedir is fullInputPath with inputPath replaced with the tail
  basedir = step.fullInputPath[0...-(step.inputPath.length)] + tail

  # TODO: use fs.existsSync basedir
  # could print a more helpful message to user than the browserify error saying
  # it can't find the module at this directory. can suggest checking package.js
  # for Npm.depends(), or, if an app file, adding meteorhacks:npm and checking
  # packages.json.

  return basedir

getBrowserifyOptions = (step) ->

  # empty user options to fill from file, if it exists
  userOptions = {}

  # look for a file with the same name, but .browserify.options.json extension
  optionsFileName = step.fullInputPath[0...-2] + 'options.json'

  if fs.existsSync optionsFileName
    try
      # read json file and convert it into an object
      userOptions = JSON.parse fs.readFileSync optionsFileName, 'utf8'
    catch e
      step.error
        message: 'Couldn\'t read JSON data: '+e.toString()
        sourcePath: step.inputPath

  # sane defaults for options; most important is the baseDir
  defaultOptions =
    # Browserify will look here for npm modules
    basedir: getBasedir(step)

    # must be true to produce source map which we extract via exorcist and
    # provide to CompileStep
    debug: true

    # put the defaults for envify transform in here as well
    # TODO: have an option which disables using envify
    transforms:
      envify:
        NODE_ENV: if getDebug() then 'development' else 'production'
        _:'purge'

  # merge user options with defaults
  _.defaults userOptions, defaultOptions

  # when they supply transforms it clobbers the envify defaults because
  # _.defaults works only on top level keys.
  # so, if there's no envify then set the default options for it
  userOptions.transforms?.envify ?= defaultOptions.transforms.envify

  return userOptions

checkFilename = (step) ->

  if step.inputPath is 'browserify.js'
    console.log 'WARNING: using \'browserify.js\' as full filename may stop working.' +
      ' See Meteor Issue #3985. Please add something before it like: client.browserify.js'

getDebug = ->
  debug = true

  # check args used
  for key in process.argv
    # if 'meteor bundle file' or 'meteor build path'
    if key is 'bundle' or key is 'build'
      debug = '--debug' in process.argv
      break;

  return debug

getReadable = (step) ->

  # Browserify accepts a Readable stream as input, so, we'll use a PassThrough
  # stream to hold the Buffer
  readable = new stream.PassThrough()

  # Meteor's CompileStep provides the file as a Buffer from step.read()
  # add the buffer into the stream and end the stream with one call to end()
  readable.end step.read()

  return readable

# async function for reading entire bundle output into a string
# wrap to convert to a synchronous function
getString = Meteor.wrapAsync (bundle, cb) ->

  # holds all data read from bundle
  string = ''

  # concatenate data chunk to string
  bundle.on 'data', (data) -> string += data

  # when we reach the end, call Meteor.wrapAsync's callback with string result
  bundle.once 'end', -> cb undefined, string  # undefined = error

  # when there's an error, give it to the callback
  bundle.once 'error', (error) -> cb error
