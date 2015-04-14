package starlight.lens;

import starlight.lens.VirtualElement.VirtualElementChildren;
import starlight.lens.VirtualElement.VirtualElementAttributes;
import starlight.lens.VirtualElement.VirtualElement;

#if !js
using StringTools;
#end
using VirtualElement.VirtualElementTools;

enum ElementAction {
    RemoveElement;
    AddElement;
    UpdateElement;
    MoveElement;
}

typedef ElementUpdate = {
    action:ElementAction,
    elementId:Int,
    ?tag:String,
    ?attrs:VirtualElementAttributes,
    ?textValue:String,
    ?newParent:Int,
    ?newIndex:Int
}

#if js
    typedef ElementType = js.html.Element;
#else
    typedef ElementType = Dynamic;
#end


class Lens {
    static var parser = ~/((^|#|\.)([^#\.\[]+))|(\[.+\])/g;
    static var attrParser = ~/\[([A-z]+)(=([A-z]+))?\]/;      //  Not the most efficient but EReg has some pretty severe restrictions.
    static var elementPropertyAttributes = ~/^(list|style|form|type|width|height)$/i;

    static var nodeCounter = 0;

    var e = element;  //  A shortcut for easy access in the `view` method.
    var root:ElementType;
    public var elementCache = new haxe.ds.IntMap<ElementType>();
    public var currentState = new Array<VirtualElement>();

    public function new() {
#if js
        this.root = js.Browser.document.body;
#end
    };

    /* element is purely a convenience function for helping to create views. */
    public static function element(signature:String, ?attrStruct:Dynamic, ?children:Dynamic):VirtualElement {
        var tagName = 'div';
        var attrs = new VirtualElementAttributes();
        var childArray:VirtualElementChildren = new VirtualElementChildren();

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
                paramChildArray = new Array<Dynamic>();
                attrStruct = {};
            }
            case TEnum(e): {
                throw 'Elements can\'t set attributes to enum: $e';
            }
            case TFunction: {
                // TODO - This should run the function and reclassify it through this switch statement as a child.
                paramChildArray = new Array<Dynamic>();
                var child = attrStruct();
                switch(Type.getClassName(child)) {
                    case 'String': paramChildArray.push(child);
                    case 'Array': paramChildArray = cast child;
                    default: paramChildArray.push('' + child);
                }
                attrStruct = {};
            }
            default: {
                paramChildArray = new Array<Dynamic>();
                paramChildArray.push('' + attrStruct);
                attrStruct = {};
            }
        }

        var classAttrName = Reflect.hasField(attrStruct, "class") ? "class" : "className";
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
#if js
            attrs.set('class', untyped __js__("attrs.get('class').trim()"));
#else
            attrs.set('class', attrs.get('class').trim());
#end
        }

        if (paramChildArray != null) {
            for (child in paramChildArray) {
                if (Type.getClass(child) == String) {
                    // Add a string as a TextNode
                    childArray.push({
                        id:nodeCounter++,
                        tag:VirtualElementTools.TEXT_TAG,
                        children: [],
                        textValue: child
                    });
                } else {
                    childArray.push(child);
                }
            }
        }

