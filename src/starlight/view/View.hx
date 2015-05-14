package starlight.view;

import starlight.view.VirtualElement.VirtualElementChildren;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.VirtualElement.VirtualElement;
import starlight.core.Types.UnsafeMap;
import starlight.core.Types.IntMap;
import starlight.core.Types.ElementType;
import starlight.core.Exceptions.AbstractionException;

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

typedef PropertySetter<T> = T->T;

@:autoBuild(starlight.view.macro.ViewBuilder.build())
class View {
    static var elementPropertyAttributes = ['list', 'style', 'form', 'type', 'width', 'height'];
    static var nodeCounter = 0;

    var e = VirtualElementTools.element;  //  A shortcut for easy access in the `view` method.
    var root:ElementType;
    var postProcessing = new UnsafeMap();
    public var elementCache = new IntMap();
    public var currentState = new Array<VirtualElement>();

    public function new() {
#if js
        this.root = js.Browser.document.body;
#end
    };

#if js
    function setValue<T>(prop:PropertySetter<T>) {
        // Mithril has m.withAttr(field, prop).  I'll change this when I find a use-case for updating anything other than value.
        return function(evt:js.html.KeyboardEvent) {
            var el:js.html.InputElement = cast evt.target;
            prop(cast el.value);
        }
    }
#end

    private function _buildClassString(obj:UnsafeMap):String {
        var classes:Array<String> = [];
#if js
        var keys:Array<String> = untyped __js__("Object").keys(obj);
        for (key in keys)
            if (obj[key] == true)
                classes.push(key);
#else
        classes = [for (key in obj.keys()) if (obj.get(key) == true) key];
#end

        return classes.join(' ');
    }

    /*
     * update will bring the `current` to parity with `next` and append all the necessary changes to `pendingChanges`.
     * Finally, it will return the new `current`
    */
    @:allow(starlight.view.test)
    function update(nextState:Array<VirtualElement>, currentState:Array<VirtualElement>, ?parentId:Int):Array<ElementUpdate> {
        // TODO: implement a keying algorithm for efficient reordering
        var updates:Array<ElementUpdate> = [];
        var currentStateItems = currentState.length;
        var nextStateItems = nextState.length;

        inline function place(func:ElementUpdate->Void, upd:ElementUpdate) {
#if pluginSupport
            updates.push(upd);
#else
            func(upd);
#end
        }

        for (index in 0...(if (currentStateItems > nextStateItems) currentStateItems else nextStateItems)) {
            var next = if (index < nextStateItems) nextState[index] else null;
            var current = if (index < currentStateItems) currentState[index] else null;
            var changingSelectValue = false;
            var currentElementId:Int;

            if (current == null) {
                currentElementId = nodeCounter++;

                place(addElement, {
                    action:AddElement,
                    elementId:currentElementId,
                    tag:next.tag,
                    attrs:next.attrs,
                    textValue:next.textValue,
                    newParent:parentId,
                    newIndex:index
                });

                changingSelectValue = next.tag == 'select' && next.attrs.exists('value');

            } else if (next == null) {
                // If there is nothing there, just remove it.
                place(removeElement, {
                    action:RemoveElement,
                    elementId:current.id
                });
                continue;
            } else if (next.tag != current.tag || next.textValue != current.textValue) {
                currentElementId = nodeCounter++;

                place(removeElement, {
                    action:RemoveElement,
                    elementId:current.id
                });
                place(addElement, {
                    action:AddElement,
                    elementId:currentElementId,
                    tag:next.tag,
                    attrs:next.attrs,
                    textValue:next.textValue,
                    newParent:parentId,
                    newIndex:index
                });

                changingSelectValue = next.tag == 'select' && next.attrs.exists('value');

            } else if (!next.isText()) {
                var attrDiff = new VirtualElementAttributes();
                var attrsAreEqual = true;

                for (key in VirtualElementTools.keys(current.attrs)) {
                    var val;
                    if (next.attrs.exists(key)) {
                        val = next.attrs.get(key);
                        attrsAreEqual = attrsAreEqual && val == current.attrs.get(key);
                    } else {
                        val = null;
                        attrsAreEqual = false;
                    }
                    attrDiff.set(key, val);
                }

                for (key in VirtualElementTools.keys(next.attrs)) {
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
                currentElementId = current.id;
            } else {
                currentElementId = current.id;
            }
            next.id = currentElementId;

#if pluginSupport
            updates = updates.concat(
#end
                update(
                    if (next == null || next.children == null) [] else next.children,
                    if (current == null || current.children == null) [] else current.children,
                    currentElementId
                )
#if pluginSupport
            );
#else
            ;
#end

            if (changingSelectValue) {
                var attrs = new VirtualElementAttributes();
                attrs.set('value', next.attrs.get('value'));
                place(updateElement, {
                    action:UpdateElement,
                    elementId:currentElementId,
                    attrs:attrs
                });
            }
        }

        return updates;
    }

    function view():Array<VirtualElement> {
        throw new AbstractionException('Override View.view().');
    }

    public function render() {
        var nextState = view();
#if pluginSupport
        consumeUpdates(update(nextState, currentState));
#else
        update(nextState, currentState);
#end
        currentState = nextState;
    }

    public static function apply(vm:View, ?root:ElementType) {
        if (root != null) {
            vm.root = root;
        }
        vm.render();
    }

    function setAttributes(element:ElementType, attrs:VirtualElementAttributes, id:Int):Void {
        // TODO: Consider denormalizing element.tagName to avoid a DOM call.
        for (attrName in VirtualElementTools.keys(attrs)) {
            var value = attrs.get(attrName);
            // TODO - potential speed optimization. elementPropertiesAttributes might do better broken out to separate conditions
            // FIXME - Normally we would use Reflect but it doesn't compile correctly such that firefox would work.
            if (untyped __js__("attrName in element") && elementPropertyAttributes.indexOf(attrName) == -1) {
                if (element.tagName != "input" || untyped __js__("element[attrName]") != value) {
                    var field = untyped __js__("element[attrName]");
                    if (untyped __js__("typeof field") == 'function' && attrName.indexOf("on") != 0) {
                        postProcessing.set(attrName, id);
                    } else {
                        untyped __js__("element[attrName] = value");
                    }
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

        if (update.isText()) {
            element = cast js.Browser.document.createTextNode(update.textValue);
        } else {
            element = cast js.Browser.document.createElement(update.tag);
            setAttributes(cast element, update.attrs, update.elementId);
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
        setAttributes(cast elementCache.get(update.elementId), update.attrs, update.elementId);
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

    @:allow(starlight.view.test)
    function consumeUpdates(updates:Array<ElementUpdate>) {
#if debugRendering
            trace('Starting update set.');
#end
        while (updates.length > 0) {
            var elementUpdate = updates.shift();
#if debugRendering
            trace(elementUpdate);
#end
            switch(elementUpdate.action) {
                case AddElement: addElement(elementUpdate);
                case UpdateElement: updateElement(elementUpdate);
                case RemoveElement: removeElement(elementUpdate);
                case MoveElement: moveElement(elementUpdate);
            }
        }

        for (method in VirtualElementTools.keys(postProcessing)) {
            var id = postProcessing.get(method);
#if debugRendering
            trace('postProcess calling $method on $id');
#end
            var el = elementCache.get(id);
            untyped __js__("el")[method]();
            postProcessing.remove(method);
        }

#if debugRendering
            trace('Finished update set.');
#end
    }
}
