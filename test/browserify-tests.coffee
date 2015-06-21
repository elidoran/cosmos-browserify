clearPreviousResults = ->
  delete Result[key] for key of Result
  Result.transforms = {}

defaultOptions = ->
  basedir:'/full/path/to/app/packages/.npm/package'
  debug:true
  transforms:{}

# test the usual successful run
Tinytest.add 'test processFile', (test) ->

  # get the function registered with Plugin.registerSourceHandler
  processFile = Plugin.fn

  # create our mock CompileStep
  compileStep = Plugin.compileStep()

  # call our plugin function with our mock CompileStep
  processFile compileStep

  # test results
  test.equal compileStep?.readBuffer?, true, 'CompileStep.read() should be called'
  test.equal Result.passThrough.run, true, 'should create a new PassThrough'
  test.equal Result.passThrough.buffer, compileStep.readBuffer

  # test fs checked for options file and returned it
  file = '/full/path/to/app/packages/file.browserify.options.json'
  test.equal Result?.existsSync, file
  test.equal Result?.readFileSync?[file]?, false, 'shouldn\'t run fs.readFileSync on options file'

  # test building browserify
  test.equal Result?.browserify?, true, 'must run browserify function'
  test.equal Result.browserify.array?, true, 'must have an array to browserify'
  test.equal Result.browserify.array?.length, 1, 'browserify gets [readable], length should be 1'
  test.equal Result.browserify.array[0]?.isTestPassThrough, true, 'should receive our test PassThrough'
  test.equal Result.browserify?.options, defaultOptions()

  # test envify transform
  test.equal Result?.transforms?.envify?, true, 'transform should be called with envify'
  test.equal Result.transforms.envify?.NODE_ENV, 'development' # testing dev mode only so far
  test.equal Result.transforms.envify?._, 'purge'

  # test bundling with browserify and reading its result
  test.equal Result.browserify?.bundle, true, 'must run browserify.bundle()'
  test.equal Result.browserify?.encoding, 'utf8'
  test.equal Result.browserify?.on?.event, 'data', 'must call bundle.on \'data\''
  test.equal Result.browserify?.once?.end?, true, 'must call bundle.once \'end\''
  test.equal Result.browserify?.once?.error?, true, 'must call bundle.once \'error\''

  # test error was *not* received by CompileStep#error()
  test.equal Result?.errorReceived?, false, 'CompileStep should *not* receive an error'
  test.equal Result?.errorReceived?.message, undefined

  # test exorcist
  file = '/full/path/to/app/packages/file.browserify.js.map'
  test.equal Result?.exorcist?, true, 'exorcist should always be called'
  test.equal Result?.exorcist?.name, file
  test.equal Result?.exorcist?.url, 'file.browserify.js'
  test.equal Result?.exorcist?.piped, 'exorcist'
  test.equal Result?.readFileSync?[file]?, true, 'should run fs.readFileSync on the source map file'
  test.equal Result?.readFileSync?[file]?.encoding, 'utf8'

  # test what's given to CompileStep.addJavaScript
  test.equal compileStep?.js?, true, 'CompileStep should contain addJavaScript info'
  test.equal compileStep.js.path, 'file.browserify.js'
  test.equal compileStep.js.sourcePath, 'file.browserify.js'
  test.equal compileStep.js.data, 'test data'


