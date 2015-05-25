package starlight.test.view;

import starlight.core.Types.ElementType;
import starlight.view.View;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.View.ElementUpdate;
import starlight.view.View.ElementAction.*;

using Lambda;
using starlight.view.VirtualElementTools;


class TestViewUpdate extends starlight.core.test.TestCase {
    var e = VirtualElementTools.element;
    var nodeCount = 0;

    static function attrEquals(a:VirtualElementAttributes, b:VirtualElementAttributes):Bool {
        for (key in a.keys()) {
            if (a.get(key) != b.get(key)) {
                return false;
            }
        }

        return [for (key in a.keys()) 1].length == [for (key in b.keys()) 1].length;
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

#if js
    public function testElementCreation() {
        var next = e('h2', {"class": "test"}, "Header");

        assertEquals(next.id, null);
        var pendingUpdates = new View().update([next], []);
        assertNotEquals(next.id, null);

        // There should be updates that detail the transition steps.
        assertEquals(2, pendingUpdates.length);

        assertAddedUpdate(next.attrs, pendingUpdates[0]);
        assertAddedUpdate(null, pendingUpdates[1]);
    }

    public function testElementAttributeChange() {
        var current = e('h1');
        var next = e('h1', {"class": "test"});

        current.id = nodeCount++;
        var pendingUpdates = new View().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertTrue(attrEquals(next.attrs, pendingUpdates[0].attrs));
    }

    public function testElementAttributeUpdate() {
        var current = e('h1', {"class": "test1"});
        var next = e('h1', {"class": "test2"});

        current.id = nodeCount++;
        var pendingUpdates = new View().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertTrue(attrEquals(next.attrs, pendingUpdates[0].attrs));
    }

    public function testClassObject() {
        var current = e('div.edit', {"class": {active: false}});
        var next = e('div.edit', {"class": {active: true}});
        var again = e('div.edit', {"class": {active: false}});

        assertEquals('edit', current.attrs.get('class'));

        current.id = nodeCount++;
        var pendingUpdates = new View().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertEquals('edit active', pendingUpdates[0].attrs.get('class'));

        pendingUpdates = new View().update([again], [next]);
        assertEquals(again.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertEquals('edit', pendingUpdates[0].attrs.get('class'));
    }

    public function testCheckboxUpdate() {
        var current = e('input[type=checkbox]', {"checked": false});
        var next = e('input[type=checkbox]', {"checked": true});
        var again = e('input[type=checkbox]', {"checked": false});

        current.id = nodeCount++;
        var pendingUpdates = new View().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertEquals('checked', pendingUpdates[0].attrs.get('checked'));

        pendingUpdates = new View().update([again], [next]);
        assertEquals(again.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertEquals(null, pendingUpdates[0].attrs.get('checked'));
    }

    public function testElementAttributeRemove() {
        var current = e('h1', {"class": "test"});
        var next = e('h1');

        current.id = nodeCount++;
        var pendingUpdates = new View().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertTrue(pendingUpdates[0].attrs.exists('class'));
        assertEquals(pendingUpdates[0].attrs.get('class'), null);
    }

    public function testElementRemoveChild() {
        var current = e('h1', {"class": "test"}, "Header");
        var next = e('h1', {"class": "test"});

        var pendingUpdates = new View().update([next], [current]);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertRemovedUpdate(current.children[0].id, pendingUpdates[0]);
    }

    public function testElementAddChild() {
        var current = e('h1', {"class": "test"});
        var next = e('h1', {"class": "test"}, "Header");

        assertEquals(null, next.children[0].id);
        var pendingUpdates = new View().update([next], [current]);
        assertNotEquals(null, next.children[0].id);

        // There should be updates that detail the transition steps.
        assertEquals(1, pendingUpdates.length);
        assertAddedUpdate(null, pendingUpdates[0]);
    }

    public function testElementReplacement() {
        var current = e('h1');
        var next = e('h2');

        current.id = nodeCount++;
        var pendingUpdates = new View().update([next], [current]);
        assertNotEquals(current.id, next.id);

        // There should be updates that detail the transition steps.
        assertEquals(2, pendingUpdates.length);
        assertRemovedUpdate(current.id, pendingUpdates[0]);

        assertEquals('h2', pendingUpdates[1].tag);
    }

    public function testSelectElementValueOnAdd() {
        var next = e(
            'select',
            {"value": "Two"},
            [
                e('option', 'One'),
                e('option', 'Two')
            ]);

        var pendingUpdates = new View().update([next], []);

        // There should be updates that detail the transition steps.
        assertEquals(6, pendingUpdates.length);
        assertEquals(pendingUpdates[pendingUpdates.length-1].action, UpdateElement);
        assertTrue(attrEquals(next.attrs, pendingUpdates[pendingUpdates.length-1].attrs));
    }
#end
}


class TestViewConsumeUpdates extends starlight.core.test.FrontendTestCase {
    function populateBasicElements(vm:Dynamic) {
        elementCache = vm.elementCache;
        var attrs = new VirtualElementAttributes();
        attrs.set("class", "title");

        var inputAttrs = new VirtualElementAttributes();
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
            attrs:new VirtualElementAttributes(),
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
        var vm = new View();
        populateBasicElements(vm);
        assertElementTextEquals("Starlight Demo", '.title');
    }

    public function testElementRemoval() {
        var vm = new View();
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
        var vm = new View();
        var updates = populateBasicElements(vm);
        assertElementTextEquals("Starlight Demo", '.title');

        var attrs = new VirtualElementAttributes();
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

        var vm = new View();
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
        var vm = new View();
        var updates = populateBasicElements(vm);

        assertElementValue('.form', 'initial');

        var inputAttrs = new VirtualElementAttributes();
        inputAttrs.set("value", "result");

        updates = [{
            action:UpdateElement,
            elementId:3,
            attrs:inputAttrs
        }];
        vm.consumeUpdates(updates);
        assertElementValue('.form', 'result');
    }

#if js
    public function testPostProcessing() {
        var vm = new View();
        var updates = populateBasicElements(vm);

        var inputEl = vm.elementCache.get(3);

        assertNotEquals(js.Browser.document.activeElement, inputEl);

        var inputAttrs = new VirtualElementAttributes();
        inputAttrs.set("focus", true);

        updates = [{
            action:UpdateElement,
            elementId:3,
            attrs:inputAttrs
        }];
        vm.consumeUpdates(updates);

        assertEquals(js.Browser.document.activeElement, inputEl);
    }
#end

    public function testSelectAddtionWithValueSet() {
        var vm = new View();
        var updates = populateBasicElements(vm);

        var attrs = new VirtualElementAttributes();
        attrs.set("value", "Two");

        updates = [{
            action:AddElement,
            elementId:4,
            tag:'select',
            attrs:new VirtualElementAttributes(),
            textValue:"",
            newParent:1,
            newIndex:1
        },
        {
            action:AddElement,
            elementId:5,
            tag:'option',
            attrs:new VirtualElementAttributes(),
            textValue:"",
            newParent:4,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:6,
            tag:'#text',
            attrs:new VirtualElementAttributes(),
            textValue:"One",
            newParent:5,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:7,
            tag:'option',
            attrs:new VirtualElementAttributes(),
            textValue:"",
            newParent:4,
            newIndex:0
        },
        {
            action:AddElement,
            elementId:8,
            tag:'#text',
            attrs:new VirtualElementAttributes(),
            textValue:"Two",
            newParent:7,
            newIndex:0
        },
        {
            action:UpdateElement,
            elementId:4,
            attrs:attrs
        }];
        vm.consumeUpdates(updates);

        assertElementValue('select', 'Two');
    }
}

class TestViewHelperFunctions extends starlight.core.test.TestCase {
    public function testBuildEventHandler() {
        var vm = new View(),
            func = vm.buildEventHandler('onchange', 1),
            stopPropagationCalled = false,
            mockEvent = {
                which: null,
                target: {
                    value: 'test',
                    checked: null
                }
            };



    }
}
