
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

  # test building browserify
  test.equal Result?.browserify?, true, 'must run browserify function'
  test.equal Result.browserify?.array.length, 1, 'browserify gets [readable], length should be 1'
  test.equal Result.browserify?.array[0]?.isTestPassThrough, true, 'should receive our test PassThrough'
  options = debug:true, basedir:'/full/path/to/app/packages/.npm/package'
  test.equal Result.browserify?.options, options

  # test bundling with browserify and reading its result
  test.equal Result.browserify?.bundle, true, 'must run browserify.bundle()'
  test.equal Result.browserify?.encoding, 'utf8'
  test.equal Result.browserify?.on?.event, 'data', 'must call bundle.on \'data\''
  test.equal Result.browserify?.once?.event, 'end', 'must call bundle.on\'end\''
  test.equal Result?.bundleString, 'test data'

  # test what's given to CompileStep.addJavaScript
  test.equal compileStep.js.path, 'file.browserify.js'
  test.equal compileStep.js.sourcePath, 'file.browserify.js'
  test.equal compileStep.js.data, 'test data'


# TODO: test having an error in the browserify.bundle() call
