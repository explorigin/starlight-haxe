package starlight.router;

import js.Browser.window;
import msignal.Signal;
import starlight.core.StringTools;

class HistoryManager {
    var isActive:Bool = false;
    var currentHash:String = '';

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

    static function getWindowHash() {
        var hash:String = StringTools.urlDecode(window.location.hash);
        return if (hash.charAt(0) == '#') StringTools.substr(hash, 1, hash.length) else hash;
    }

    static inline function trimHash(hash:String) {
        return if (hash.charAt(0) == '/') StringTools.substr(hash, 1, hash.length) else hash;
    }
}
