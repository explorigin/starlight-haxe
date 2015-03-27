package starlight.lens;

import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VirtualElement;
import starlight.lens.VirtualElement.TextVirtualElement;
import starlight.lens.VirtualElement.ElementUpdate;
import starlight.lens.VirtualElement.ElementAction.*;

using StringTools;
using VirtualElement.VirtualElementTools;

class Lens {
    static var parser = ~/((^|#|\.)([^#\.\[]+))|(\[.+\])/g;
    static var attrParser = ~/\[([A-z]+)(=([A-z]+))?\]/;  // Not the most efficient but EReg has some pretty severe restrictions.

    public var pendingUpdates:Array<ElementUpdate> = [];

    public function new() {}

    public static function element(signature:String, ?attrStruct:Dynamic, ?children:Dynamic):VirtualElement {
        var childArray:VirtualElementChildren;

        var tagName = 'div';
        var classAttrName = Reflect.hasField(attrStruct, "class") ? "class" : "className";
        var attrs = new VirtualElementAttributes();
        var classes = new Array<String>();
        var paramChildArray:Array<Dynamic>;

        // Allow the short form of specifying children without attributes.
        switch(Type.typeof(attrStruct)) {
            case TClass(s): {
                switch(Type.getClassName(s)) {
                    case 'String': {
                        paramChildArray = new Array<Dynamic>();
                        paramChildArray.push(attrStruct);
                    }
                    case 'Array': {
                        paramChildArray = cast attrStruct;
                    }
                    default: throw "Invalid Type passed to Lens.element for attributes";
                }
                attrStruct = {};
            }
            case TObject: {
                switch(Type.typeof(children)) {
                    case TClass(s): {
                        switch(Type.getClassName(s)) {
                            case 'String': {
                                paramChildArray = new Array<Dynamic>();
                                paramChildArray.push(children);
                            }
                            case 'Array': {
                                paramChildArray = cast children;
                            }
                            default: throw "Invalid Type passed to Lens.element for children";
                        }
                    }
                    case TNull: paramChildArray = new Array<Dynamic>();
                    default: throw "Invalid Type passed to Lens.element for children";
                }
            }
            case TNull: {
                attrStruct = {};
                paramChildArray = new Array<Dynamic>();
            }
            default: throw 'Invalid Type passed to Lens.element: $attrStruct';
        }

        var keepGoing = parser.match(signature);

        while(keepGoing) {
            switch(parser.matched(2)) {
                case "": tagName = parser.matched(3);
                case "#": attrs.set("id", parser.matched(3));
                case ".": classes.push(parser.matched(3));
                default: {
                    if (parser.matched(4).charAt(0) == "[") {
                        if(attrParser.match(parser.matched(4))) {
                            if (attrParser.matched(3) != "") {
                                attrs.set(attrParser.matched(1), attrParser.matched(3));
                            } else if (attrParser.matched(2) != "") {
                                attrs.set(attrParser.matched(1), "");
                            } else {
                                attrs.set(attrParser.matched(1), "true");
                            }
                        }
                    }
                }
            }

            keepGoing = parser.match(parser.matchedRight());
        }

        if (classes.length > 0) {
            attrs.set('class', classes.join(" "));
        }

        for (attrName in Reflect.fields(attrStruct)) {
            var value = Reflect.field(attrStruct, attrName);
            if (attrName == classAttrName) {
                if (value != "") {
                    var cellValue = attrs.get(attrName);
                    attrs.set(attrName, (if (cellValue != null) cellValue else "") + " " + value);
                }
            } else {
                attrs.set(attrName, value);
            }
        }
        if (attrs.get('class') != null) {
            attrs.set('class', attrs.get('class').trim());
        }
        var cell = new VirtualElement(tagName, attrs);

        if (paramChildArray != null) {
            childArray = cell.children;
            for (child in paramChildArray) {
                if (Reflect.hasField(child, 'tag')) {
                    childArray.push(child);
                } else {
                    childArray.push(new TextVirtualElement(cast child));
                }
            }
        }
        return cell;
    }

    inline function appendUpdate(update:Array<ElementUpdate>) {
        pendingUpdates = pendingUpdates.concat(update);
    }

    /* update will bring the `current` to parity with `next` and append all the necessary changes to `pendingChanges`.
     * Finally, it will return the new `current`
    */
    public function update(next:VirtualElement, current:VirtualElement, ?parentId:Int, ?parentIndex:Int):VirtualElement {
        // TODO: implement a keying algorithm for efficient reordering
        var index = 0;
        var larger:VirtualElementChildren;
        var smaller:VirtualElementChildren;
        var normalOrder = true;


        if (current == null) {
            // If there is nothing to compare, just create it.
            appendUpdate(next.getUpdates(AddElement, parentId, parentIndex));
            larger = next.children;
            smaller = new VirtualElementChildren();
        } else if (next == null) {
            // If there is nothing there, just remove it.
            appendUpdate(current.getUpdates(RemoveElement, parentId, parentIndex));
            return null;
        } else if (next.tag != current.tag) {
            // Remove the old element
            appendUpdate(current.getUpdates(RemoveElement, parentId, parentIndex));
            // Update the new element
            appendUpdate(next.getUpdates(AddElement, parentId, parentIndex));
            larger = next.children;
            smaller = new VirtualElementChildren();
        } else {
            if (!next.attrs.attrEquals(current.attrs) || next.textValue != current.textValue) {
                // Update the current element
                appendUpdate(next.getUpdates(UpdateElement, parentId, parentIndex));
            }

            if (next.children.length > current.children.length) {
                larger = next.children;
                smaller = current.children;
            } else {
                larger = current.children;
                smaller = next.children;
                normalOrder = false;
            }

        }

        for (child in larger) {
            if (normalOrder) {
                update(child, smaller[index], next.id, index);
            } else {
                update(smaller[index], child, next.id, index);
            }
            index++;
        }

        return next;
    }
}
