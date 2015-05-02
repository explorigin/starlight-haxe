package starlight.router;

import js.Browser.window;
import promhx.Stream;
import promhx.Deferred;

using StringTools;

typedef HashUpdateEvent = String;

class HistoryManager {
    var isActive:Bool = false;
    var currentHash:String = '';

    var triggerHashUpdate:Deferred<HashUpdateEvent>;
    public var onHashUpdate(default, null):Stream<HashUpdateEvent>;

    public function new(?defaultHandler:HashUpdateEvent->Void) {
        triggerHashUpdate = new Deferred<HashUpdateEvent>();
        onHashUpdate = triggerHashUpdate.stream();

        if (defaultHandler != null) {
            onHashUpdate.then(defaultHandler);
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
        triggerHashUpdate.resolve(trimHash(newHash)); // FIXME - add the oldHash
    }

    static function getWindowHash() {
        var hash = window.location.hash.urlDecode();
        if (hash.charAt(0) == '#') {
            hash = hash.substr(1);
        }
        return hash;
    }

    static function trimHash(hash:String) {
        if (hash.charAt(0) == '/') {
            hash = hash.substr(1);
        }
        return hash;
    }
}
