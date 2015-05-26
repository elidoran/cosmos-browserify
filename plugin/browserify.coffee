Browserify = Npm.require 'browserify'
envify = Npm.require 'envify'

# get 'stream' to use PassThrough to provide a Buffer as a Readable stream
stream     = Npm.require 'stream'

processFile = (step) ->

  # when true it's dev, when false it's production
  debug = getDebug step

  # create a browserify instance passing our readable stream as input,
  # and options object for debug and the basedir
  browserify = Browserify [getReadable(step)],
    # browserify options
    basedir: getBasedir(step) # Browserify looks here for npm modules
    debug: debug     # Browserify creates internal source map

  # use the envify transform to replace instances of `process.env`
  # with strings
  browserify.transform envify

  # have browserify process the file and include all required modules.
  # we receive a readable stream as the result
  bundle = browserify.bundle()

  # set the readable stream's encoding so we read strings from it
  bundle.setEncoding('utf8')

  # use Meteor.wrapAsync to wrap `getString` so it's done synchronously
  wrappedFn = Meteor.wrapAsync getString

  try # try-catch for browserify errors

    # call our wrapped function with the readable stream as its argument
    string = wrappedFn bundle

    # now that we have the compiled result as a string we can add it using CompileStep
    # inside try-catch because this shouldn't run when there's an error.
    step.addJavaScript
      path:       step.inputPath  # name of the file
      sourcePath: step.inputPath  # use same name, we've just browserified it
      data:       string          # the actual browserified results
      bare:       step?.fileOptions?.bare

  catch e
    # output error via CompileStep#error()
    # convert it to a string and then remove the 'Error: ' at the beginning.
    step.error message:e.toString().substring 7

# add our function as the handler for files ending in 'browserify.js'
Plugin.registerSourceHandler 'browserify.js', processFile

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
  basedir = step.fullInputPath.slice(0, -(step.inputPath.length)) + tail

  # TODO: use fs.existsSync basedir
  # could print a more helpful message to user than the browserify error saying
  # it can't find the module at this directory. can suggest checking package.js
  # for Npm.depends(), or, if an app file, adding meteorhacks:npm and checking
  # packages.json.

  return basedir

getDebug = ->
  debug = true

  # check args used
  for key in process.argv
    # if 'meteor bundle file' or 'meteor build file'
    if key is 'bundle' or key is 'build'
      debug = '--debug' in process.argv
      break;

  return debug

getEnvifyOptions = (debug, step) ->

  envifyOptions =
    NODE_ENV: if debug then 'development' else 'production'
    # purge by default because we're running it this once
    _: 'purge'

  # TODO:
  # use step to know which file we're processing so we can get config options
  # for it and override env value, or purge value

  return envifyOptions

getReadable = (step) ->

  # Browserify accepts a Readable stream as input, so, we'll use a PassThrough
  # stream to hold the Buffer
  readable = new stream.PassThrough()

  # Meteor's CompileStep provides the file as a Buffer from step.read()
  # add the buffer into the stream and end the stream with one call to end()
  readable.end step.read()

  return readable

# async function for reading entire bundle output into a string
getString = (bundle, cb) ->

  # holds all data read from bundle
  string = ''

  # concatenate data chunk to string
  bundle.on 'data', (data) -> string += data

  # when we reach the end, call Meteor.wrapAsync's callback with string result
  bundle.once 'end', -> cb undefined, string  # undefined = error

  # when there's an error, give it to the callback
  bundle.once 'error', (error) -> cb error
