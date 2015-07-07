package starlight.router;

import msignal.Signal;

#if js
import js.Browser.window;
#else
typedef MockDOMWindow = {
    onhashchange: Void->Void,
    location: {
        hash: String
    }
}
#end

@:allow(starlight.test.router)
class HistoryManager {
    var isActive:Bool = false;
    var currentHash:String = '';
#if (!js)
    public var window:MockDOMWindow = {
        onhashchange: null,
        location: {
            hash: '#hash'
        }
    };
#end

    public var onHashUpdate(default, null) = new Signal2<String, String>();

    public function new(?defaultHandler:String->String->Void) {
        if (defaultHandler != null) {
            onHashUpdate.add(defaultHandler);
        }
    }

    public function init(?firstHash:String) {
        if (isActive) {
            return;
        }

        window.onhashchange = checkHistory;

        isActive = true;

        if (firstHash != null) {
            registerChange(firstHash);
        } else {
            currentHash = getWindowHash();
        }
    }

    function checkHistory() {
        var newHash = getWindowHash();
        if (newHash != currentHash) {
            registerChange(newHash);
        }
    }

    function registerChange(newHash) {
        var oldHash = currentHash;
        currentHash = newHash;
        onHashUpdate.dispatch(trimHash(newHash), trimHash(oldHash));
    }

    // This would normally be static but connecting it to the class enables testing.
    function getWindowHash() {
        var hash:String = StringTools.urlDecode(window.location.hash);
        return if (hash.charAt(0) == '#') (untyped hash).substr(1, hash.length) else hash;
    }

    static inline function trimHash(hash:String) {
        return if (hash.charAt(0) == '/') (untyped hash).substr(1, hash.length) else hash;
    }
}
