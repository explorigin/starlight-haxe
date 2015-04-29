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

Starlight consists of a set of modular components to handle:

- storage and sync
- view-rendering and updating
- browser-to-server and server-to-server communication

### View

The View portion of Starlight provides a way to define and manipulate the browser DOM using templates, event handling and components.  It is lightweight virtual-DOM inspired by [Mithril](http://mithriljs.com) and [KnockoutJS](https://www.knockoutjs.com).

#### Example

```Haxe
class ViewModel extends View {
    var title = "Starlight Demo"
    var clickCount = 0;

    function handleClick(evt) {
        clickCount++;
    }

    public override function view() {
        return [
            e('header.title', if (clickCount > 0) '$title - clicked $clickCount times.' else title),
            e('section', [
                e('button', {onclick: handleClick}, 'Click Me!')
            ])
        ];
    }
}

View.apply(new ViewModel());
```

### Payload

Payload manages storage and syncing between the front-end and back-end.

(Under consideration: https://github.com/hoodiehq/wip-hoodie-store-on-pouchdb#dream-api)

### Elevator

Elevator provides communication in various forms between the server and browser.
