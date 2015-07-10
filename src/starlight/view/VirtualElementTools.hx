package starlight.view;

import starlight.core.Types.UnsafeMap;
import starlight.core.Exceptions.TypeException;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.VirtualElement.VirtualElementChildren;

using StringTools;

class VirtualElementTools {
    static var BOOLEAN_ATTRIBUTES = [
        'autofocus',
        'checked',
        'disabled',
        'formnovalidate',
        'multiple',
        'readonly'
    ];
    static var VOID_TAGNAMES = [
        'area',
        'base',
        'br',
        'col',
        'command',
        'embed',
        'hr',
        'img',
        'input',
        'keygen',
        'link',
        'meta',
        'param',
        'source',
        'track',
        'wbr'
    ];

    public inline static var TEXT_TAG = '#text';

    static inline public function isVoid(element:VirtualElement):Bool {
        return VOID_TAGNAMES.indexOf(element.tag.toLowerCase()) != -1;
    }

    static inline public function isText(element:{tag:String}):Bool {
        return element.tag == TEXT_TAG;
    }

    static public function toHTML(e:VirtualElement):String {
        if (VirtualElementTools.isVoid(e)) {
            var attrArray = [for (key in e.attrs.keys()) if (BOOLEAN_ATTRIBUTES.indexOf(key) == -1) '$key="${e.attrs.get(key)}"' else key];
            var attrString = ' ' + attrArray.join(' ');
            if (attrArray.length == 0) {
                attrString = '';
            }
            return '<${e.tag}$attrString>';
        } else if (VirtualElementTools.isText(e)) {
            return e.textValue;
        } else {
            var attrArray = [for (key in e.attrs.keys()) '$key="${e.attrs.get(key)}"'];
            var attrString = ' ' + attrArray.join(' ');
            if (attrArray.length == 0) {
                attrString = '';
            }
            var childrenString:String = [for (child in e.children) VirtualElementTools.toHTML(child)].join('');
            return '<${e.tag}$attrString>$childrenString</${e.tag}>';
        }
        return '';
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

    public inline static function parseSignature(signature:String):starlight.view.VirtualElement {
        var tagName = 'div';
        var attrs = new UnsafeMap();
        var classes = new Array<String>();
        var signatureRemaining = signature;

        function smallestPositive(a, b) {
            if (a == b) return 0;
            if (a < 0) a = a*-10000;
            if (b < 0) b = b*-10000;
            if (a > b)
                return 1;
            else
                return -1;
        }

        function getNext(str:String) {
            var indexes = [
                str.indexOf('.'),
                str.indexOf('#'),
                str.indexOf('[')
            ];
            indexes.sort(smallestPositive);
            if (indexes[0] == -1) {
                return str.length;
            }

            return indexes[0];
        }
        var nextElementIndex = getNext(signatureRemaining);

        if (nextElementIndex == 0) {
            tagName = 'div';
            nextElementIndex = getNext(signatureRemaining.substr(1));
        } else {
            tagName = signatureRemaining.substr(0, nextElementIndex).toLowerCase();
            signatureRemaining = signatureRemaining.substr(tagName.length);
            nextElementIndex = getNext(signatureRemaining.substr(1));
        }

        while(signatureRemaining.length != 0) {
            switch(signatureRemaining.charAt(0)) {
                case "#": attrs.set("id", signatureRemaining.substr(1, nextElementIndex));
                case ".": classes.push(signatureRemaining.substr(1, nextElementIndex));
                case "[": {
                    var attrElements = signatureRemaining.substring(1, signatureRemaining.indexOf(']')).split('=');
                    switch(attrElements) {
                        case [name, value]: attrs.set(name, value);
                        case [name]: attrs.set(name, "true");
                        default: throw new TypeException('Attributes is not properly formatted: ${attrElements.join("=")}');
                    }
                }
                default: throw new TypeException('Invalid signature: "$signatureRemaining"');
            }

            signatureRemaining = signatureRemaining.substr(nextElementIndex+1);
            nextElementIndex = getNext(signatureRemaining.substr(1));
        }

        if (classes.length > 0) {
            var classAttr = new UnsafeMap();
            for (cls in classes) {
                classAttr.set(cls, true);
            }
            attrs.set('class', classAttr);
        }

        return {tag: tagName, attrs: attrs};
    }

    /* element is purely a convenience function for helping to create views. */
    public static function element(signature:String, ?attrStruct:Dynamic, ?children:Dynamic):VirtualElement {
        var childArray:VirtualElementChildren = new VirtualElementChildren();
        var paramChildArray = new Array<Dynamic>();

        // Allow the short form of specifying children without attributes.
        switch(Type.typeof(attrStruct)) {
            case TClass(s): {
                switch(Type.getClassName(s)) {
                    case 'String': {
                        paramChildArray.push(attrStruct);
                    }
                    case 'Array': {
                        paramChildArray = cast attrStruct;
                    }
                    default: throw new TypeException("Invalid Type passed to View.element for attributes");
                }
                attrStruct = {};
            }
            case TObject: {
                switch(Type.typeof(children)) {
                    case TClass(s): {
                        switch(Type.getClassName(s)) {
                            case 'String': {
                                paramChildArray.push(children);
                            }
                            case 'Array': {
                                paramChildArray = cast children;
                            }
                            default: throw new TypeException("Invalid Type passed to View.element for children");
                        }
                    }
                    case TNull: {}
                    default: throw new TypeException("Invalid Type passed to View.element for children");
                }
            }
            case TNull: {
                attrStruct = {};
            }
            case TEnum(e): {
                throw new TypeException('Elements can\'t set attributes to enum: $e');
            }
            case TFunction: {
                // TODO - This should run the function and reclassify it through this switch statement as a child.
                var child = attrStruct();
                switch(Type.getClassName(child)) {
                    case 'String': paramChildArray.push(child);
                    case 'Array': paramChildArray = cast child;
                    default: paramChildArray.push('' + child);
                }
                attrStruct = {};
            }
            default: {
                paramChildArray.push('' + attrStruct);
                attrStruct = {};
            }
        }

        var ve = parseSignature(signature);
        var attrs:VirtualElementAttributes = ve.attrs;
        var classes:UnsafeMap;

        if (attrs.exists('class')) {
            classes = attrs.get('class');
        } else {
            classes = new UnsafeMap();
        }

        for (attrName in Reflect.fields(attrStruct)) {
            var value = Reflect.field(attrStruct, attrName);
            if (attrName == 'class') {
                switch(Type.typeof(value)) {
                    case TObject: {
                        for (key in Reflect.fields(value)) {
                            classes.set(key, Reflect.field(value, key));
                        }
                    }
                    case TClass(s): classes.set(value, true);
                    default: throw new TypeException("InvalidType passed to element.class");
                }
            } else if (ve.tag == 'input' && attrName == 'checked') {
                attrs.set(attrName, if (cast value) 'checked' else null);
            } else {
                attrs.set(attrName, value);
            }
        }

        if ([for (key in classes.keys()) true].length > 0) {
            attrs.set('class', buildClassString(classes));
        }

        if (paramChildArray.length > 0) {
            for (child in paramChildArray) {
                if (Type.getClass(child) == String) {
                    // Add a string as a TextNode
                    childArray.push({
                        tag:VirtualElementTools.TEXT_TAG,
                        textValue: child
                    });
                } else {
                    childArray.push(child);
                }
            }
        }

        return {
            tag:ve.tag,
            attrs:attrs,
            children:childArray
        };
    }
}
