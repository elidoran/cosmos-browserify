Browserify = Npm.require 'browserify'
stream     = Npm.require 'stream'

getString = (bundle, cb) -> # async function reading entire bundle
  string = '' # holds all as a string
  bundle.on 'data', (data) -> string += data
  bundle.on 'end', -> cb undefined, string  # undefined = error

Plugin.registerSourceHandler 'browserify.js', (step) ->
  # TODO: how to know if it's production or dev? change value of debug...
  # TODO: inputPath may include directories we need to strip for basedir
  readable = new stream.PassThrough()   # hold Buffer as Readable stream
  readable.end step.read()              # put Buffer into stream
  basedir = step.fullInputPath.slice(0, -(step.inputPath.length)) + '.npm/package'
  browserify = Browserify [readable], debug:true, basedir:basedir
  bundle = browserify.bundle()
  bundle.setEncoding('utf8')          # work with strings
  string = Meteor.wrapAsync(getString)(bundle) # wrap for sync use and call it
  step.addJavaScript                  # add result as new JS file
    path:       step.inputPath
    sourcePath: step.inputPath
    data:       string
    bare:       step?.fileOptions?.bare
