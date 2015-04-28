package starlight.lens.tests;

import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.VirtualElement;

using starlight.lens.VirtualElement.VirtualElementTools;

class TestVirtualElementTools extends haxe.unit.TestCase {
    public function testToHTML() {
        var ve:VirtualElement = {
            tag:"#text",
            children:[],
            textValue:"Hi"
        };
        assertEquals(ve.toHTML(), 'Hi');
    }

    public function testVoidTagToHTML() {
        var ve:VirtualElement = {
            tag:"br",
            attrs:new VirtualElementAttributes(),
            children:[]
        };
        assertEquals('<br>', ve.toHTML());

        var attrs = new VirtualElementAttributes();
        attrs.set('type', 'text');
        ve = {
            tag:"input",
            attrs:attrs,
            children:[]
        };
        assertEquals(ve.toHTML(), '<input type="text">');
    }

    public function testStandardTagHTML() {
        var attrs = new VirtualElementAttributes();
        attrs.set('href', 'about:config');
        var ve:VirtualElement = {
            tag:"a",
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
            attrs:attrs,
            children:[{
                tag:"#text",
                children:[],
                textValue:"Hi"
            }]
        };
        assertEquals(ve.toHTML(), '<a href="about:config">Hi</a>');
    }

    public function testIsVoid() {
        var v1:VirtualElement = {
            tag:"a",
            attrs:new VirtualElementAttributes(),
            children:[]
        };
        var v2:VirtualElement = {
            tag:"br",
            attrs:new VirtualElementAttributes(),
            children:[]
        };
        assertFalse(v1.isVoid());
        assertTrue(v2.isVoid());
    }

    public function testIsText() {
        var v1:VirtualElement = {
            tag:VirtualElementTools.TEXT_TAG,
            attrs:new VirtualElementAttributes(),
            children:[]
        };
        var v2:VirtualElement = {
            tag:"br",
            attrs:new VirtualElementAttributes(),
            children:[]
        };
        assertTrue(v1.isText());
        assertFalse(v2.isText());
    }

    public function testChildrenEquals() {
        var a = new VirtualElementChildren();
        var b = new VirtualElementChildren();
        var ve:VirtualElement = {
            tag:"#text",
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
