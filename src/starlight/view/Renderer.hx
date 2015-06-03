package starlight.view;

import starlight.view.VirtualElement;
import starlight.view.VirtualElement.VirtualElementChildren;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.VirtualElementTools;
import starlight.view.Component;
import starlight.view.Component.ElementUpdate;
import starlight.core.Types.UnsafeMap;
import starlight.core.Types.IntMap;
import starlight.core.Types.ElementType;
import starlight.core.FunctionTools;

using VirtualElementTools.VirtualElementTools;

typedef PseudoEvent = {
    id: Int,
    type: String,
    which: Int,
    target: {
        value: String,
        checked: Bool
    }
};

#if js

@:allow(starlight.test.view)
class Renderer {
    static var elementPropertyAttributes = ['list', 'style', 'form', 'type', 'width', 'height'];

    var rootComponent:Component;
    var rootElement:ElementType;
    var postProcessing = new UnsafeMap();
    var elementCache = new IntMap();
    var updateSets = new Array<Array<ElementUpdate> >();

    public function new() {};

    public function start(mainComponent:Component, root:ElementType) {
        rootElement = root;
        rootComponent = mainComponent;

        rootComponent.updatesAvailable.add(captureUpdates);  // FIXME - ensure idempotency

        rootComponent.checkState();
    }

    function captureUpdates(updates: Array<ElementUpdate>) {
        updateSets.push(updates);
        FunctionTools.debounce(render);
    }

    function render() {
        if (updateSets.length == 0) {
            return;
        }

        consumeUpdates(updateSets.pop());
    }

    function buildEventHandler(eventId:Int) {
        return function(evt:Dynamic) {
            evt.stopPropagation();

            var dataObject:PseudoEvent = {
                id: eventId,
                type: evt.type,
                which: evt.which,
                target: {
                    value: evt.target.value,
                    checked: evt.target.checked
                }
            }

            rootComponent.triggerEvent(dataObject);
        }
    }


    function setAttributes(element:ElementType, attrs:VirtualElementAttributes, id:Int):Void {
        // TODO: Consider denormalizing element.tagName to avoid a DOM call.
        for (attrName in attrs.keys()) {
            var value = attrs.get(attrName);
            // TODO - potential speed optimization. elementPropertiesAttributes might do better broken out to separate conditions
            // FIXME - Normally we would use Reflect but it doesn't compile correctly such that firefox would work.
            if (untyped __js__("attrName in element") && elementPropertyAttributes.indexOf(attrName) == -1) {
                if (element.tagName != "input" || untyped __js__("element[attrName]") != value) {
                    var field = untyped __js__("element[attrName]");
                    if (attrName.indexOf("on") == 0) {
                        (untyped element)[cast attrName] = buildEventHandler(value);
                    } else if (untyped __js__("typeof field") == 'function') {
                        postProcessing.set(attrName, id);
                    } else {
                        (untyped element)[cast attrName] = value;
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
        var nextSibling = parent.childNodes[index];
        if (nextSibling != null) {
            parent.insertBefore(element, nextSibling);
        } else {
            parent.appendChild(element);
        }
    }

    inline function addElement(update:ElementUpdate) {
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
            parent = rootElement;
        } else {
            parent = elementCache.get(update.newParent);
        }
        injectElement(element, parent, update.newIndex);
    }

    inline function updateElement(update:ElementUpdate) {
        setAttributes(cast elementCache.get(update.elementId), update.attrs, update.elementId);
    }

    inline function removeElement(update:ElementUpdate) {
        var element = elementCache.get(update.elementId);
        element.parentNode.removeChild(element);
        elementCache.remove(update.elementId);
    }

    inline function moveElement(update:ElementUpdate) {
        injectElement(
            elementCache.get(update.elementId),
            elementCache.get(update.newParent),
            update.newIndex);
    }

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

        for (method in postProcessing.keys()) {
            var id = postProcessing.get(method);

            #if debugRendering
                trace('postProcess calling $method on $id');
            #end

            (untyped elementCache.get(id))[untyped method]();
            postProcessing.remove(method);
        }

        #if debugRendering
            trace('Finished update set.');
        #end
    }
}

#end
