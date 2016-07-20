Package.describe({
  name: 'cosmos:browserify',
  version: '0.10.0',
  summary: 'Bundle NPM modules for client side with Browserify',
  git: 'https://github.com/elidoran/cosmos-browserify.git',
  documentation: 'README.md'
});

Package.registerBuildPlugin({
  name: "CosmosBrowserify",
  // need 'meteor' for Npm and Meteor.wrapAsync
  use: ['caching-compiler@1.0.0', 'meteor', 'underscore@1.0.4'],
  sources: ['plugin/browserify.js'],
  npmDependencies: {
      "browserify": "12.0.1"         // primary tool which actually does the browserify
    , "envify":"3.4.0"             // transforms process.env values
    , "exorcist-stream":"0.4.0"    // gets source map from source (forked version for streaming)
    , "strung":"1.0.4"             // acts as a readable/writable/duplex
    , "json-stringify-safe":"5.0.1"
  }
});

// Need these so they're available during testing :(
// the list of them in Package.registerBuildPlugin doesn't do it...
// because plugin goes to .npm/plugin/CosmosBrowserify and these to: .npm/package
// I'm using a symlink so there's only one copy of them.
Npm.depends({
  "browserify": "12.0.1"
  , "envify":"3.4.0"
  , "exorcist-stream":"0.4.0"
  , "strung":"1.0.4"
  , "json-stringify-safe":"5.0.1"
});

// Need this for the 'isobuild:compiler-plugin'
Package.onUse(function (api) {
  // no longer backwards compatible (just has to be)
  api.versionsFrom('1.2');
  api.use([
    'isobuild:compiler-plugin@1.0.0'
  ], 'server');

});
