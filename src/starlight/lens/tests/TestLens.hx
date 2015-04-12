package starlight.lens.tests;

import starlight.lens.Lens;
import starlight.lens.VirtualElement.ElementUpdate;
import starlight.lens.VirtualElement.ElementAction.*;

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

    function assertRemovedUpdate(id, oldParent, oldIndex, update) {
        assertEquals(id, update.elementId);
        assertEquals(null, update.oldParent);
        assertEquals(null, update.oldIndex);
        assertEquals(null, update.newParent);
        assertEquals(null, update.newIndex);
    }

    function assertAddedUpdate(attrs:VirtualElement.VirtualElementAttributes, update:VirtualElement.ElementUpdate) {
        if (attrs != null)
            assertTrue(attrs.attrEquals(update.attrs));
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
        assertTrue(next.attrs.attrEquals(pendingUpdates[0].attrs));
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
        assertRemovedUpdate(current.children[0].id, current.id, 0, pendingUpdates[0]);
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
        assertRemovedUpdate(current.id, null, null, pendingUpdates[0]);

        assertEquals('h2', pendingUpdates[1].tag);
    }
}


class FrontendTestCase extends starlight.tests.TestCase {
    public var elementCache = new haxe.ds.IntMap<starlight.lens.ElementType>();

    public override function tearDown() {
        var i = elementCache.keys();
        while(i.hasNext()) {
            var key = i.next();
            var el = elementCache.get(key);
            elementCache.remove(key);
#if js
            try {
                el.parentElement.removeChild(el);
            } catch (e:Dynamic) {
                // We don't care
            }
#end
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
}

class TestLensConsumeUpdates extends FrontendTestCase {
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
        function checkValue(selector, value) {
#if js
            assertEquals(cast(js.Browser.document.querySelector(selector), js.html.InputElement).value, value);
#else
            assertTrue(true);  // Just make the test not complain.
#end
        }

        var vm = new Lens();
        var updates = populateBasicElements(vm);

        checkValue('.form', 'initial');

        var inputAttrs = new VirtualElement.VirtualElementAttributes();
        inputAttrs.set("value", "result");

        updates = [{
            action:UpdateElement,
            elementId:3,
            attrs:inputAttrs
        }];
        vm.consumeUpdates(updates);
        checkValue('.form', 'result');
    }
}
