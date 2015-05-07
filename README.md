# Cosmos Browserify [![Build Status](https://travis-ci.org/elidoran/cosmos-browserify.svg?branch=master)](https://travis-ci.org/elidoran/cosmos-browserify)

#### [Browserify](http://browserify.org) [npm](http://npmjs.org) dependencies in [Meteor](http://meteor.com) packages for **client side** use.

### Simple Example

Look at [cosmos-browserify-example](http://github.com/elidoran/cosmos-browserify-example)
for a complete working Meteor app example. Look at a [package in the app](http://github.com/elidoran/cosmos-browserify-example/tree/master/packages/browserify-example)
to see how to make one.

### Easy as 1 2 3

Three steps to using `cosmos:browserify` with the `upper-case` npm module.

1. Add to `package.js`:

    ```javascript
    // have Meteor get the npm module for you
    Npm.depends({'upper-case':'1.1.2'});

    Package.onUse(function(api) {
      // use this package
      api.use(['cosmos:browserify@0.1.3'], 'client');

      // add file in Step #2, and the package's client script
      api.addFiles(['browserify.js', 'example.js'], 'client');

      // OPTIONAL: make available to the entire client by exporting it:
      api.export('uppercase', 'client');
    });
    ```

2. Add to `browserify.js` in the root of your package:

    ```javascript
    // w/out `var` it will be package scoped so package code may use it
    uppercase = require('upper-case');
    ```

3. Add to Meteor package's client script:

    If you exported the variable then you may use it in an app script.

    ```javascript
    console.log("example use: ", uppercase('some text'));
    ```

Your browser's console will print: `example use: SOME TEXT`


### Install and Usage

#### Step 1: NPM dependencies

Use Meteor's [Npm.depend()](http://docs.meteor.com/#/full/Npm-depends) to add npm
modules as dependencies in `package.js`:

```javascript
Npm.depends({
  'some-module':'1.2.3',
  another:'4.5.6'
});
```

Meteor automatically downloads the NPM modules into your package
at `.npm/package`. Commit the folder to source control. It has an
`npm-shrinkwrap.json` for consistent dependency versions.

#### Step 2: Use `cosmos:browserify` package

Add `cosmos:browserify` as a client package dependency in the `onUse` section
of `package.js`.

```javascript
Package.onUse(function(api) {
  api.use([
    'cosmos:browserify@0.1.3'
  ], 'client');
});
```

#### Step 3: Browserify Entry File

Create a file in the root of your package named `browserify.js`.

Note: It only needs to *end* with that, you may name it `client.browserify.js`,
for example.

1. Each module you require will be bundled into the result
2. declaring without `var` will make it *package scoped* in your Meteor package

```javascript
something = require('module-name');
```

Now, `cosmos:browserify` will use browserify to bundle all modules into a single
JavaScript file and add it to the **client side**. The variables declared
without `var` in this file will be available to your meteor package's client
code as package scoped variables.

#### Step 4: Verify Script is in the Client

Open your Meteor app in your browser. View the page's source. Look through the
long list of included JS files until you find the one named for your package.
For example, the builtin `blaze` package's script tag looks similar to:

```html
<script type="text/javascript" src="/packages/blaze.js?a5c324925e5f6e800a4"></script>
```

Click on the link for your package to view its combined scripts.

There are two things to look for:

1. Ensure your browserified bundle is in there. If your package was
`someuser:somepackage` then you'd look for a block like this:

    ```javascript
    /////////////////////////////////////////////////
    // packages/someuser:somepackage/browserify.js //
    /////////////////////////////////////////////////
    ```

2. Ensure the variable you want to use is in "package scoped". If you're looking
for a variable named `something` then you'd see this:

    ```javascript
    /* Package-scope variables */
    var something, __coffeescriptShare;
    ```

Note: I always use coffeescript, so there's always the `__coffeescriptShare` there.
I'm not sure if it's always there or not.


#### Step 5: Use the module

In your package's client scripts you have access to all package scoped variables.

For example, when `something` is exported as shown above, then access it like
a global variable:

```javascript
// if it's an object with functions
something.someFunction()

// if it's a factory function to create an object
instance = something()

// if it's a class function
instance = new something()
```

## Meteor Application Scope

Variables in `browserify.js` are not available globally to client code because Meteor limits variables published by a package to *package scope*.

Use Meteor's [api.export()](http://docs.meteor.com/#/full/pack_export) to make a variable available to all client code:

```javascript
// Use the name of the variable you created in `browserify.js`
api.export('uppercase', 'client');
```

## MIT License
