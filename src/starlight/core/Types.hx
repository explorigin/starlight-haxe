package starlight.core;

/*
 * UnsafeMap is a more-efficient StringMap for the Javascript platform at the
 * expense of not being able to handle some some reserved words as keys.
 * Aside from Javascript, it is a normal StringMap.trace
 */

#if js
typedef UnsafeMap = haxe.DynamicAccess<Dynamic>;
#else
typedef UnsafeMap = haxe.ds.StringMap<Dynamic>;
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
