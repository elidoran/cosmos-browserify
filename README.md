# Cosmos Browserify [![Build Status](https://travis-ci.org/elidoran/cosmos-browserify.svg?branch=master)](https://travis-ci.org/elidoran/cosmos-browserify)

#### [Browserify](http://browserify.org) [npm](http://npmjs.org) dependencies in [Meteor](http://meteor.com) packages for **client side** use.

## Table of Contents

1. [Example Meteor App](#example-meteor-app)
2. [Use in a Meteor Package](#use-in-a-meteor-package)
3. [Use in a Meteor App](#use-in-a-meteor-app)


## Example Meteor App

Look at [cosmos-browserify-example](http://github.com/elidoran/cosmos-browserify-example)
for a complete working Meteor app example. Look at a [package in the app](http://github.com/elidoran/cosmos-browserify-example/tree/master/packages/browserify-example)
to see how to make one.


## Use in a Meteor Package

Specify npm modules in your package and browserify them to the client. The variables may be package scoped or app (global) scoped.


#### Quick Start

For a quick start, copy my functional [example package](https://github.com/elidoran/cosmos-browserify-example/blob/master/packages/browserify-example).

#### 1. Create and Add your package

Use standard Meteor package create and add:

```
  $ meteor create --package cosmos:browserify-example
  $ meteor add cosmos:browserify-example
```

#### 2. Create browserify file

Create a JavaScript file requiring the npm modules you want to browserify. The file name must end with `browserify.js`. Example content:

```javascript
  // without var it becomes a package scoped variable
  uppercase = require('upper-case');
```

#### 3. Update package.js

```javascript
  // Specify npm modules
  Npm.depends({
    'upper-case':'1.1.2'
  });

  Package.onUse(function(api) {
    // add package
    api.use(['cosmos:browserify@0.2.0'], 'client');

	// add browserify file in step #2 with your package's client files
    api.addFiles(['browserify.js', 'your/package/file.js'], 'client');

    // OPTIONAL: make variable app (global) scoped:
    api.export('uppercase', 'client');
  });
```

##### Exporting to app

As with all other variables in a package the browserified variables are limited to the package scope unless they are exported via `api.export()` as shown above.


#### 4. Verify success

First, ensure your app is running without errors.

##### App scoped variable

If you exported a variable to the app scope then you may use it in the browser's JavaScript console.

##### Package scoped variable

If your variable is package scoped you may still verify it was browserified.

A. Use *View Source* to see the script tags Meteor is sending to your client.

B. Find your package's script tag and click on it to view its source. For package `someuser:somepackage` there will be a script tag like this:

```html
    <script type="text/javascript" src="/packages/someuser_somepackage.js?a5c324925e5f6e800a4"></script>
```

C. Find your package's browserify script. If your package was `someuser:somepackage` and the file named `browserify.js` then you'd look for a block like this:

```javascript
  /////////////////////////////////////////////////
  // packages/someuser:somepackage/browserify.js //
  /////////////////////////////////////////////////
```
D. Ensure the variable you want is in the package scoped area. If you're looking for a variable named `uppercase` then you'd see this:

```javascript
  /* Package-scope variables */
  var uppercase, __coffeescriptShare;
```

Note: I always use coffeescript, so there's always the `__coffeescriptShare` there. I'm not sure if it's always there or not.


#### 5. Use variable

In your package's client scripts you have access to all package scoped variables, including those browserified. For example:

```javascript
  console.log("uppercase('some text') = ", uppercase('some text'));
```


## Use in a Meteor App

Specify npm modules in your app and browserify them to the client. The variables will be app (global) scoped.

It is possible to make browserified variables app (global) scoped by exporting them from a package with `api.export()`. Please see [Exporting to App](#exporting-to-app).


#### 1. Enable app npm modules

Meteor doesn't support npm modules at the app level. Fortunately, you can add the ability with the [meteorhacks:npm](http://github.com/meteorhacks/npm) package.

    $ meteor add meteorhacks:npm

The first time your app runs (or if it's running when you add the package) it will create a `packages.json` file in the root of your app. Specify the modules in `packages.json`. For example:

```javascript
{
  "upper-case" : "1.1.2"
}
```

#### 2. Create browserify file

Create a JavaScript file requiring the npm modules you want to browserify. The name must end with `browserify.js`. For example:

```javascript
// without var it becomes an app (global) scoped variable
uppercase = require('upper-case');
```


#### 3. Enable browserify

Add `cosmos:browserify`:

    $ meteor add cosmos:browserify

It will browserify your `browserify.js` file and push it to the client.

#### 4. Verify it worked

In your browser's JavaScript console you can use the variable (`uppercase` if you followed my example).


## MIT License
