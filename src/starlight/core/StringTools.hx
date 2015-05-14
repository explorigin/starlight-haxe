package starlight.core;

import StringTools in HaxeStringTools;

class StringTools {
    public inline static function trim(s:String) {
#if js
        return untyped __js__('String.prototype.trim').call(s);
#else
        return HaxeStringTools.trim(s);
#end
    }

    public inline static function substr(s:String, start:Int, ?length:Int) {
#if js
        return untyped __js__('String.prototype.substr').call(s, start, length);
#else
        return s.substr(start, length);
#end
    }

    public inline static function substring(s:String, start:Int, ?end:Int) {
#if js
        return untyped __js__('String.prototype.substring').call(s, start, end);
#else
        return s.substring(start, end);
#end
    }

    public inline static function charAt(s:String, index:Int) {
#if js
        return untyped __js__('String.prototype.charAt')(s, index);
#else
        return s.charAt(index);
#end
    }

    public inline static function urlDecode(s:String) {
#if js
        return untyped __js__('decodeURIComponent')(s.split("+").join(" "));
#else
        return HaxeStringTools.urlDecode(s);
#end
    }

    public inline static function toTitleCase(s:String) {
        return [for (word in s.split(' ')) word.charAt(0).toUpperCase() + StringTools.substr(word, 1, word.length)].join(' ');
    }
}
