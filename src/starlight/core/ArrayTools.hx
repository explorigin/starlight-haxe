package starlight.core;

class ArrayTools<S> {
    public inline static function mapi<S, T>(a:Array<S>, f:S->?Int->T) {
#if js
        return untyped __js__('Array.prototype.map').call(a, f);
#else
        var out = new Array<T>();
        var i = 0;
        for (e in a) {
            out.push(f(e, i));
            i++;
        }
        return out;
#end
    }
}
