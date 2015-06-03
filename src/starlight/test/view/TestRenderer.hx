package starlight.test.view;

import js.Browser;

import starlight.core.Types.ElementType;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.Renderer.Renderer;
import starlight.view.Renderer.PseudoEvent;
import starlight.view.Component.ElementUpdate;
import starlight.view.Component.ElementAction.*;

#if js
class MockedRenderer extends Renderer {
    public var lastEvent:PseudoEvent;
    public var lastUpdates:Array<ElementUpdate>;
    public var lastBuiltEventId:Int;

    public function new() {
        super();

        rootComponent = cast {
            triggerEvent: function(obj) {
                lastEvent = obj;
            }
        };
    }

    override public function consumeUpdates(updates) {
        lastUpdates = updates;
    }

    override function buildEventHandler(id:Int) {
        lastBuiltEventId = id;
        return function(evt:Dynamic) {};
    }
}

class TestRenderer extends starlight.core.test.FrontendTestCase {
    function populateBasicElements(r:Renderer) {
        elementCache = r.elementCache;

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
        r.consumeUpdates(updates);

        return updates;
    }

    public function testElementCreation() {
        var r = new Renderer();
        r.rootElement = Browser.document.body;
        populateBasicElements(r);
        assertElementTextEquals("Starlight Demo", '.title');
    }

    public function testElementRemoval() {
        var r = new Renderer();
        r.rootElement = Browser.document.body;
        var updates = populateBasicElements(r);

        updates = [{
            action:RemoveElement,
            elementId:1,
        }];
        r.consumeUpdates(updates);

        assertFalse(r.elementCache.exists(1));
        assertEquals(Browser.document.querySelector('.title'), null);
    }

    public function testElementUpdate() {
        var r = new Renderer();
        r.rootElement = Browser.document.body;
        var updates = populateBasicElements(r);

        assertElementTextEquals("Starlight Demo", '.title');

        var attrs = new VirtualElementAttributes();
        attrs.set("class", "title hidden");

        updates = [{
            action:UpdateElement,
            elementId:1,
            attrs:attrs
        }];
        r.consumeUpdates(updates);

        assertElementTextEquals("Starlight Demo", '.title');
        assertElementTextEquals("Starlight Demo", '.hidden');
        assertElementTextEquals("Starlight Demo", '.title.hidden');
    }

    public function testElementMove() {
        function checkParent(selector, parentKey, index) {
            var parent:ElementType = elementCache.get(parentKey);
            if (parent == null) {
                parent = Browser.document.body;
            }
            var element:ElementType = cast Browser.document.querySelector(selector);
            assertTrue(untyped __js__("element.parentElement === parent"));
            assertTrue(untyped __js__("parent.childNodes.item(index) === element"));
        }

        var r = new Renderer();
        r.rootElement = Browser.document.body;
        var updates = populateBasicElements(r);

        var bodyChildren = untyped __js__("Array.prototype.slice.call( document.body.childNodes )");
        checkParent('.form', null, bodyChildren.indexOf(Browser.document.querySelector('.form')));
        updates = [{
            action:MoveElement,
            elementId:3,
            newParent:1,
            newIndex:1
        }];
        r.consumeUpdates(updates);

        checkParent('.form', 1, 1);
        updates = [{
            action:MoveElement,
            elementId:3,
            newParent:1,
            newIndex:0
        }];
        r.consumeUpdates(updates);

        checkParent('.form', 1, 0);
    }

    public function testInputValueUpdate() {
        var r = new Renderer();
        r.rootElement = Browser.document.body;
        var updates = populateBasicElements(r);

        assertElementValue('.form', 'initial');

        var inputAttrs = new VirtualElementAttributes();
        inputAttrs.set("value", "result");

        updates = [{
            action:UpdateElement,
            elementId:3,
            attrs:inputAttrs
        }];
        r.consumeUpdates(updates);
        assertElementValue('.form', 'result');
    }

    public function testPostProcessing() {
        var r = new Renderer();
        r.rootElement = Browser.document.body;
        var updates = populateBasicElements(r);

        var inputEl = r.elementCache.get(3);

        assertNotEquals(Browser.document.activeElement, inputEl);

        var inputAttrs = new VirtualElementAttributes();
        inputAttrs.set("focus", true);

        updates = [{
            action:UpdateElement,
            elementId:3,
            attrs:inputAttrs
        }];
        r.consumeUpdates(updates);

        assertEquals(Browser.document.activeElement, inputEl);
    }

    public function testRender() {
        var r = new MockedRenderer();

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

        r.updateSets.push(updates);
        assertEquals(1, r.updateSets.length);
        assertEquals(null, r.lastUpdates);
        r.render();
        assertEquals(0, r.updateSets.length);
        assertEquals(updates.length, r.lastUpdates.length);
        r.lastUpdates = null;

        r.render();
        assertEquals(null, r.lastUpdates);
    }

    public function testSelectAddtionWithValueSet() {
        var r = new Renderer();
        r.rootElement = Browser.document.body;
        var updates = populateBasicElements(r);

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
        r.consumeUpdates(updates);

        assertElementValue('select', 'Two');
    }

    public function testSetAttributes() {
        var el:ElementType = Browser.document.createElement("div");
        var attrs1 = new VirtualElementAttributes();
        // attrs.set("value", "Two");
        attrs1.set("onclick", 1);  // At this level, events are represented by IDs.
        attrs1.set("blur", true);
        attrs1.set("random", 2);
        attrs1.set("style", "color: red;");

        var r = new Renderer();
        r.setAttributes(el, attrs1, 1);

        assertEquals(1, r.postProcessing.get('blur'));
        assertEquals('function', untyped __js__('typeof el.onclick'));
        assertEquals('2', el.getAttribute('random'));

        var attrs2 = new VirtualElementAttributes();
        attrs2.set("onclick", 1);  // At this level, events are represented by IDs.
        attrs2.set("random", null);
        attrs2.set("style", "color: blue;");
        r.setAttributes(el, attrs2, 1);

        assertEquals('function', untyped __js__('typeof el.onclick'));
        assertEquals(null, el.getAttribute('random'));

        var el2:ElementType = Browser.document.createElement("input");
        var attrs3 = new VirtualElementAttributes();
        attrs3.set("onsubmit", 2);  // At this level, events are represented by IDs.
        attrs3.set("type", "submit");
        r.setAttributes(el2, attrs3, 1);

        assertEquals('function', untyped __js__('typeof el2.onsubmit'));
        assertEquals("submit", (untyped el2).type);
    }
}

class TestViewHelperFunctions extends starlight.core.test.TestCase {
    public function testBuildEventHandler() {
        var r = new MockedRenderer(),
            func1 = r.buildEventHandler(1),
            func2 = r.buildEventHandler(2),
            stopPropagationCalled = false,
            mockEvent1 = {
                id: 1,
                type: 'test',
                which: null,
                target: {
                    value: 'test1',
                    checked: null
                },
                stopPropagation: function() { stopPropagationCalled = true; }
            },
            mockEvent2 = {
                id: 2,
                type: 'test',
                which: null,
                target: {
                    value: 'test2',
                    checked: null
                },
                stopPropagation: function() { stopPropagationCalled = true; }
            };

        func1(mockEvent1);
        assertTrue(stopPropagationCalled);
        assertEquals(mockEvent1.id, r.lastEvent.id);

        stopPropagationCalled = false;
        func2(mockEvent2);
        assertTrue(stopPropagationCalled);
        assertEquals(mockEvent2.id, r.lastEvent.id);
    }
}

#end
