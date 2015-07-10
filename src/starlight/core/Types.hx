package starlight.core;

/*
 * UnsafeMap is a more-efficient StringMap for the Javascript platform at the
 * expense of not being able to handle some some reserved words as keys.
 * Aside from Javascript, it is a normal StringMap.trace
 */

#if js
typedef UnsafeMap = DynamicAccess<Dynamic>;
typedef IntMap = DynamicIntAccess<Dynamic>;
#else
typedef UnsafeMap = haxe.ds.StringMap<Dynamic>;
typedef IntMap = haxe.ds.IntMap<Dynamic>;
#end

/*
 * ElementType provides an abstraction that we can work with on multiple build
 * targets.
 */
#if js
    typedef ElementType = js.html.Element;
#else
    typedef ElementType = Dynamic;
#end

/**
    A mirror of haxe.DynamicAccess with more efficient .keys() method
**/
abstract DynamicAccess<T>(Dynamic<T>) from Dynamic<T> to Dynamic<T> {
    public inline function new() this = {};

    @:arrayAccess
    public inline function get(key:String):Null<T> {
        #if js
        return untyped this[key]; // we know it's an object, so we don't need a check
        #else
        return Reflect.field(this, Std.string(key));
        #end
    }

    @:arrayAccess
    public inline function set(key:String, value:T):T {
        #if js
        return untyped this[key] = value;
        #else
        Reflect.setField(this, Std.string(key), value);
        return value;
        #end
    }

    public inline function exists(key:String):Bool return Reflect.hasField(this, Std.string(key));

    public inline function remove(key:String):Bool return Reflect.deleteField(this, Std.string(key));

    public inline function keys():Array<String> {
#if js
        return (untyped Object).keys(this);
#else
        return cast Reflect.fields(this);
#end
    }

  @:from
  static public function fromObject<T>(o:{}):DynamicAccess<T> {
    return cast o;
  }

  @:to
  public function toObject<T>():{} {
    return cast this;
  }
}

/**
    A mirror of haxe.DynamicAccess that work for integers
**/
abstract DynamicIntAccess<T>(Dynamic<T>) from Dynamic<T> to Dynamic<T> {
    public inline function new() this = {};

    @:arrayAccess
    public inline function get(key:Int):Null<T> {
        #if js
        return untyped this[key]; // we know it's an object, so we don't need a check
        #else
        return Reflect.field(this, Std.string(key));
        #end
    }

    @:arrayAccess
    public inline function set(key:Int, value:T):T {
        #if js
        return untyped this[key] = value;
        #else
        Reflect.setField(this, Std.string(key), value);
        return value;
        #end
    }

    public inline function exists(key:Int):Bool return Reflect.hasField(this, Std.string(key));

    public inline function remove(key:Int):Bool return Reflect.deleteField(this, Std.string(key));

    public inline function keys():Array<Int> {
#if js
        return (untyped Object).keys(this).map(Std.parseInt);
#else
        return cast Reflect.fields(this);
#end
    }
}
