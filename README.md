# Cosmos Browserify [![Build Status](https://travis-ci.org/elidoran/cosmos-browserify.svg?branch=master)](https://travis-ci.org/elidoran/cosmos-browserify)

#### [Browserify](http://browserify.org) [npm](http://npmjs.org) dependencies in [Meteor](http://meteor.com) packages for **client side** use.

##### Note: For Meteor 1.2 you must use comsos:browserify 0.7.0+

## Table of Contents

1. [Example Meteor App](#example-meteor-app)
2. [Use in a Meteor Package](#use-in-a-meteor-package)
    1. [Create and Add Your Package](#1-create-and-add-your-package)
    2. [Create browserify file](#2-create-browserify-file)
    3. [Update package.js](#3-update-packagejs)
    4. [Verify success](#4-verify-success)
    5. [Use Variable](#5-use-variable)
3. [Use in a Meteor App](#use-in-a-meteor-app)
    1. [Enable App npm modules](#1-enable-app-npm-modules)
    2. [Create App browserify file](#2-create-app-browserify-file)
    3. [Enable browserify](#3-enable-browserify)
    4. [Verify success](#4-verify-it-worked)
4. [Passing options to Browserify](#passing-options-to-browserify)
    1. [Using transforms](#using-transforms)
5. [Caching Result](#caching-result)
6. [Reporting an Issue](#reporting-an-issue)

## Example Meteor App

Look at [cosmos-browserify-example](http://github.com/elidoran/cosmos-browserify-example) for a complete working Meteor app example. Look at a [package in the app](http://github.com/elidoran/cosmos-browserify-example/tree/master/packages/browserify-example) to see how to make one.


## Use in a Meteor Package

Specify npm modules in your package and browserify them to the client. The variables may be package scoped or app (global) scoped.


#### Quick Start

For a quick start, copy my functional [example package](https://github.com/elidoran/cosmos-browserify-example/blob/master/packages/browserify-example).

#### 1. Create and Add your package

Use standard Meteor package create and add:

```
$ meteor create --package cosmos:browserify-example
```

#### 2. Create browserify file

Create a JavaScript file requiring the npm modules you want to browserify. The file name must end with `browserify.js`.
NOTE: Due to [Meteor Issue #3985](https://github.com/meteor/meteor/issues/3985) we must put something before the extension, like: `client.browserify.js`.
Example content:

```js
// without var it becomes a package scoped variable
uppercase = require('upper-case');
```

#### 3. Update package.js

```js
// Specify npm modules
Npm.depends({
  'upper-case':'1.1.2'
});

Package.onUse(function(api) {
  // add package
  api.use(['cosmos:browserify@0.7.0'], 'client');

  // add browserify file in step #2 with your package's client files
  api.addFiles(['client.browserify.js', 'your/package/file.js'], 'client');

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

C. Find your package's browserify script. If your package was `someuser:somepackage` and the file named `client.browserify.js` then you'd look for a block like this:

```js
////////////////////////////////////////////////////////
// packages/someuser:somepackage/client.browserify.js //
////////////////////////////////////////////////////////
```
D. Ensure the variable you want is in the package scoped area. If you're looking for a variable named `uppercase` then you'd see this:

```js
/* Package-scope variables */
var uppercase, __coffeescriptShare;
```

Note: I always use coffeescript, so there's always the `__coffeescriptShare` there. I'm not sure if it's always there or not.


#### 5. Use variable

In your package's client scripts you have access to all package scoped variables, including those browserified. For example:

```js
console.log("uppercase('some text') = ", uppercase('some text'));
```


## Use in a Meteor App

Specify npm modules in your app and browserify them to the client. The variables will be app (global) scoped.

It is possible to make browserified variables app (global) scoped by exporting them from a package with `api.export()`. Please see [Exporting to App](#exporting-to-app).


#### 1. Enable app npm modules

Meteor doesn't support npm modules at the app level. Fortunately, you can add the ability with the [meteorhacks:npm](http://github.com/meteorhacks/npm) package.

```sh
$ meteor add meteorhacks:npm
```

The first time your app runs (or if it's running when you add the package) it will create a `packages.json` file in the root of your app. Specify the modules in `packages.json`. For example:

```js
{
  "upper-case" : "1.1.2"
}
```

#### 2. Create app browserify file

Create a JavaScript file requiring the npm modules you want to browserify. The name must end with `browserify.js`.

Example content:

```js
// without var it becomes an app (global) scoped variable
uppercase = require('upper-case');
```

NOTE:

1. Due to [Meteor Issue #3985](https://github.com/meteor/meteor/issues/3985) we must put something before the extension, like: `app.browserify.js`.
2. When the file is outside the `client` folder Meteor runs the browserify plugin twice, once for client and once for server. I recommend putting the file inside `client`. It is a client-only file anyway.

#### 3. Enable browserify

Add `cosmos:browserify`:

```sh
$ meteor add cosmos:browserify
```

It will browserify your `app.browserify.js` file and push it to the client.

#### 4. Verify it worked

In your browser's JavaScript console you can use the variable (`uppercase` if you followed my example).

## Passing options to Browserify

Browserify can be configured with additional options by adding a file with the same name as your `.browserify.js` file, but with the extension `.browserify.options.json`.

```
# example file structure:
- app.browserify.js             # entry point
- app.browserify.options.json   # options
```

You can use any [options that you can pass to the API](https://github.com/substack/node-browserify#browserifyfiles--opts).

#### Using transforms

To use a Browserify transform from NPM, add its package to your `packages.json` as described above; then pass it in the special `transform` option. This option is an object where the keys are the transform names, and the values are the options that can be passed to that transform.

Below is an example of using the `exposify` transform to use a global React variable with React Router instead of the React package from NPM.

##### packages.json

```
{
  "react-router": "0.13.3",
  "exposify": "0.4.3"
}
```
##### app.browserify.js

```js
ReactRouter = require("react-router");
```

##### app.browserify.options.json

```js
{
  "transforms": {
    "exposify": {
      "global": true,
      "expose": {
        "react": "React"
      }
    }
  }
}
```

#### Transforms in a Package

Make Meteor watch the options file for updates by adding it to the API:

```js
// from example package in cosmos-browserify-example
api.addFiles([
    'client/example.html',    // show some example results
    'client/example.coffee',  // package's Meteor script
    'client.browserify.js',           // browserify file
    'client.browserify.options.json'  // browserify options file
  ],
  'client'
);
```

## Caching Result

As of 0.7.0 the Meteor Build API supports caching build plugin results. It will only redo a browserify operation when files it builds have changed.


## Reporting an Issue

When reporting an issue consider showing:

1. the npm modules you're browserifying via the app's packages.json or package.js's Npm.depends() call
2. the browserify.js file, at least the require calls portion
3. the browserify.options.json file
4. the error

## MIT License
