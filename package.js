Package.describe({
  name: 'cosmos:browserify',
  version: '0.3.0',
  summary: 'Bundle NPM modules for client side with Browserify',
  git: 'https://github.com/elidoran/cosmos-browserify.git',
  documentation: 'README.md'
});

Package.registerBuildPlugin({
  name: "CosmosBrowserify",
  // need 'meteor' for Npm and Meteor.wrapAsync
  use: ['coffeescript@1.0.6', 'meteor', 'underscore'],
  sources: ['plugin/browserify.coffee'],
  npmDependencies: {"browserify": "9.0.8", "envify": "3.4.0"}
});

Package.onTest(function(api) {
  api.use('tinytest');
  // not testing by adding package in 'use'
  api.use(['coffeescript@1.0.6', 'underscore']);
  api.addFiles([
    // export stuff for use in Testing, and to Mock things like Npm
    //'test/export.js',
    // fill in the exported mocks (separate so I can write in CoffeScript)
    'test/mocks.coffee',
    // the tests
    'test/browserify-tests.coffee',
    // add our plugin file directly instead of adding package in api.use
    'plugin/browserify.coffee'
  ], 'client');

});
