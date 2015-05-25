# Starlight

With Javascript, you can have...

- isomorphic app rendering
- code-sharing between server and client components
- static type-checking

...but you can only pick a few of these at a time.  Starlight gives you all these things to provide a solid platform for large web applications.  Starlight is built with a Javascript-like language called [Haxe](https://www.haxe.org).  In addition to the above features, Haxe offers...

- Dead-code elimination
- Support for various server-side technology stacks ([PHP](http://php.net/), [Python](https://www.python.org/), [NodeJS](https://nodejs.org/), [Java](http://www.java.com/en/about/) or [Neko](http://nekovm.org/))

## Run tests

To ensure that your platform can run Starlight correctly, tests will run automatically when you build Starlight.

    haxe build.hxml

Be sure to open `test.html` in your target web browsers to ensure that the browser components work properly.

## Modules

### View

The View portion of Starlight provides a way to define and manipulate the browser DOM using templates, event handling and components.  It is lightweight virtual-DOM inspired by [Mithril](http://mithriljs.com) and [KnockoutJS](https://www.knockoutjs.com).

## Examples

See the src/examples directory for examples on how Starlight is used.

## Roadmap

### General

- AMD or ES6 modules for the client-side

### View layer

- split between DOM renderer and component
- nestable components
- implement web-worker components
- make all but the DOM renderer work on the server-side
- provide reactive event interface to DOM events

### Loader

- implement loader that can resolve a main web component and sub-components and start the appropriate web-workers

  - loader should use a new web-worker for each source-file domain.

### Router

Current router is just a history event interface

- defined routes
- callback navigation
- server-side routing
- nestable routes and mapping to nestable components

### Server-side

- isomorphic rendering
- standardized RPC method
- event-like server
- pure-server logic

### Storage layer

 - investigate different storage methods

   - data storage (private)
     - pouchdb/couchdb
     - rethinkdb
     - indexeddb
   - data storage (public)
     - ipfs
     - maidsafe
     - s3
  - file layer
     - s3
     - byofs
     - remote-storage
     - maidsafe
     - webtorrent

  - Consider API: https://github.com/hoodiehq/wip-hoodie-store-on-pouchdb#dream-api

### i18n/l10n

- implement haxe i18n library
