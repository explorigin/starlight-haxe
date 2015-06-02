package hello_world;

import js.Browser;

import starlight.view.Component;
import starlight.view.Renderer;

class ViewModel extends Component {
    var title = "Starlight • Hello World";
    var clickCount = 0;

    function handleClick() {
        clickCount++;
    }

    @:prerender
    override function template() {
        return [
            e('header.title', [if (clickCount > 0) '$title - clicked $clickCount times.' else title]),
            e('section', [
                e('button', {onclick: handleClick}, 'Click Me!')
            ])
        ];
    }
}

class App {
    static function main() {
        var r = new Renderer();
        r.start(new ViewModel(), Browser.document.body);
    }
}
