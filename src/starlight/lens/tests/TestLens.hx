package starlight.lens.tests;

import starlight.lens.Lens;
import starlight.lens.Lens;
using VirtualElement.VirtualElementTools;

class TestLensElement extends haxe.unit.TestCase {
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
        var l = new Lens();

        var next = e('h2', {"class": "test"}, "Header");

        assertEquals(0, l.pendingUpdates.length);
        var final = l.update(next, null);

        // Our return value should always equal `next`
        assertTrue(final.veEquals(next));
        assertEquals(1, final.children.length);
        assertTrue(final.children[0].veEquals(new VirtualElement.TextVirtualElement('Header')));

        // There should be updates that detail the transition steps.
        assertEquals(2, l.pendingUpdates.length);

        assertAddedUpdate(final.tag, final.attrs, null, null, l.pendingUpdates[0]);
        assertAddedUpdate('#text', null, l.pendingUpdates[0].elementId, 0, l.pendingUpdates[1], 'Header');
    }
    public function testElementAttributeChange() {
        var l = new Lens();

        var current = e('h1');
        var next = e('h1', {"class": "test"});

        assertEquals(0, l.pendingUpdates.length);
        var final = l.update(next, current);

        // Our return value should always equal `next`
        assertTrue(final.veEquals(next));
        assertEquals(0, final.children.length);

        // There should be updates that detail the transition steps.
        assertEquals(1, l.pendingUpdates.length);
        assertEquals(final.tag, l.pendingUpdates[0].tag);
        assertTrue(final.attrs.attrEquals(l.pendingUpdates[0].attrs));
    }

    public function testElementRemoveChild() {
        var l = new Lens();

        var current = e('h1', {"class": "test"}, "Header");
        var next = e('h1', {"class": "test"});

        assertEquals(0, l.pendingUpdates.length);
        var final = l.update(next, current);

        // Our return value should always equal `next`
        assertTrue(final.veEquals(next));
        assertEquals(0, final.children.length);

        // There should be updates that detail the transition steps.
        assertEquals(1, l.pendingUpdates.length);
        assertRemovedUpdate(current.children[0].id, final.id, 0, l.pendingUpdates[0]);
    }

    public function testElementAddChild() {
        var l = new Lens();

        var current = e('h1', {"class": "test"});
        var next = e('h1', {"class": "test"}, "Header");

        assertEquals(0, l.pendingUpdates.length);
        var final = l.update(next, current);

        // Our return value should always equal `next`
        assertTrue(final.veEquals(next));
        assertEquals(1, final.children.length);
        assertTrue(final.children[0].veEquals(new VirtualElement.TextVirtualElement('Header')));

        // There should be updates that detail the transition steps.
        assertEquals(1, l.pendingUpdates.length);
        assertAddedUpdate('#text', null, final.id, 0, l.pendingUpdates[0], 'Header');
    }

    public function testElementReplacement() {
        var l = new Lens();

        var current = e('h1');
        var next = e('h2');

        assertEquals(0, l.pendingUpdates.length);
        var final = l.update(next, current);

        // Our return value should always equal `next`
        assertEquals(next.tag, final.tag);

        // There should be updates that detail the transition steps.
        assertEquals(2, l.pendingUpdates.length);
        assertRemovedUpdate(current.id, null, null, l.pendingUpdates[0]);

        assertEquals('h2', l.pendingUpdates[1].tag);
    }}
