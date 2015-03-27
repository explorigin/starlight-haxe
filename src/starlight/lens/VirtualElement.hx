package starlight.lens;

import haxe.ds.StringMap;

using StringTools;
using VirtualElement.VirtualElementTools;


typedef VirtualElementAttributes = StringMap<String>;
typedef VirtualElementChildren = Array<VirtualElement>;

enum ElementAction {
    RemoveElement;
    AddElement;
    UpdateElement;
    MoveElement;
}

typedef ElementUpdate = {
    elementId:Int,
    ?tag:String,
    ?attrs:VirtualElementAttributes,
    ?textValue:String,
    ?oldParent:Int,
    ?oldIndex:Int,
    ?newParent:Int,
    ?newIndex:Int
}

class VirtualElementTools {
    static public function toHTML(children:VirtualElementChildren):String {
        return [for (child in children) child.toHTML()].join('');
    }

    static public function childrenEquals(a:VirtualElementChildren, b:VirtualElementChildren):Bool {
        if (a.length == b.length) {
            var len = a.length;
            while(len-- != 0) {
                if (a[len] != b[len]) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    static public function attrEquals(a:VirtualElementAttributes, b:VirtualElementAttributes):Bool {
        for (key in a.keys()) {
            if (a.get(key) != b.get(key)) {
                return false;
            }
        }

        return ([for (k in a.keys()) true].length == [for (k in b.keys()) true].length);
    }

    static public function veEquals(a:VirtualElement, b:VirtualElement):Bool {
        return a.tag == b.tag && a.attrs.attrEquals(b.attrs) && a.textValue == b.textValue;
    }
}

class VirtualElement {
    static inline var TEXT_TAG = '#text';

    static var nodeIndex:Int = 0;

    static var BOOLEAN_ATTRIBUTES = [
        'autofocus',
        'checked',
        'disabled',
        'formnovalidate',
        'multiple',
        'readonly'
    ];
    static var VOID_TAGNAMES = ~/^(AREA|BASE|BR|COL|COMMAND|EMBED|HR|IMG|INPUT|KEYGEN|LINK|META|PARAM|SOURCE|TRACK|WBR)$/i;

    var isVoid:Bool;

    public var id:Int;
    public var tag:String;
    public var attrs:VirtualElementAttributes;
    public var children:VirtualElementChildren;
    public var textValue:String;

    public function new(tag:String, ?attrs:VirtualElementAttributes, ?children:VirtualElementChildren, ?index:Int) {
        id = if (index != null) index else nodeIndex++;
        this.tag = tag;

        isVoid = VOID_TAGNAMES.match(tag);

        this.attrs = if (attrs != null) attrs else new VirtualElementAttributes();
        this.children = if (children != null) children else new VirtualElementChildren();
    }

    public inline function equals(other:VirtualElement):Bool {
        var attrKeyString = [for (key in attrs.keys()) key].join('');
        var otherAttrKeyString = [for (key in other.attrs.keys()) key].join('');
        return id == other.id && attrKeyString == otherAttrKeyString;
    }

    public function toHTML() {
        if (isVoid) {
            var attrArray = [for (key in attrs.keys()) if (BOOLEAN_ATTRIBUTES.indexOf(key) == -1) '$key="${attrs.get(key)}"' else key];
            var attrString = ' ' + attrArray.join(' ');
            if (attrArray.length == 0) {
                attrString = '';
            }
            return '<$tag$attrString>';
        } else {
            var attrArray = [for (key in attrs.keys()) '$key="${attrs.get(key)}"'];
            var attrString = ' ' + attrArray.join(' ');
            if (attrArray.length == 0) {
                attrString = '';
            }
            var childrenString:String = children.toHTML();
            return '<$tag$attrString>$childrenString</$tag>';
        }
    }
}

class TextVirtualElement extends VirtualElement {
    public function new(textValue:String = '') {
        super("#text");

        this.textValue = textValue;
    }

    public override inline function toHTML() {
        return textValue;
    }
}
