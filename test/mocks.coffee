# Mocks for:
#  1. MultiFileCachingCompiler
#  2. Plugin.registerCompiler
#
# Note the @ making the variables package scoped

class @MultiFileCachingCompiler
  constructor: () ->


@Plugin =
  registerCompiler: () ->
    console.log 'registered compiler!'