        return {
            id:nodeCounter++,
            tag:tagName,
            isVoid:tagName.isVoidTag(),
            attrs:attrs,
            children:childArray
        };
    }

    /*
     * update will bring the `current` to parity with `next` and append all the necessary changes to `pendingChanges`.
     * Finally, it will return the new `current`
    */
    public function update(nextState:Array<VirtualElement>, currentState:Array<VirtualElement>, ?parentId:Int):Array<ElementUpdate> {
        // TODO: implement a keying algorithm for efficient reordering
        var updates:Array<ElementUpdate> = [];
        var currentStateItems = currentState.length;
        var nextStateItems = nextState.length;

        inline function place(func, upd) {
#if plugin-support
            updates.push(upd);
#else
            func(upd);
#end
        }

        for (index in 0...(if (currentStateItems > nextStateItems) currentStateItems else nextStateItems)) {
            var next = if (index < nextStateItems) nextState[index] else null;
            var current = if (index < currentStateItems) currentState[index] else null;

            if (current == null) {
                // If there is nothing to compare, just create it.
                place(addElement, {
                    action:AddElement,
                    elementId:next.id,
                    tag:next.tag,
                    attrs:next.attrs,
                    textValue:next.textValue,
                    newParent:parentId,
                    newIndex:index
                });

            } else if (next == null) {
                // If there is nothing there, just remove it.
                place(removeElement, {
                    action:RemoveElement,
                    elementId:current.id
                });
                continue;
            } else if (next.tag != current.tag || next.textValue != current.textValue) {
                // Remove the old element
                place(removeElement, {
                    action:RemoveElement,
                    elementId:current.id
                });
                // Update the new element
                place(addElement, {
                    action:AddElement,
                    elementId:next.id,
                    tag:next.tag,
                    attrs:next.attrs,
                    textValue:next.textValue,
                    newParent:parentId,
                    newIndex:index
                });
            } else if (next.tag != VirtualElementTools.TEXT_TAG) {
                var attrDiff = new VirtualElementAttributes();
                var attrsAreEqual = true;

                for (key in current.attrs.keys()) {
                    var val;
                    if (next.attrs.exists(key)) {
                        val = next.attrs.get(key);
                    } else {
                        val = null;
                        attrsAreEqual = false;
                    }
                    attrDiff.set(key, val);
                }

                for (key in next.attrs.keys()) {
                    if (!attrDiff.exists(key)) {
                        attrDiff.set(key, next.attrs.get(key));
                        attrsAreEqual = false;
                    }
                }

                if (!attrsAreEqual) {
                    // Update the current element
                    place(updateElement, {
                        action:UpdateElement,
                        elementId:current.id,
                        attrs:attrDiff
                    });
                }
                next.id = current.id;
            } else {
                next.id = current.id;
            }

#if plugin-support
            updates = updates.concat(
                update(
                    if (next == null) [] else next.children,
                    if (current == null) [] else current.children,
                    next.id
                )
            );
#else
            update(
                if (next == null) [] else next.children,
                if (current == null) [] else current.children,
                next.id
            );
#end
        }

        return updates;
    }

    @:keep
    public function view():Array<VirtualElement> {
        return [{
            id:nodeCounter++,
            tag:VirtualElementTools.TEXT_TAG,
            children: [],
            textValue:Type.getClassName(cast this) + ' does have have a view() method.'
        }];
    }

    public function render() {
        var nextState = view();
#if plugin-support
        consumeUpdates(update(nextState, currentState));
#else
        update(nextState, currentState);
#end
        currentState = nextState;
    }

    public static function apply(vm:Lens, ?root:ElementType) {
        if (root != null) {
            vm.root = root;
        }
        vm.render();
    }

    public static function setAttributes(element:ElementType, attrs:VirtualElementAttributes):Void {
        // TODO: Consider denormalizing element.tagName to avoid a DOM call.
        for (attrName in attrs.keys()) {
            var value = attrs.get(attrName);
            // TODO - potential speed optimization. elementPropertiesAttributes might do better broken out to separate conditions
            if (Reflect.hasField(element, attrName) && !elementPropertyAttributes.match(attrName)) {
                if (element.tagName != "input" || Reflect.field(element, attrName) != value) {
                    Reflect.setField(element, attrName, value);
                }
            } else {
                if (value == null) {
                    element.removeAttribute(attrName);
                } else {
                    element.setAttribute(attrName, value);
                }
            }
        }
    }

    function injectElement(element:ElementType, parent:ElementType, index:Int) {
#if js
        var nextSibling = parent.childNodes[index];
        if (nextSibling != null) {
            parent.insertBefore(element, nextSibling);
        } else {
            parent.appendChild(element);
        }
#end
    }

    inline function addElement(update:ElementUpdate) {
#if js
        var element:ElementType;
        var parent:ElementType;

        if (update.tag == '#text') {
            element = cast js.Browser.document.createTextNode(update.textValue);
        } else {
            element = cast js.Browser.document.createElement(update.tag);
            setAttributes(cast element, update.attrs);
        }
        elementCache.set(update.elementId, cast element);

        if (update.newParent == null) {
            parent = root;
        } else {
            parent = elementCache.get(update.newParent);
        }
        injectElement(element, parent, update.newIndex);
#end
    }

    inline function updateElement(update:ElementUpdate) {
#if js
        setAttributes(cast elementCache.get(update.elementId), update.attrs);
#end
    }

    inline function removeElement(update:ElementUpdate) {
#if js
        var element = elementCache.get(update.elementId);
        element.parentNode.removeChild(element);
        elementCache.remove(update.elementId);
#end
    }

    inline function moveElement(update:ElementUpdate) {
#if js
        injectElement(
            elementCache.get(update.elementId),
            elementCache.get(update.newParent),
            update.newIndex);
#end
    }

    public function consumeUpdates(updates:Array<ElementUpdate>) {
        while (updates.length > 0) {
            var elementUpdate = updates.shift();
            switch(elementUpdate.action) {
                case AddElement: addElement(elementUpdate);
                case UpdateElement: updateElement(elementUpdate);
                case RemoveElement: removeElement(elementUpdate);
                case MoveElement: moveElement(elementUpdate);
            }
        }
    }
}
