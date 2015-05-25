package hello_world;

import starlight.view.View;

class ViewModel extends View {
    var title = "Starlight • Hello World";
    var clickCount = 0;

    function handleClick() {
        clickCount++;
    }

    @:view
    override function view() {
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
        var view = new ViewModel();
        view.render();
    }
}
