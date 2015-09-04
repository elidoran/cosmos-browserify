# get our plugin class to test it
BrowserifyPlugin = share.BrowserifyPlugin

Tinytest.add 'test we have the objects', (test) ->

  test.equal MultiFileCachingCompiler?, true, 'MultiFileCachingCompiler should be available for BrowserifyPlugin'
  test.equal BrowserifyPlugin?, true, 'BrowserifyPlugin should be exported'

# TODO: call functions on BrowserifyPlugin and check results...
