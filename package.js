Package.describe({
  name: 'cosmos:browserify',
  version: '0.1.4',
  summary: 'Bundle NPM modules for client side with Browserify',
  git: 'https://github.com/elidoran/cosmos-browserify.git',
  documentation: 'README.md'
});

Package.registerBuildPlugin({
  name: "cosmosBrowserify",
  use: ['coffeescript@1.0.6','meteor'],
  sources: ['plugin/browserify.coffee'],
  npmDependencies: {"browserify": "9.0.8"}
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('cosmos:browserify');
  api.addFiles('test/browserify-tests.js');
});
