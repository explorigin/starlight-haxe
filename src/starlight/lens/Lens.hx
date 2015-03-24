package starlight.lens;

import starlight.lens.VirtualElement.IVirtualElement;
import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VoidVirtualElement;
import starlight.lens.VirtualElement.StandardVirtualElement;
import starlight.lens.VirtualElement.TextVirtualElement;

using StringTools;

class Lens {
    static var parser = ~/((^|#|\.)([^#\.\[]+))|(\[.+\])/g;
    static var attrParser = ~/\[([A-z]+)(=([A-z]+))?\]/;  // Not the most efficient but EReg has some pretty severe restrictions.
    static var singleTagElements = ~/^(AREA|BASE|BR|COL|COMMAND|EMBED|HR|IMG|INPUT|KEYGEN|LINK|META|PARAM|SOURCE|TRACK|WBR)$/;

    public static function element(signature:String, ?attrStruct:Dynamic, ?children:Dynamic):IVirtualElement {
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
                    default: throw "Invalid Type passed to Lens.element";
                }
                attrStruct = {};
            }
            case TObject: {
                if (children != null) {
                    paramChildArray = cast children;
                } else {
                    paramChildArray = new Array<Dynamic>();
                }
            };
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

        var isSingleTag = singleTagElements.match(tagName.toUpperCase());

        var cell:Dynamic = switch(isSingleTag) {
            case true: new VoidVirtualElement(tagName, new VirtualElementAttributes());
            default: new StandardVirtualElement(tagName, new VirtualElementAttributes());
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
        cell.attrs = attrs;


        if (!isSingleTag && paramChildArray != null) {
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
}
