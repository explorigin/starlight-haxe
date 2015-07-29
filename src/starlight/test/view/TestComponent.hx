package starlight.test.view;

import starlight.core.Types.ElementType;
import starlight.core.Types.Symbol;
import starlight.view.VirtualElement.VirtualElement;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.Component;
import starlight.view.Component.ElementUpdate;

import starlight.view.macro.ElementBuilder.e;

using Lambda;
using starlight.view.VirtualElementTools;


class MockComponent extends Component {
    public var updateReturnValue:Array<ElementUpdate>;

    override function update(nextState, currentState, ?parentId:Int) {
        return updateReturnValue;
    }

    override function template() {
        return [e('div')];
    }
}


class TestComponent extends starlight.core.test.TestCase {
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
        var pendingUpdates = new Component().update([next], []);
        assertNotEquals(next.id, null);

        assertEquals(2, pendingUpdates.length);

        assertAddedUpdate(next.attrs, pendingUpdates[0]);
        assertAddedUpdate(null, pendingUpdates[1]);
    }

    public function testElementAttributeChange() {
        var current = e('h1');
        var next = e('h1', {"class": "test"});

        current.id = nodeCount++;
        var pendingUpdates = new Component().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertTrue(attrEquals(next.attrs, pendingUpdates[0].attrs));
    }

    public function testElementAttributeUpdate() {
        var current = e('h1', {"class": "test1"});
        var next = e('h1', {"class": "test2"});

        current.id = nodeCount++;
        var pendingUpdates = new Component().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertTrue(attrEquals(next.attrs, pendingUpdates[0].attrs));
    }

    public function testClassObject() {
        var current = e('div.edit', {"class": {active: false}});
        var next = e('div.edit', {"class": {active: true}});
        var again = e('div.edit', {"class": {active: false}});

        assertEquals('edit', current.attrs.get('class'));

        current.id = nodeCount++;
        var pendingUpdates = new Component().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertTrue(pendingUpdates[0].attrs.get('class').indexOf('edit') != -1);
        assertTrue(pendingUpdates[0].attrs.get('class').indexOf('active') != -1);

        pendingUpdates = new Component().update([again], [next]);
        assertEquals(again.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertEquals('edit', pendingUpdates[0].attrs.get('class'));
    }

    public function testCheckboxUpdate() {
        var current = e('input[type=checkbox]', {"checked": false});
        var next = e('input[type=checkbox]', {"checked": true});
        var again = e('input[type=checkbox]', {"checked": false});

        current.id = nodeCount++;
        var pendingUpdates = new Component().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertEquals('checked', pendingUpdates[0].attrs.get('checked'));

        pendingUpdates = new Component().update([again], [next]);
        assertEquals(again.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertEquals(null, pendingUpdates[0].attrs.get('checked'));
    }

    public function testElementAttributeRemove() {
        var current = e('h1', {"class": "test"});
        var next = e('h1');

        current.id = nodeCount++;
        var pendingUpdates = new Component().update([next], [current]);
        assertEquals(next.id, nodeCount-1);

        assertEquals(1, pendingUpdates.length);
        assertTrue(pendingUpdates[0].attrs.exists('class'));
        assertEquals(pendingUpdates[0].attrs.get('class'), null);
    }

    public function testElementRemoveChild() {
        var current = e('h1', {"class": "test"}, "Header");
        var next = e('h1', {"class": "test"});

        var pendingUpdates = new Component().update([next], [current]);

        assertEquals(1, pendingUpdates.length);
        assertRemovedUpdate(current.children[0].id, pendingUpdates[0]);
    }

    public function testElementAddChild() {
        var current = e('h1', {"class": "test"});
        var next = e('h1', {"class": "test"}, "Header");

        assertEquals(null, next.children[0].id);
        var pendingUpdates = new Component().update([next], [current]);
        assertNotEquals(null, next.children[0].id);

        assertEquals(1, pendingUpdates.length);
        assertAddedUpdate(null, pendingUpdates[0]);
    }

    public function testNoChange() {
        var current = e('h1', {"class": "test"});
        var next = e('h1', {"class": "test"});

        var c = new Component();
        var pendingUpdates = c.update([next], [current]);
        assertEquals(0, pendingUpdates.length);

        current = {id: null, tag: VirtualElementTools.TEXT_TAG, textValue: 'hi'};
        next = {id: null, tag: VirtualElementTools.TEXT_TAG, textValue: 'hi'};

        pendingUpdates = c.update([next], [current]);
        assertEquals(0, pendingUpdates.length);
    }

    public function testElementReplacement() {
        var current = e('h1');
        var next = e('h2');
        var again = {id: null, tag: VirtualElementTools.TEXT_TAG, textValue: 'hi'};

        current.id = nodeCount++;
        var c = new Component();
        var pendingUpdates = c.update([next], [current]);
        assertNotEquals(current.id, next.id);

        assertEquals(2, pendingUpdates.length);
        assertRemovedUpdate(current.id, pendingUpdates[0]);

        assertEquals('h2', pendingUpdates[1].tag);

        pendingUpdates = c.update([again], [next]);
        assertNotEquals(next.id, again.id);

        assertEquals(2, pendingUpdates.length);
        assertRemovedUpdate(next.id, pendingUpdates[0]);

        assertEquals(VirtualElementTools.TEXT_TAG, pendingUpdates[1].tag);

    }

    public function testTextReplacement() {
        var current = {id: null, tag: VirtualElementTools.TEXT_TAG, textValue: 'hi'};
        var next = {id: null, tag: VirtualElementTools.TEXT_TAG, textValue: 'bye'};

        current.id = nodeCount++;
        var c = new Component();
        var pendingUpdates = c.update([next], [current]);

        assertEquals(1, pendingUpdates.length);
        assertEquals(Symbol.forKey('UpdateElement'), pendingUpdates[0].action);
        assertEquals('bye', Reflect.field(pendingUpdates[0].attrs, 'textContent'));
    }

    public function testSelectElementValueOnAdd() {
        var next = e(
            'select',
            {"value": "Two"},
            [
                e('option', 'One'),
                e('option', 'Two')
            ]);

        var pendingUpdates = new Component().update([next], []);

        assertEquals(6, pendingUpdates.length);
        assertEquals(pendingUpdates[pendingUpdates.length-1].action, Symbol.forKey('UpdateElement'));
        assertTrue(attrEquals(cast next.attrs, cast pendingUpdates[pendingUpdates.length-1].attrs));
    }
#end

    public function testRemoveEventHandlers() {
        var c = new Component(),
            attrs = new VirtualElementAttributes();

        attrs.set('onchange', 1);
        attrs.set('onkeyup', 2);

        c.removeEventHandlers(1);  // Assert no Exception

        c.existingEventMap.set(1, attrs);
        c.events.set(1, function() {});
        c.events.set(2, function() {});

        assertEquals(2, [for (key in c.events.keys()) 1].length);

        c.removeEventHandlers(1);  // Assert no Exception
        assertEquals(0, [for (key in c.events.keys()) 1].length);
    }

    public function testReplaceEventHandlers() {
        var r = new Component(),
            onChangeFunc = function() {},
            onKeyUpFunc = function() {},
            attrs = new VirtualElementAttributes(),
            resultAttrs = new VirtualElementAttributes();

        attrs.set('onchange', onChangeFunc);
        attrs.set('onkeyup', onKeyUpFunc);
        attrs.set('id', 'tamborine');

        resultAttrs.set('onchange', 1);
        resultAttrs.set('onkeyup', 0);
        resultAttrs.set('id', 'tamborine');

        function compareResults(output:VirtualElementAttributes) {
            assertEquals(2, [for (key in r.events.keys()) 1].length);
            for (key in resultAttrs.keys()) {
                assertTrue(output.exists(key));
            }
            assertEquals(resultAttrs.get('id'), output.get('id'));
            assertTrue(output.get('onkeyup') == 1 || output.get('onkeyup') == 0);
            assertTrue(output.get('onchange') == 1 || output.get('onchange') == 0);
            assertEquals([for (key in resultAttrs.keys()) 1].length, [for (key in output.keys()) 1].length);
        }

        compareResults(r.replaceEventHandlers(attrs, 1));

        // This is not a stutter.  Running it twice to check idempotency.
        compareResults(r.replaceEventHandlers(attrs, 1));
    }

    public function testCheckState() {
        var c = new MockComponent();
        c.updateReturnValue = [];
        assertEquals(0, c.currentState.length);
        c.checkState();
        assertEquals(0, c.currentState.length);
        c.updateReturnValue = [{
            elementId: 1,
            action: Symbol.forKey('AddElement')
        }];
        c.checkState();
        assertEquals(1, c.currentState.length);
    }

    public function testTriggerEvent() {
        var c = new Component();
        c.events.set(1, function(evt) {
            assertEquals(1, evt.id);
            assertEquals('test', evt.type);
            return false;
        });
        c.triggerEvent({
            id: 1,
            which: null,
            type: 'test',
            target: {value: 'test_value', checked: null}
        });

        c.events.set(2, function(evt) {
            assertEquals(2, evt.id);
            assertEquals('test2', evt.type);
        });
        try {
            c.triggerEvent({
                id: 2,
                which: null,
                type: 'test2',
                target: {value: 'test_value', checked: null}
            });
        } catch (e:Dynamic) {}

        c.triggerEvent({
            id: 3,
            which: null,
            type: 'test3',
            target: {value: 'test_value', checked: null}
        });
    }
}
