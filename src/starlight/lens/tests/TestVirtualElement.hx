package starlight.lens.tests;

import haxe.Serializer;

import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.VirtualElement;
import starlight.lens.VirtualElement.TextVirtualElement;

class TestVirtualElement extends haxe.unit.TestCase {
    public function testTextHTML() {
        var ve = new TextVirtualElement("Hi");
        assertEquals(ve.toHTML(), 'Hi');
    }

    public function testVoidTagHTML() {
        var ve = new VirtualElement("br");
        assertEquals(ve.toHTML(), '<br>');

        var attrs = new VirtualElementAttributes();
        attrs.set("type", "text");
        var ve = new VirtualElement("input", attrs);
        assertEquals(ve.toHTML(), '<input type="text">');
    }

    public function testStandardTagHTML() {
        var attrs = new VirtualElementAttributes();
        attrs.set("href", "about:config");
        var ve = new VirtualElement("a", attrs);
        assertEquals(ve.toHTML(), '<a href="about:config"></a>');
    }

    public function testStandardTagHTMLWithChildren() {
        var attrs = new VirtualElementAttributes();
        attrs.set("href", "about:config");
        var ve = new VirtualElement("a", attrs, [new TextVirtualElement("Hi")]);
        assertEquals(ve.toHTML(), '<a href="about:config">Hi</a>');
    }
}
