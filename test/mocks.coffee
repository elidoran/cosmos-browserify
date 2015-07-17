### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Mocks for:
#  1. Npm.require to deliver both stream and browserify mocks
#  2. Meteor.wrapAsync
#
# Note the @ making the variables package scoped
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

# when testing `process` is undefined, so, define it
@process = argv:[]

# store results for test to verify with test.equal
@Result = transforms:{}

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

  'envify/custom': (options) -> Result.transforms.envify = options

  'exorcist': (outputName, sourceMapURL) ->
    Result.exorcist = name:outputName,url:sourceMapURL
    return 'exorcist'

  # instead of the real browserify
  browserify: (array, options) ->
    # store into results
    Result.browserify = array: array, options: options
    # return this mock when browserify.bundle() is called
    return browserifyObject =
      bundle: ->
        # store this was run
        Result.browserify.bundle = true
        # return a mock readable stream
        return bundleObject =
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
            Result.browserify.once ?= {}
            Result.browserify.once[eventType] = fn
            # only call the end() fn when we're not testing an error
            if eventType is 'end' and not Result?.errorWanted then fn()

            # only call the error() fn when we're testing an error
            if eventType is 'error' and Result?.errorWanted then fn 'test error'

          # pipe to exorcist / writable stream (cache file)
          pipe: (to) ->
            Result.piped ?= []
            Result.piped.push to
            return this

      # store received transform name and options
      transform: (transformName, transformOptions) ->
        if typeof transformName is 'string'
          Result.transforms[transformName] = transformOptions
        # else it's an object, so the envify object.
        # we already stored its options in the mock returned by require
        # and transformOptions here is undefined. so, do nothing.


  fs:
    existsSync: (name) ->
      Result.existsSync ?= {}
      Result.existsSync[name] = true
      if name is '/full/path/to/app/packages/file.browserify.options.json'
        return Result?.optionsFile?
      if name is '/full/path/to/app/packages/file.browserify.js.cached'
        return Result?.cacheFile?

      return false

    readFileSync: (name, options) ->
      Result.readFileSync ?= {}
      Result.readFileSync[name] = options
      if name?[-4...] is '.map'
        'source map'
      else
        if Result?.optionsFile? then Result?.optionsFile else null

    createWriteStream: (fileName, options) ->
      Result.writeStream = name:fileName, options:options
      return 'cache write stream'

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
      pathForSourceMap: options?.pathForSourceMap ? 'file.browserify.js'
      packageName: if options?.noPackageName then null else (options?.packageName ? 'cosmos:test')
      # store the info into the step so it can be tested
      addJavaScript: (info) -> step.js = info
      error: (info) -> Result.errorReceived = info

    # return the step we created
    return step

  # mock this function and get our plugin function to call
  registerSourceHandler: (extension, fn) ->
    if extension is "browserify.js"
      Plugin.fn = fn

# don't use @Meteor as with other Mocks because `Meteor` exists in test client
# instead, replace the wrapAsync with our version, which seems not to affect
# the test client.
# fn is the wrapped function: getString
Meteor.wrapAsync = (fn) ->
  # bundle is our mocked bundle object
  return (bundle) ->
    result = {}
    # call getString with mocked bundle and our callback which stores the string
    fn bundle, (error, string) -> result = error:error, string:string
    # return result string to plugin, or throw error
    if result?.error then throw new Error result.error
    return result.string
