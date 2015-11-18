# 0.9.1 - 2015/11/17

1. **local package** *basedir* option handling worked despite *.npm/package* tail, now it removes that tail
2. cleaned up **published package** *basedir* option handling using a Meteor property to get *~/.meteor* location
3. final else uses `basedirOption` or `.`
4. reordered `getBrowserifyOptions()` to: defaults, option file, basedir processing, combine

# 0.9.0 - 2015/11/15

1. use basedir option to find local node_modules allowing manual `npm install` use

# 0.8.4 - 2015/11/17

1. fix searching for `nodeModulesPath` in builds

# 0.8.3 - 2015/10/30

1. upgrade Browserify from 11.1.0 to 11.2.0

# 0.8.2 - 2015/10/30

1. removed `file.getDeclaredExports()` from `getCacheKey()` to fix #29

# 0.8.1 - 2015/10/6

1. fix #24 by converting npm dir path to OS style path

# 0.8.0 - 2015/10/1

1. totally new algorithm for locating npm dir. uses deep internal properties (no bueno, but necessary)
2. uses `exorcist-stream` (forked `exorcist` with PR#26) to avoid writing source map to a file, reading the file, and then deleting the file
3. uses `strung` instead of `streams.PassThrough` as readable
4. uses `strung` instead of `on 'data'` to gather source from browserify

# 0.7.4 - 2015/09/30

1. tried another way to fix getRoot()

# 0.7.3 - 2015/09/30

1. tried another way to fix getRoot()

# 0.7.2 - 2015/09/30

1. fixed getRoot() for test-packages

# 0.7.1 - 2015/09/29

1. added ability for package directory to be any format by digging it out of InputFile's properties

# 0.7.0 - 2015/09/22

1. rewrote plugin to work with Meteor 1.2 Build API
2. updated README with note about version use
3. updated browserify to 11.1.0

# 0.5.1 - 2015/09/12

1. avoid browserify crashing from an empty readable stream by adding a newline when CompileStep.read() returns an empty Buffer.  

# 0.5.0 - 2015/07/17

1. update browserify to 10.2.4 from 9.0.8. Test pass, apps work. Seems fine.
2. accepted [PR#9](https://github.com/elidoran/cosmos-browserify/pull/9) from [stubailo](https://github.com/stubailo) removing extra indentation from some of the README's code blocks. Thank you stubailo.
3. caching both browserified result and its source map file to reuse unless rebuild is needed. See [Issue #11](https://github.com/elidoran/cosmos-browserify/issues/11)
4. README recommends app browserify file in client folder to avoid running twice
5. accepted [PR#12](https://github.com/elidoran/cosmos-browserify/pull/12) from [optilude](https://github.com/optilude) correcting options file extension type in README. Thank you optilude.
6. fixed catching browserify errors which was broken by 0.4.0

# 0.4.0 - 2015/06/21

1. accepted [PR#7](https://github.com/elidoran/cosmos-browserify/pull/7) from [stubailo](https://github.com/stubailo) to allow options and using other transforms.
2. allow the options file to override envify default options
3. added exorcist use to extract source map from browserified file to supply to CompileStep
4. added test for using an options file

# 0.3.0 - 2015/05/26

1. accepted [PR#5](https://github.com/elidoran/cosmos-browserify/pull/5) from [lourd](https://github.com/lourd) to use envify transform (thank you @lourd)
2. added on to PR#5 to use envify/custom and provide its options; altered tests
3. added warning against using extension as filename because of Meteor issue [#3985](https://github.com/meteor/meteor/issues/3985). Revised README.

# 0.2.0 - 2015/05/16

1. refactored  [browserify.coffee](https://github.com/elidoran/cosmos-browserify/blob/master/plugin/browserify.coffee)
2. added support for [meteorhacks:npm](https://github.com/meteorhacks/npm) providing app level npm modules for app browserify.js files
3. updated README to mention meteorhacks:npm support

# 0.1.4 - 2015/05/15

1. changed plugin name to CosmosBrowserify
2. added Travis CI
3. added testing of a successful plugin call
4. ignore .DS_Store files
5. reformatted plugin's [browserify.coffee](https://github.com/elidoran/cosmos-browserify/blob/master/plugin/browserify.coffee) with more comments and whitespace
6. added error handling for browserify errors
7. determine `debug` for browserify based on `process.argv` contents. (Thank you Arunoda for this idea)
8. added test for browserify throwing an error

# 0.1.3 - 2015/05/04

1. previous publish was incomplete. must republish to new version

# 0.1.2 - 2015/05/04

1. fixed `package.js` test file path
2. fixed `package.js` coffeescript version

# 0.1.1 - 2015/05/04

1. fix [issue #1](https://github.com/elidoran/cosmos-browserify/issues/1) local `stream` variable given a unique name
