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

typedef ComponentAssignment = {
    component: Component,
    root: ElementType
};

typedef UpdateSet = {
    id:Int,
    updates: Array<ElementUpdate>
};

#if js

@:allow(starlight.test.view)
class Renderer {
    static var elementPropertyAttributes = ['list', 'style', 'form', 'type', 'width', 'height'];
    static var assignmentID = 0;

    var componentMap = new IntMap();
    var elementMap = new IntMap();
    var postProcessing = new UnsafeMap();
    var elementCache = new IntMap();
    var updateSets = new Array<UpdateSet>();

    public function new(?assignments:Array<ComponentAssignment>) {
        if (assignments == null) {
            return;
        }
        for (assignment in assignments) {
            registerActiveComponent(assignment.component, assignment.root);
        }
    };

    function registerActiveComponent(c:Component, root:ElementType) {
        var id = assignmentID++;
        componentMap.set(id, c);
        elementMap.set(id, root);
        c.updatesAvailable.add(captureUpdates.bind(id, _));
    }

    public static inline function debounce(fun:Void->Void) {
        #if (js && !unittest)
            if ((untyped fun).timeout) {
                return;
            }
            (untyped fun).timeout = untyped __js__('requestAnimationFrame(function() { delete fun.timeout; fun() })');
        #else
            fun();
        #end
    }

    public function start() {
        for (assignmentId in componentMap.keys()) {
            componentMap.get(assignmentId).checkState();
        }
    }

    function captureUpdates(id:Int, updates: Array<ElementUpdate>) {
        if (updates != null && updates.length > 0) {
            updateSets.unshift({id: id, updates: updates});
            debounce(render);
        }
    }

    function render() {
        if (updateSets.length == 0) {
            return;
        }

        consumeUpdates(updateSets.pop());
    }

    function buildEventHandler(eventId:Int, assignmentId:Int) {
        var component = componentMap.get(assignmentId);

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

            component.triggerEvent(dataObject);
        }
    }

    function setAttributes(element:ElementType, attrs:VirtualElementAttributes, elementId:Int, assignmentId:Int):Void {
        // TODO: Consider denormalizing element.tagName to avoid a DOM call.
        for (attrName in attrs.keys()) {
            var value = attrs.get(attrName);
            // TODO - potential speed optimization. elementPropertiesAttributes might do better broken out to separate conditions
            // FIXME - Normally we would use Reflect but it doesn't compile correctly such that firefox would work.
            if (untyped __js__("attrName in element") && elementPropertyAttributes.indexOf(attrName) == -1) {
                if (element.tagName != "input" || untyped __js__("element[attrName]") != value) {
                    var field = untyped __js__("element[attrName]");
                    if (attrName.indexOf("on") == 0) {
                        (untyped element)[cast attrName] = buildEventHandler(value, assignmentId);
                    } else if (untyped __js__("typeof field") == 'function') {
                        postProcessing.set(attrName, elementId);
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

    inline function addElement(update:ElementUpdate, assignmentId:Int) {
        var element:ElementType;
        var parent:ElementType;

        if (update.isText()) {
            element = cast js.Browser.document.createTextNode(update.textValue);
        } else {
            element = cast js.Browser.document.createElement(update.tag);
            setAttributes(cast element, update.attrs, update.elementId, assignmentId);
        }
        elementCache.set(update.elementId, cast element);

        if (update.newParent == null) {
            parent = elementMap.get(assignmentId);
        } else {
            parent = elementCache.get(update.newParent);
        }

        injectElement(element, parent, update.newIndex);
    }

    inline function updateElement(update:ElementUpdate, assignmentId:Int) {
        setAttributes(cast elementCache.get(update.elementId), update.attrs, update.elementId, assignmentId);
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

    function consumeUpdates(assignment:UpdateSet) {
        #if debugRendering
            trace('Starting update set.');
        #end

        while (assignment.updates.length > 0) {
            var elementUpdate = assignment.updates.shift();

            #if debugRendering
                trace(elementUpdate);
            #end

            switch(js.Symbol.keyFor(elementUpdate.action)) {
                case 'AddElement': addElement(elementUpdate, assignment.id);
                case 'UpdateElement': updateElement(elementUpdate, assignment.id);
                case 'RemoveElement': removeElement(elementUpdate);
                case 'MoveElement': moveElement(elementUpdate);
            }
        }

        for (method in postProcessing.keys()) {
            var elementId = postProcessing.get(method);

            #if debugRendering
                trace('postProcess calling $method on $elementId');
            #end

            (untyped elementCache.get(elementId))[untyped method]();
            postProcessing.remove(method);
        }

        #if debugRendering
            trace('Finished update set.');
        #end
    }
}

#end