# test options file with debug=true and a transform
Tinytest.add 'test options file', (test) ->

  clearPreviousResults()

  options = defaultOptions()

  # add exposify transform to options
  options.transforms.exposify =
    global: true
    expose:
      react: "React"

  # add imaginary transform to options so there's more in there
  options.transforms.imaginary =
    some:'value'
    and:'another'

  # supply an options file. make our options JSON content
  Result.optionsFile = JSON.stringify options

  # get the function registered with Plugin.registerSourceHandler
  processFile = Plugin.fn

  # create our mock CompileStep
  compileStep = Plugin.compileStep()

  # call our plugin function with our mock CompileStep
  processFile compileStep

  # test results
  test.equal compileStep?.readBuffer?, true, 'CompileStep.read() should be called'
  test.equal Result.passThrough.run, true, 'should create a new PassThrough'
  test.equal Result.passThrough.buffer, compileStep.readBuffer

  # test fs checked for options file and returned it
  file = '/full/path/to/app/packages/file.browserify.options.json'
  test.equal Result?.existsSync, file
  test.equal Result?.readFileSync?[file]?, true, 'should run fs.readFileSync on options file'

  # test building browserify
  test.equal Result?.browserify?, true, 'must run browserify function'
  test.equal Result.browserify.array?, true, 'must have an array to browserify'
  test.equal Result.browserify.array?.length, 1, 'browserify gets [readable], length should be 1'
  test.equal Result.browserify.array[0]?.isTestPassThrough, true, 'should receive our test PassThrough'
  test.equal Result.browserify?.options, options

  # test envify transform
  test.equal Result?.transforms?.envify?, true, 'transform should be called with envify'
  test.equal Result.transforms.envify?.NODE_ENV, 'development' # testing dev mode only so far
  test.equal Result.transforms.envify?._, 'purge'

  # test exposify transform
  test.equal Result?.transforms?.exposify?, true, 'transform should be called with exposify'
  test.equal Result.transforms.exposify.global, true
  test.equal Result.transforms.exposify?.expose?.react, 'React'

  # test imaginary transform
  test.equal Result?.transforms?.imaginary?, true, 'transform should be called with imaginary'
  test.equal Result.transforms.imaginary?.some, 'value'
  test.equal Result.transforms.imaginary?.and, 'another'

  # test bundling with browserify and reading its result
  test.equal Result.browserify?.bundle, true, 'must run browserify.bundle()'
  test.equal Result.browserify?.encoding, 'utf8'
  test.equal Result.browserify?.on?.event, 'data', 'must call bundle.on \'data\''
  test.equal Result.browserify?.once?.end?, true, 'must call bundle.once \'end\''
  test.equal Result.browserify?.once?.error?, true, 'must call bundle.once \'error\''

  # test error was *not* received by CompileStep#error()
  test.equal Result?.errorReceived?, false, 'CompileStep should *not* receive an error'
  test.equal Result?.errorReceived?.message, undefined

  # test exorcist
  file = '/full/path/to/app/packages/file.browserify.js.map'
  test.equal Result?.exorcist?, true, 'exorcist should always be called'
  test.equal Result?.exorcist?.name, file
  test.equal Result?.exorcist?.url, 'file.browserify.js'
  test.equal Result?.exorcist?.piped, 'exorcist'
  test.equal Result?.readFileSync?[file]?, true, 'should run fs.readFileSync on the source map file'
  test.equal Result?.readFileSync?[file]?.encoding, 'utf8'

  # test what's given to CompileStep.addJavaScript
  test.equal compileStep?.js?, true, 'CompileStep should contain addJavaScript info'
  test.equal compileStep.js.path, 'file.browserify.js'
  test.equal compileStep.js.sourcePath, 'file.browserify.js'
  test.equal compileStep.js.data, 'test data'


# test an error in browserify
Tinytest.add 'test with browserify error', (test) ->

  clearPreviousResults()

  # cause it to use the on error callback
  Result.errorWanted = true

  # get the function registered with Plugin.registerSourceHandler
  processFile = Plugin.fn

  # create our mock CompileStep
  compileStep = Plugin.compileStep()

  # call our plugin function with our mock CompileStep
  processFile compileStep

  # test results
  test.equal compileStep?.readBuffer?, true, 'CompileStep.read() should be called'
  test.equal Result.passThrough.run, true, 'should create a new PassThrough'
  test.equal Result.passThrough.buffer, compileStep.readBuffer

  # test fs checked for options file and returned it
  file = '/full/path/to/app/packages/file.browserify.options.json'
  test.equal Result?.existsSync, file
  test.equal Result?.readFileSync?[file]?, false, 'shouldn\'t run fs.readFileSync on options file'

  # test building browserify
  test.equal Result?.browserify?, true, 'must run browserify function'
  test.equal Result.browserify.array?, true, 'must have an array to browserify'
  test.equal Result.browserify.array?.length, 1, 'browserify gets [readable], length should be 1'
  test.equal Result.browserify.array[0]?.isTestPassThrough, true, 'should receive our test PassThrough'
  test.equal Result.browserify?.options, defaultOptions()

  # test envify transform
  test.equal Result?.transforms?.envify?, true, 'transform should be called with envify'
  test.equal Result.transforms.envify?.NODE_ENV, 'development' # testing dev mode only so far
  test.equal Result.transforms.envify?._, 'purge'

  # test bundling with browserify and reading its result
  test.equal Result.browserify?.bundle, true, 'must run browserify.bundle()'
  test.equal Result.browserify?.encoding, 'utf8'
  test.equal Result.browserify?.on?.event, 'data', 'must call bundle.on \'data\''
  test.equal Result.browserify?.once?.end?, true, 'must call bundle.once \'end\''
  test.equal Result.browserify?.once?.error?, true, 'must call bundle.once \'error\''

  # test error received by CompileStep#error()
  test.equal Result?.errorReceived?, true, 'CompileStep should receive an error'
  test.equal Result.errorReceived.message, 'test error'

# TODO: test with 'bundle' in process.argv
# TODO: test with 'build' in process.argv
# TODO: test with 'build' in process.argv and --debug
