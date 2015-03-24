package starlight.lens.tests;

import starlight.lens.Lens;

class TestLens extends haxe.unit.TestCase {
    public function testVoidGeneration() {
        var ve = Lens.element('br');
        assertEquals('<br>', ve.toHTML());

        var ve = Lens.element('input', {"class": "text"});
        assertEquals('<input class="text">', ve.toHTML());

        var ve = Lens.element('input[type=checkbox]', {"class": "text", "checked": true});
        assertEquals('<input class="text" type="checkbox" checked>', ve.toHTML());

        var ve = Lens.element('input#id.header', {"data-bind": "value: text"});
        assertEquals('<input id="id" class="header" data-bind="value: text">', ve.toHTML());
    }

    public function testStandardTagGeneration() {
        var ve = Lens.element('h1');
        assertEquals('<h1></h1>', ve.toHTML());

        var ve = Lens.element('h2', {"class": "text"});
        assertEquals('<h2 class="text"></h2>', ve.toHTML());

        var ve = Lens.element('span#id.header', {"data-bind": "value: text"});
        assertEquals('<span id="id" class="header" data-bind="value: text"></span>', ve.toHTML());
    }

    public function testNestedTagGeneration() {
        var e = Lens.element;

        var ve = e('h1', {}, ['hi']);
        assertEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h2', {"class": "text"}, [e('span', {"class": "header"}, ["Title"])]);
        assertEquals('<h2 class="text"><span class="header">Title</span></h2>', ve.toHTML());

        var ve = e('span#id.header', {"data-bind": "value: text"}, [
            "Title - ",
            e('div', {"data-bind": "value: $index"})
        ]);
        assertEquals('<span id="id" class="header" data-bind="value: text">Title - <div data-bind="value: $$index"></div></span>', ve.toHTML());
    }

    public function testTagGenerationWithOptionalAttributes() {
        var e = Lens.element;

        var ve = e('h1', ['hi']);
        assertEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h1', 'hi');
        assertEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h1', ['hi', e('span', {"class": "header"}, ["Title"])]);
        assertEquals('<h1>hi<span class="header">Title</span></h1>', ve.toHTML());
    }
}
