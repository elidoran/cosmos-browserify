### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Mocks for:
#  1. Npm.require to deliver both stream and browserify mocks
#  2. Meteor.wrapAsync
#
# Note the @ making the variables package scoped
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

# store results for test to verify with test.equal
@Result = {}

# plugin calls 'new stream.PassThrough()' so give it a class to instantiate
class PassThroughMock
  constructor: ->
    # store this was run
    Result.passThrough = run:true
    # store this is our test object so we can check for it
    this.isTestPassThrough = true
  # end gets our mock Buffer, a string, and stores it in results
  end: (buffer) -> Result.passThrough.buffer = buffer

# store objects to return in Npm.require calls
required =
  # instead of node's stream module, all we need is PassThrough, give the mock
  stream: PassThrough:PassThroughMock

  # instead of the real browserify
  browserify: (array, options) ->
    # store into results
    Result.browserify = array: array, options: options
    # return this mock when browserify.bundle() is called
    return bundle: ->
      # store this was run
      Result.browserify.bundle = true
      # return a mock readable stream
      return {
        # store the encoding it's told to use
        setEncoding: (encoding) -> Result.browserify.encoding = encoding

        # on 'data', fn => appends string data to string variable
        on: (eventType, fn) ->
          # store what its called with
          Result.browserify.on = event:eventType, fn:fn
          # if it's the correct event type then call the function now with a string
          if eventType is 'data' then fn 'test data'

        # once 'end', fn => calls the callback
        once: (eventType, fn) ->
          # store what its called with
          Result.browserify.once = event:eventType, fn:fn
          # if it's the correct event type then call the function now
          if eventType is 'end' then fn()
      }

# mock this by returning our mock objects instead
@Npm =
  require: (name) -> required[name]

# mock a CompileStep object. accept options to tests can supply different values
@Plugin =
  compileStep: (options) ->
    # create the step to return (allows referencing it in read())
    # use values set in `options` or defaults
    step =
      # step.read() is called to get the file contents to give browserify.
      # we'll just use a string for testing.
      read: ->
        # store the buffer we're returning, which also implies this was run
        step.readBuffer = options?.buffer ? 'CompileStep#read() Buffer'
        return step.readBuffer
      inputPath: options?.inputPath ? 'file.browserify.js'
      fullInputPath:
        options?.fullInputPath ? '/full/path/to/app/packages/file.browserify.js'
      # store the info into the step so it can be tested
      addJavaScript: (info) -> step.js = info

    # return the step we created
    return step

  # mock this function and get our plugin function to call
  registerSourceHandler: (extension, fn) -> Plugin.fn = fn

# don't use @Meteor as with other Mocks because `Meteor` exists in test client
# instead, replace the wrapAsync with our version, which seems not to affect
# the test client.
# fn is the wrapped function: getString
Meteor.wrapAsync = (fn) ->
  # bundle is our mocked bundle object
  return (bundle) ->
    # call getString with mocked bundle and our callback which stores the string
    fn bundle, (error, string) -> Result.bundleString = string
    # return the string result back into plugin
    return Result.bundleString
