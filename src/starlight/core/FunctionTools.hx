package starlight.core;

class FunctionTools {
    public static inline function debounce(fun:Void->Void) {
        // FIXME - This is JS-specific.  Refactor it when splitting apart the view from the renderer.
    #if (js && !unittest)
        if ((untyped fun).timeout) {
            return;
        }
        (untyped fun).timeout = untyped __js__('requestAnimationFrame(function() { delete fun.timeout; fun(); }, 0)');
    #else
        fun();
    #end
    }
}
