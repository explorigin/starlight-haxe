package starlight.lens.tests;

import starlight.lens.Lens;
using VirtualElement.VirtualElementTools;

class TestLensElement extends haxe.unit.TestCase {
    function assertVoidHTMLEquals(control:String, variable:String) {
        var varElements = variable.substr(1, variable.length-2).split(' ');
        var conElements = control.substr(1, variable.length-2).split(' ');
        assertEquals(varElements[0], conElements[0]);
        if (varElements.length > 1) {
            assertEquals(varElements[varElements.length-1], conElements[conElements.length-1]);

            for (el in varElements)
                assertTrue(conElements.indexOf(el) != -1);
        }
    }

    public function testVoidGeneration() {
        var ve = Lens.element('br');
        assertVoidHTMLEquals('<br>', ve.toHTML());

        var ve = Lens.element('input', {"class": "text"});
        assertVoidHTMLEquals('<input class="text">', ve.toHTML());

        var ve = Lens.element('input[type=checkbox]', {"class": "text", "checked": true});
        assertVoidHTMLEquals('<input type="checkbox" class="text" checked>', ve.toHTML());

        var ve = Lens.element('input#id.header', {"data-bind": "value: text"});
        assertVoidHTMLEquals('<input id="id" class="header" data-bind="value: text">', ve.toHTML());
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

        var ve = e('h1', {}, 'hi');
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


class TestLensUpdate extends haxe.unit.TestCase {
    var e = Lens.element;

    function assertRemovedUpdate(id, oldParent, oldIndex, update) {
        assertEquals(id, update.elementId);
        assertEquals(oldParent, update.oldParent);
        assertEquals(oldIndex, update.oldIndex);
        assertEquals(null, update.newParent);
        assertEquals(null, update.newIndex);
    }

    function assertAddedUpdate(tag:String, attrs:VirtualElement.VirtualElementAttributes, newParent:Int, newIndex:Int, update:VirtualElement.ElementUpdate, ?textValue:String) {
        assertEquals(newParent, update.newParent);
        assertEquals(newIndex, update.newIndex);
        assertEquals(tag, update.tag);

        if (textValue != null) {
            assertEquals(textValue, update.textValue);
            return;
        }

        if (attrs != null) {
            assertTrue(attrs.attrEquals(update.attrs));
        }
    }

    public function testElementCreation() {
        var next = e('h2', {"class": "test"}, "Header");

        var pendingUpdates = Lens.update(next, null);

        // There should be updates that detail the transition steps.
        assertEquals(2, pendingUpdates.length);

        assertAddedUpdate(next.tag, next.attrs, null, null, pendingUpdates[0]);
        assertAddedUpdate('#text', null, pendingUpdates[0].elementId, 0, pendingUpdates[1], 'Header');
    }

    public function testElementAttributeChange() {
        var current = e('h1');
        var next = e('h1', {"class": "test"});

        var pendingUpdates = Lens.update(next, current);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertEquals(next.tag, pendingUpdates[0].tag);
        assertTrue(next.attrs.attrEquals(pendingUpdates[0].attrs));
    }

    public function testElementRemoveChild() {
        var current = e('h1', {"class": "test"}, "Header");
        var next = e('h1', {"class": "test"});

        var pendingUpdates = Lens.update(next, current);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertRemovedUpdate(current.children[0].id, next.id, 0, pendingUpdates[0]);
    }

    public function testElementAddChild() {
        var current = e('h1', {"class": "test"});
        var next = e('h1', {"class": "test"}, "Header");

        var pendingUpdates = Lens.update(next, current);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertAddedUpdate('#text', null, next.id, 0, pendingUpdates[0], 'Header');
    }

    public function testElementReplacement() {
        var current = e('h1');
        var next = e('h2');

        var pendingUpdates = Lens.update(next, current);

        // There should be updates that detail the transition steps.
        assertEquals(2, pendingUpdates.length);
        assertRemovedUpdate(current.id, null, null, pendingUpdates[0]);

        assertEquals('h2', pendingUpdates[1].tag);
    }
}

class BasicViewModel extends Lens {
    var title = "Starlight Demo";
    public var clickCount = 0;

    public override function view() {
        return [
            e('header.title', if (clickCount > 0) '$title - clicked $clickCount times.' else title)
        ];
    }
}

class NestedViewModel extends Lens {
    public override function view() {
        return [
            e('header.title', [
                e('span.brand', "Starlight"),
                "&nbsp;Demo",
            ])
        ];
    }
}

class TestLensViewModel extends haxe.unit.TestCase {
    var vm:Lens;

    public override function tearDown() {
        if (vm != null) {
            var i = vm.elementCache.keys();
            while(i.hasNext()) {
                var key = i.next();
#if js
                var el = vm.elementCache.get(key);
                vm.elementCache.remove(key);

                try {
                    el.parentElement.removeChild(el);
                } catch (e:Dynamic) {
                    // We don't care
                }
#end
            }
        }
    }


    function assertElementTextEquals(text:String, selector:String) {
#if js
        var el = js.Browser.document.querySelector(selector);
        if (el == null) {
            assertEquals(selector, null);
        }
        assertEquals(text, el.innerHTML);
#else
        // Can't test on this platform but we add an assert to prevent this test from failing.
        assertTrue(true);
#end
    }

    public function testBasicVMCreation() {
        vm = new BasicViewModel();
        Lens.apply(vm);

        assertElementTextEquals("Starlight Demo", '.title');
    }

    public function testNestedVMCreation() {
        vm = new NestedViewModel();
        Lens.apply(vm);

        assertElementTextEquals("Starlight", '.title .brand');
    }
}
