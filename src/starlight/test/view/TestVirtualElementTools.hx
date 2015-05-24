package starlight.test.view;

import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.VirtualElement.VirtualElementChildren;
import starlight.view.VirtualElement.VirtualElement;

using starlight.view.VirtualElementTools.VirtualElementTools;
using StringTools;

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
        var c = new VirtualElementChildren();
        var ve1:VirtualElement = {
            tag:"#text",
            children:[],
            textValue:"Hi"
        };
        var ve2:VirtualElement = {
            tag:"#text",
            children:[],
            textValue:"Bye"
        }

        assertTrue(a.childrenEquals(b));

        a.push(ve1);
        assertFalse(a.childrenEquals(b));
        assertFalse(b.childrenEquals(a));

        b.push(ve2);
        assertFalse(a.childrenEquals(b));
        assertFalse(b.childrenEquals(a));

        c.push(ve1);
        assertTrue(a.childrenEquals(c));
    }

#if js
    public function testBuildClassString() {
        var a = VirtualElementTools.buildClassString(cast {on: true, off: false}),
            b = VirtualElementTools.buildClassString(cast {on: false, off: true}),
            c = VirtualElementTools.buildClassString(cast {on: true, off: true});

        assertEquals('on', a);
        assertEquals('off', b);
        assertEquals('on off', c);
    }

    public function testChildren() {
        var a = VirtualElementTools.buildChildren([{tag: VirtualElementTools.TEXT_TAG, textValue: 'hi'}]),
            b = VirtualElementTools.buildChildren('hi'),
            c = VirtualElementTools.buildChildren(1);

        assertEquals(Type.getClass(a), Array);
        assertEquals(a[0].tag, VirtualElementTools.TEXT_TAG);
        assertEquals(a[0].textValue, 'hi');
        assertEquals(Type.getClass(b), Array);
        assertEquals(b[0].tag, VirtualElementTools.TEXT_TAG);
        assertEquals(b[0].textValue, 'hi');
        assertEquals(Type.getClass(c), Array);
        assertEquals(c[0].tag, VirtualElementTools.TEXT_TAG);
        assertEquals(c[0].textValue, '1');
    }
#end
}

class TestElementCreation extends starlight.core.test.TestCase {
    function assertVoidHTMLEquals(control:String, variable:String) {
        var index = Std.int(Math.min(control.indexOf(' ', 2), control.indexOf('>', 2))) + 1;

        var conTag = control.substring(1, index - 1);
        var conElements = control.substring(index, -1).trim().split(' ');

        var varTag = variable.substring(1, index - 1);
        var varElements = variable.substring(index, -1).trim().split(' ');

        // Check Tag names
        assertEquals(conTag, varTag);

        var conAttrs = new haxe.ds.StringMap<String>();
        var conKeyCount = 0;
        for (entry in conElements) {
            var elements = entry.split('=');
            if (elements.length == 1) {
                conAttrs.set(elements[0], 'true');
            } else {
                conAttrs.set(elements[0], elements[1]);
            }
            conKeyCount++;
        }
        var varAttrs = new haxe.ds.StringMap<String>();
        var varKeyCount = 0;
        for (entry in varElements) {
            var elements = entry.split('=');
            if (elements.length == 1) {
                varAttrs.set(elements[0], 'true');
            } else {
                varAttrs.set(elements[0], elements[1]);
            }
            varKeyCount++;
        }

        assertEquals(conKeyCount, varKeyCount);

        for (key in conAttrs.keys()) {
            assertEquals(conAttrs.get(key), varAttrs.get(key));
        }
    }

    function assertHTMLEquals(control:String, variable:String) {
        var index = control.indexOf('>', 2) + 1;
        assertEquals(index, variable.indexOf('>', 2) + 1);

        assertVoidHTMLEquals(
            control.substring(0, index),
            variable.substring(0, index)
        );

        var contentEndingIndex = control.length - (index + 1);

        while(index < contentEndingIndex) {
            if (control.charAt(index) != '<') {
                assertEquals(control.substring(index, control.indexOf('<', index)), variable.substring(index, variable.indexOf('<', index)));
            } else {
                assertVoidHTMLEquals(
                    control.substring(index, control.indexOf('>', index)),
                    variable.substring(index, variable.indexOf('>', index))
                );
            }
            index = control.indexOf('<', index +1);
        }
    }

    public function testVoidGeneration() {
        var ve = VirtualElementTools.element('br');
        assertVoidHTMLEquals('<br>', ve.toHTML());

        var ve = VirtualElementTools.element('input', {"class": "text"});
        assertVoidHTMLEquals('<input class="text">', ve.toHTML());

        var ve = VirtualElementTools.element('input[type=checkbox]', {"class": "text", "checked": true});
        assertVoidHTMLEquals('<input class="text" type="checkbox" checked>', ve.toHTML());

        var ve = VirtualElementTools.element('input#id.header', {"data-bind": "value: text"});
        assertVoidHTMLEquals('<input id="id" class="header" data-bind="value: text">', ve.toHTML());
    }

    public function testStandardTagGeneration() {
        var ve = VirtualElementTools.element('h1');
        assertHTMLEquals('<h1></h1>', ve.toHTML());

        var ve = VirtualElementTools.element('h2', {"class": "text"});
        assertHTMLEquals('<h2 class="text"></h2>', ve.toHTML());

        var ve = VirtualElementTools.element('.text');
        assertHTMLEquals('<div class="text"></div>', ve.toHTML());

        var ve = VirtualElementTools.element('');
        assertHTMLEquals('<div></div>', ve.toHTML());

        var ve = VirtualElementTools.element('span#id.header', {"data-bind": "value: text"});
        assertHTMLEquals('<span id="id" class="header" data-bind="value: text"></span>', ve.toHTML());
    }

    public function testNestedTagGeneration() {
        var e = VirtualElementTools.element;

        var ve = e('h1', {}, ['hi']);
        assertHTMLEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h1', {}, 'hi');
        assertHTMLEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h2', {"class": "text"}, [e('span', {"class": "header"}, ["Title"])]);
        assertHTMLEquals('<h2 class="text"><span class="header">Title</span></h2>', ve.toHTML());

        var ve = e('span#id.header', {"data-bind": "value: text"}, [
            "Title - ",
            e('div', {"data-bind": "value: $index"})
        ]);
        assertHTMLEquals('<span id="id" class="header" data-bind="value: text">Title - <div data-bind="value: $$index"></div></span>', ve.toHTML());
    }

    public function testTagGenerationWithOptionalAttributes() {
        var e = VirtualElementTools.element;

        var ve = e('h1', ['hi']);
        assertHTMLEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h1', 'hi');
        assertHTMLEquals('<h1>hi</h1>', ve.toHTML());

        var ve = e('h1', ['hi', e('span', {"class": "header"}, ["Title"])]);
        assertHTMLEquals('<h1>hi<span class="header">Title</span></h1>', ve.toHTML());
    }
}

