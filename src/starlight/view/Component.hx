package starlight.view;

import msignal.Signal;

import starlight.view.VirtualElement;
import starlight.view.Renderer.PseudoEvent;
import starlight.view.VirtualElement.VirtualElementAttributes;
import starlight.view.VirtualElementTools;
import starlight.core.Types.UnsafeMap;
import starlight.core.Types.IntMap;
import starlight.core.Exceptions.AbstractionException;
import starlight.core.FunctionTools;

using VirtualElementTools.VirtualElementTools;

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

@:allow(starlight.test.view)
@:autoBuild(starlight.view.macro.PropertyBuilder.build())
class Component {
    static var elementPropertyAttributes = ['list', 'style', 'form', 'type', 'width', 'height'];
    static var nodeCounter = 0;
    static var eventCounter = 0;

    var events = new IntMap();
    var existingEventMap = new IntMap();
    public var elementCache = new IntMap();
    public var currentState = new Array<VirtualElement>();
    public var updatesAvailable(default, null) = new Signal1<Array<ElementUpdate> >();

    public function new() {};

    public function checkState() {
        var nextState = template();
        var updates = update(nextState, currentState);
        if (updates.length != 0) {
            updatesAvailable.dispatch(updates);
            currentState = nextState;
        }
    }

    @:keep
    public function triggerEvent(evt:PseudoEvent) {
        var eventHandler = events.get(evt.id);

        if (eventHandler != null) {
            #if debugRendering
                var elementId:Int;

                for (eventElementId in existingEventMap.keys()) {
                    var elementEventMap:UnsafeMap = existingEventMap.get(eventElementId);
                    for (eventName in elementEventMap.keys()) {
                        if (elementEventMap.get(eventName) == evt.id) {
                            elementId = eventElementId;
                            break;
                        }
                    }
                    if (elementId != null) {
                        break;
                    }
                }
                trace('${evt.type} event triggered on $elementId: $evt');
            #end

            if (eventHandler(evt) != false) {
                FunctionTools.debounce(checkState);
            }
        }
    }

    static function buildClassString(obj:UnsafeMap):String {
#if js
        return [for (key in ((untyped Object).keys(obj):Array<String>)) if (cast obj.get(key)) key].join(' ');
#else
        return [for (key in obj.keys()) if (obj.get(key) == true) key].join(' ');
#end
    }

#if js
    static function buildChildren(result:Dynamic):Array<VirtualElement> {
        // Calls to this function are automatically inserted with the view builder macro.
        // In some cases, it is impossible to know at compile-type what some template values
        // are.  In these cases, we punt to runtime.
        return if (untyped __js__('Array').isArray(result)) result else [{tag: VirtualElementTools.TEXT_TAG, textValue: untyped result}];
    }
#end

    private function setValue<T>(prop:PropertySetter<T>) {
        // Mithril has m.withAttr(field, prop).  I'll change this when I find a use-case for updating anything other than value.
        return function(evt:{target: {value: T}}):Void {
            prop(evt.target.value);
        };
    }

    private function replaceEventHandlers(attrs:VirtualElementAttributes, elementId:Int) {
        for (key in attrs.keys()) {
            if (key.indexOf('on') == 0) {
                if (!existingEventMap.exists(elementId)) {
                    existingEventMap.set(elementId, new UnsafeMap());
                }
                var elementRecord:UnsafeMap = existingEventMap.get(elementId);
                var eventId:Int = elementRecord.get(key);
                if (eventId == null) {
                    eventId = eventCounter++;
                    elementRecord.set(key, eventId);
                    events.set(eventId, attrs.get(cast key));
                }
                attrs.set(cast key, eventId);
            }
        }

        return attrs;
    }

    private function removeEventHandlers(elementId:Int) {
        var elementRecord:UnsafeMap = existingEventMap.get(elementId);
        if (elementRecord == null) {
            return;
        }

        for (eventName in elementRecord.keys()) {
            events.remove(elementRecord.get(eventName));
        }
        existingEventMap.remove(elementId);
    }

    /*
     * update compares `currentState` to `nextState` and returns an array of necessary changes.
    */
    function update(nextState:Array<VirtualElement>, currentState:Array<VirtualElement>, ?parentId:Int):Array<ElementUpdate> {
        // TODO: implement a keying algorithm for efficient reordering
        var updates:Array<ElementUpdate> = [];
        var currentStateItems = currentState.length;
        var nextStateItems = nextState.length;

        for (index in 0...(if (currentStateItems > nextStateItems) currentStateItems else nextStateItems)) {
            var next = if (index < nextStateItems) nextState[index] else null;
            var current = if (index < currentStateItems) currentState[index] else null;
            var changingSelectValue = false;
            var currentElementId:Int;

            if (current == null) {
                currentElementId = nodeCounter++;

                updates.push({
                    action:AddElement,
                    elementId:currentElementId,
                    tag:next.tag,
                    attrs:if (next.attrs != null) replaceEventHandlers(next.attrs, currentElementId) else cast {},
                    textValue:next.textValue,
                    newParent:parentId,
                    newIndex:index
                });

                changingSelectValue = next.tag == 'select' && next.attrs.exists('value');

            } else if (next == null) {
                // If there is nothing there, just remove it.
                updates.push({
                    action:RemoveElement,
                    elementId:current.id
                });
                removeEventHandlers(current.id);
                continue;
            } else if (next.tag != current.tag) {
                currentElementId = nodeCounter++;

                updates.push({
                    action:RemoveElement,
                    elementId:current.id
                });
                removeEventHandlers(current.id);

                updates.push({
                    action:AddElement,
                    elementId:currentElementId,
                    tag:next.tag,
                    attrs:if (next.attrs != null) replaceEventHandlers(next.attrs, currentElementId) else cast {},
                    textValue:next.textValue,
                    newParent:parentId,
                    newIndex:index
                });

                changingSelectValue = next.tag == 'select' && next.attrs.exists('value');

            } else if (next.textValue != current.textValue) {
                updates.push({
                    action:UpdateElement,
                    elementId:current.id,
                    attrs:cast {textContent: next.textValue}
                });

                currentElementId = current.id;
            } else if (!next.isText()) {
                var attrDiff = new VirtualElementAttributes();
                var normalizedNextAttributes = replaceEventHandlers(next.attrs, current.id);
                var attrsAreEqual = true;

                for (key in current.attrs.keys()) {
                    var val;
                    if (normalizedNextAttributes.exists(key)) {
                        val = normalizedNextAttributes.get(key);
                        attrsAreEqual = attrsAreEqual && val == current.attrs.get(key);
                    } else {
                        val = null;
                        attrsAreEqual = false;
                    }
                    attrDiff.set(key, val);
                }

                for (key in normalizedNextAttributes.keys()) {
                    if (!attrDiff.exists(key)) {
                        attrDiff.set(key, normalizedNextAttributes.get(key));
                        attrsAreEqual = false;
                    }
                }

                if (!attrsAreEqual) {
                    // Update the current element
                    updates.push({
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

            updates = updates.concat(
                update(
                    if (next == null || next.children == null) [] else next.children,
                    if (current == null || current.children == null) [] else current.children,
                    currentElementId
                )
            );

            if (changingSelectValue) {
                var selectSecondarySet = new VirtualElementAttributes();
                selectSecondarySet.set('value', next.attrs.get('value'));
                updates.push({
                    action:UpdateElement,
                    elementId:currentElementId,
                    attrs: selectSecondarySet
                });
            }
        }

        return updates;
    }

    function template():Array<VirtualElement> {
        throw new AbstractionException('Override View.view().');
    }
}
