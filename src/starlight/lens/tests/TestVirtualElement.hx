package starlight.lens.tests;

import haxe.Serializer;

import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.StandardVirtualElement;
import starlight.lens.VirtualElement.TextVirtualElement;
import starlight.lens.VirtualElement.VoidVirtualElement;

class TestVirtualElement extends haxe.unit.TestCase {
    public function testVoidHTML() {
        var ve = new VoidVirtualElement("br");
        assertEquals(ve.toHTML(), '<br>');

        var attrs = new VirtualElementAttributes();
        attrs.set("type", "text");
        var ve = new VoidVirtualElement("input", attrs);
        assertEquals(ve.toHTML(), '<input type="text">');
    }

    public function testTextHTML() {
        var ve = new TextVirtualElement("Hi");
        assertEquals(ve.toHTML(), 'Hi');
    }

    public function testEnclosedTagHTML() {
        var attrs = new VirtualElementAttributes();
        attrs.set("href", "about:config");
        var ve = new StandardVirtualElement("a", attrs);
        assertEquals(ve.toHTML(), '<a href="about:config"></a>');
    }

    public function testEnclosedTagHTMLWithChildren() {
        var attrs = new VirtualElementAttributes();
        attrs.set("href", "about:config");
        var ve = new StandardVirtualElement("a", attrs, [new TextVirtualElement("Hi")]);
        assertEquals(ve.toHTML(), '<a href="about:config">Hi</a>');
    }
}
