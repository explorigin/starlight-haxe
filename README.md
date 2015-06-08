# Starlight

Starlight is an experimental web framework.  It is opinionated toward single-page applications (unhosted where possible) and micro-services for interacting with servers (when it must).

## Run tests

To ensure that your platform can run Starlight correctly, tests will run automatically when you build Starlight.

    haxe build.hxml

PHP tests must be invoked separately after running the above build command.

    php5 php/index.php

Be sure to open `test.html` in your target web browsers to ensure that the browser components work properly.

## Modules

### View

The View portion of Starlight provides a way to define and manipulate the browser DOM using templates, event handling and components.  It is lightweight virtual-DOM inspired by [Mithril](http://mithriljs.com), [KnockoutJS](https://www.knockoutjs.com) and [Grimwire](https://github.com/pfraze/grimwire).

## Examples

See the src/examples directory for examples on how Starlight can be used.

## Roadmap

### General

  - Consider ways to improve UX by anticipating server responses.  If the real response comes back differently:

    - rewind the UI state back to before the fake response
    - apply the real response
    - reapply the rewinded events until something looks different or we've returned to the current state
    - call it a "Time Warp" =)

  - Modify JSGenerator to output ES6 modules

    - integration with webpack

### View layer

- element-motion tracking algorithm to make moving an element more efficient.
- consider mapping all event handlers to the root node and use event bubbling to have fewer DOM interactions (particularly important for mouseover events because these sorts of things can create tons of event handlers when just one pulls events into Javascript-land just as well.)
- black-list some tag types ("script", "style", "embed", "object", "param")
- nestable components
- implement web-worker components
- textarea and content-editable support
- make everything, except the DOM renderer, work on the server-side
- provide reactive event interface to DOM events

### Loader

  - implement loader that can resolve a main web component and sub-components and start the appropriate web-workers

### Router

Current router is just a history event interface

- defined routes
- callback navigation
- server-side routing
- nestable routes and mapping to nestable components

### Server-side

- isomorphic rendering
- standardized RPC method (ext.direct or Haxe remoting)
- ICE connection initialization

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
