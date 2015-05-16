Browserify = Npm.require 'browserify'

# get 'stream' to use PassThrough to provide a Buffer as a Readable stream
stream     = Npm.require 'stream'

# TODO: inputPath may include directories we need to strip for basedir
processFile = (step) ->

  # create a browserify instance passing our readable stream as input,
  # and options object for debug and the basedir
  browserify = Browserify [getReadable(step)],
    # browserify options
    basedir = getBasedir(step) # Browserify looks here for npm modules
    debug = getDebug(step)     # Browserify creates internal source map

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
  # CompileStep has the absolute path to the file in `fullInputPath`
  # CompileStep has the name of the file in `inputPath`
  # basedir is fullInputPath with inputPath replaced with '.npm/package'
  basedir = step.fullInputPath.slice(0, -(step.inputPath.length)) + '.npm/package'

getDebug = (step) ->
  debug = true

  # check args used
  for key in process.argv
    # if 'meteor bundle file' or 'meteor build file'
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
