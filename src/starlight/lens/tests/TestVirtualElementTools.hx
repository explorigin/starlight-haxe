package starlight.lens.tests;

import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.VirtualElement;

using starlight.lens.VirtualElement.VirtualElementTools;

class TestVirtualElementTools extends haxe.unit.TestCase {
    public function testToHTML() {
        var ve:VirtualElement = {
            tag:"#text",
            id:1,
            children:[],
            textValue:"Hi"
        };
        assertEquals(ve.toHTML(), 'Hi');
    }

    public function testVoidTagToHTML() {
        var ve:VirtualElement = {
            tag:"br",
            id:1,
            attrs:new VirtualElementAttributes(),
            children:[],
            isVoid: true
        };
        assertEquals('<br>', ve.toHTML());

        var attrs = new VirtualElementAttributes();
        attrs.set('type', 'text');
        ve = {
            tag:"input",
            id:1,
            attrs:attrs,
            children:[],
            isVoid: true
        };
        assertEquals(ve.toHTML(), '<input type="text">');
    }

    public function testStandardTagHTML() {
        var attrs = new VirtualElementAttributes();
        attrs.set('href', 'about:config');
        var ve:VirtualElement = {
            tag:"a",
            id:1,
            attrs:attrs,
            children:[]
        };
        assertEquals(ve.toHTML(), '<a href="about:config"></a>');
    }

    public function testStandardTagHTMLWithChildren() {
        var attrs = new VirtualElementAttributes();
        attrs.set('href', 'about:config');
        var ve:VirtualElement = {
            tag:"a",
            id:1,
            attrs:attrs,
            children:[{
                tag:"#text",
                id:1,
                children:[],
                textValue:"Hi"
            }]
        };
        assertEquals(ve.toHTML(), '<a href="about:config">Hi</a>');
    }

    public function testIsVoidTag() {
        assertTrue('br'.isVoidTag());
        assertFalse('a'.isVoidTag());
    }

    public function testIsTextTag() {
        assertTrue('#text'.isTextTag());
        assertFalse('a'.isTextTag());
    }

    public function testAttrEquals() {
        var a = new VirtualElementAttributes();
        var b = new VirtualElementAttributes();

        assertTrue(a.attrEquals(b));

        b.set('key', 'value');
        assertFalse(a.attrEquals(b));
        assertFalse(b.attrEquals(a));

        a.set('key', 'value');
        assertTrue(a.attrEquals(b));
    }

    public function testChildrenEquals() {
        var a = new VirtualElementChildren();
        var b = new VirtualElementChildren();
        var ve:VirtualElement = {
            tag:"#text",
            id:1,
            children:[],
            textValue:"Hi"
        };

        assertTrue(a.childrenEquals(b));

        b.push(ve);
        assertFalse(a.childrenEquals(b));
        assertFalse(b.childrenEquals(a));

        a.push(ve);
        assertTrue(a.childrenEquals(b));
    }
}
