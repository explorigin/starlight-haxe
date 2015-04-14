package starlight.lens.tests;

import starlight.lens.Lens;
import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.Lens.ElementUpdate;
import starlight.lens.Lens.ElementAction.*;

using Lambda;
using VirtualElement.VirtualElementTools;

class TestLensElement extends starlight.tests.TestCase {
    function assertVoidHTMLEquals(control:String, variable:String) {
        var varElements = variable.substr(1, variable.length-2).split(' ');
        var conElements = control.substr(1, variable.length-2).split(' ');
        assertEquals(varElements[0], conElements[0]);
        if (varElements.length > 1) {
            assertEquals(varElements[varElements.length-1], conElements[conElements.length-1]);

            for (el in varElements)
                assertContains(conElements, el);
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


class TestLensUpdate extends starlight.tests.TestCase {
    var e = Lens.element;

    static function attrEquals(a:VirtualElementAttributes, b:VirtualElementAttributes):Bool {
        for (key in a.keys()) {
            if (a.get(key) != b.get(key)) {
                return false;
            }
        }

        return a.array().length == b.array().length;
    }

    function assertRemovedUpdate(id, update) {
        assertEquals(id, update.elementId);
        assertEquals(null, update.newParent);
        assertEquals(null, update.newIndex);
    }

    function assertAddedUpdate(attrs:VirtualElementAttributes, update:ElementUpdate) {
        if (attrs != null)
            assertTrue(attrEquals(attrs, update.attrs));
    }

    public function testElementCreation() {
        var next = e('h2', {"class": "test"}, "Header");

        var pendingUpdates = Lens.update([next], []);

        // There should be updates that detail the transition steps.
        assertEquals(2, pendingUpdates.length);

        assertAddedUpdate(next.attrs, pendingUpdates[0]);
        assertAddedUpdate(null, pendingUpdates[1]);
    }

    public function testElementAttributeChange() {
        var current = e('h1');
        var next = e('h1', {"class": "test"});

        var pendingUpdates = Lens.update([next], [current]);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertTrue(attrEquals(next.attrs, pendingUpdates[0].attrs));
    }

    public function testElementAttributeRemove() {
        var current = e('h1', {"class": "test"});
        var next = e('h1');

        var pendingUpdates = Lens.update([next], [current]);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertHas(cast pendingUpdates[0].attrs, 'class');
        assertEquals(pendingUpdates[0].attrs.get('class'), null);
    }

    public function testElementRemoveChild() {
        var current = e('h1', {"class": "test"}, "Header");
        var next = e('h1', {"class": "test"});

        var pendingUpdates = Lens.update([next], [current]);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertRemovedUpdate(current.children[0].id, pendingUpdates[0]);
    }

    public function testElementAddChild() {
        var current = e('h1', {"class": "test"});
        var next = e('h1', {"class": "test"}, "Header");

        var pendingUpdates = Lens.update([next], [current]);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertAddedUpdate(null, pendingUpdates[0]);
    }

    public function testElementReplacement() {
        var current = e('h1');
        var next = e('h2');

        var pendingUpdates = Lens.update([next], [current]);

        // There should be updates that detail the transition steps.
        assertEquals(2, pendingUpdates.length);
        assertRemovedUpdate(current.id, pendingUpdates[0]);

        assertEquals('h2', pendingUpdates[1].tag);
    }
}


class TestLensConsumeUpdates extends starlight.tests.FrontendTestCase {
    function populateBasicElements(vm) {
        elementCache = vm.elementCache;
        var attrs = new VirtualElement.VirtualElementAttributes();
        attrs.set("class", "title");

        var inputAttrs = new VirtualElement.VirtualElementAttributes();
        inputAttrs.set("class", "form");
        inputAttrs.set("value", "initial");
        inputAttrs.set("placeholder", "test text");

        var updates:Array<ElementUpdate> = [{
            action:AddElement,
            elementId:1,
            tag:'h1',
            attrs:attrs,
            textValue:"",
            newParent:null,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:2,
            tag:'#text',
            attrs:new VirtualElement.VirtualElementAttributes(),
            textValue:"Starlight Demo",
            newParent:1,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:3,
            tag:'input',
            attrs:inputAttrs,
            textValue:"",
            newParent:null,
            newIndex:1
        }];
        vm.consumeUpdates(updates);

        return updates;
    }

    public function testElementCreation() {
        var vm = new Lens();
        populateBasicElements(vm);
        assertElementTextEquals("Starlight Demo", '.title');
    }

    public function testElementRemoval() {
        var vm = new Lens();
        var updates = populateBasicElements(vm);

        updates = [{
            action:RemoveElement,
            elementId:1,
        }];
        vm.consumeUpdates(updates);

        assertFalse(vm.elementCache.exists(1));
#if js
        assertEquals(js.Browser.document.querySelector('.title'), null);
#end
    }

    public function testElementUpdate() {
        var vm = new Lens();
        var updates = populateBasicElements(vm);
        assertElementTextEquals("Starlight Demo", '.title');

        var attrs = new VirtualElement.VirtualElementAttributes();
        attrs.set("class", "title hidden");

        updates = [{
            action:UpdateElement,
            elementId:1,
            attrs:attrs
        }];
        vm.consumeUpdates(updates);

        assertElementTextEquals("Starlight Demo", '.title');
        assertElementTextEquals("Starlight Demo", '.hidden');
        assertElementTextEquals("Starlight Demo", '.title.hidden');
    }

    public function testElementMove() {
        function checkParent(selector, parentKey, index) {
            var parent:ElementType = elementCache.get(parentKey);
#if js
            if (parent == null) {
                parent = js.Browser.document.body;
            }
            var element:ElementType = cast js.Browser.document.querySelector(selector);
            assertTrue(untyped __js__("element.parentElement === parent"));
            assertTrue(untyped __js__("parent.childNodes.item(index) === element"));
#else
            assertTrue(true);
#end
        }

        var vm = new Lens();
        var updates = populateBasicElements(vm);
#if js
        var bodyChildren = untyped __js__("Array.prototype.slice.call( document.body.childNodes )");
        checkParent('.form', null, bodyChildren.indexOf(js.Browser.document.querySelector('.form')));
#end
        updates = [{
            action:MoveElement,
            elementId:3,
            newParent:1,
            newIndex:1
        }];
        vm.consumeUpdates(updates);

        checkParent('.form', 1, 1);
        updates = [{
            action:MoveElement,
            elementId:3,
            newParent:1,
            newIndex:0
        }];
        vm.consumeUpdates(updates);

        checkParent('.form', 1, 0);
    }

    public function testInputValueUpdate() {
        var vm = new Lens();
        var updates = populateBasicElements(vm);

        assertElementValue('.form', 'initial');

        var inputAttrs = new VirtualElement.VirtualElementAttributes();
        inputAttrs.set("value", "result");

        updates = [{
            action:UpdateElement,
            elementId:3,
            attrs:inputAttrs
        }];
        vm.consumeUpdates(updates);
        assertElementValue('.form', 'result');
    }

    public function testSelectAddtionWithValueSet() {
        var vm = new Lens();
        var updates = populateBasicElements(vm);

        var attrs = new VirtualElement.VirtualElementAttributes();
        attrs.set("value", "Two");

        updates = [{
            action:AddElement,
            elementId:4,
            tag:'select',
            attrs:attrs,
            textValue:"",
            newParent:1,
            newIndex:1
        },
        {
            action:AddElement,
            elementId:5,
            tag:'option',
            attrs:new VirtualElement.VirtualElementAttributes(),
            textValue:"",
            newParent:4,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:6,
            tag:'#text',
            attrs:new VirtualElement.VirtualElementAttributes(),
            textValue:"One",
            newParent:5,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:7,
            tag:'option',
            attrs:new VirtualElement.VirtualElementAttributes(),
            textValue:"",
            newParent:4,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:8,
            tag:'#text',
            attrs:new VirtualElement.VirtualElementAttributes(),
            textValue:"Two",
            newParent:7,
            newIndex:0
        }];
        vm.consumeUpdates(updates);

        assertElementValue('select', 'Two');
    }
}
