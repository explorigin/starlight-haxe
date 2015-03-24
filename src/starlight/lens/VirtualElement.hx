package starlight.lens;

import haxe.ds.StringMap;

using StringTools;
using starlight.lens.VirtualElement.VirtualElementArrayExtender;



typedef VirtualElementAttributes = StringMap<String>;
typedef VirtualElementChildren = Array<IVirtualElement>;


interface IVirtualElement {
    public var tag:String;
    public function toHTML():String;
}


class VirtualElementArrayExtender {
    static public function toHTML(children:VirtualElementChildren) {
        return [for (child in children) child.toHTML()].join('');
    }
}

class VirtualElement {
    static inline var TEXT_TAG = '#text';
    static var nodeIndex:Int = 0;

    public var id:Int;
    public var tag:String;

    public function new(tag:String) {
        id = nodeIndex++;
        this.tag = tag;
    }
}


class TextVirtualElement extends VirtualElement implements IVirtualElement {
    public var textValue:String;

    public function new(textValue:String = '') {
        super("#text");

        this.textValue = textValue;
    }

    public function toHTML() {
        return textValue;
    }
}


class VoidVirtualElement extends VirtualElement implements IVirtualElement {
    public var attrs:VirtualElementAttributes;
    public static var BOOLEAN_ATTRIBUTES = [
        'autofocus',
        'checked',
        'disabled',
        'formnovalidate',
        'multiple',
        'readonly'
    ];

    public function new(tag:String, ?attrs:VirtualElementAttributes) {
        super(tag);

        this.attrs = if (attrs != null) attrs else new VirtualElementAttributes();
    }

    public function toHTML() {
        var attrArray = [for (key in attrs.keys()) if (BOOLEAN_ATTRIBUTES.indexOf(key) == -1) '$key="${attrs.get(key)}"' else key];
        var attrString = ' ' + attrArray.join(' ');
        if (attrArray.length == 0) {
            attrString = '';
        }
        return '<$tag$attrString>';
    }
}


class StandardVirtualElement extends VoidVirtualElement {
    public var children:VirtualElementChildren;

    public function new(tag:String, ?attrs:VirtualElementAttributes, ?children:VirtualElementChildren) {
        super(tag, attrs);

        this.children = if (children != null) children else new VirtualElementChildren();
    }

    public function removeNode() {
        if (attrs.exists('onUnload')) {
            attrs.get('onUnload');
        }
    }

    public override function toHTML() {
        var attrArray = [for (key in attrs.keys()) '$key="${attrs.get(key)}"'];
        var attrString = ' ' + attrArray.join(' ');
        if (attrArray.length == 0) {
            attrString = '';
        }
        var childrenString:String = children.toHTML();
        return '<$tag$attrString>$childrenString</$tag>';
    }
}
