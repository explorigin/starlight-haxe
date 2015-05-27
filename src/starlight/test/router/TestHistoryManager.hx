package starlight.test.router;

import starlight.router.HistoryManager;

class TestHistoryManager extends haxe.unit.TestCase {
    function setHash(mgr:HistoryManager, hash:String) {
#if js
        untyped __js__("window.location.hash = hash");
#else
        mgr.window.location.hash = hash;
#end
    }

#if js
    override function tearDown() {
        untyped __js__("window.location.hash = ''");
    }
#end

    public function testCheckHistoryInitPullsCurrentHash() {
        var called = false,
            handler = function (newHash, oldHash) {
                assertEquals('new', newHash);
                assertEquals('old', oldHash);
                called = true;
            },
            h = new HistoryManager(handler);

        setHash(h, 'old');
        h.init();
        assertTrue(h.isActive);
        assertEquals('old', h.currentHash);
        assertFalse(called);
    }

    public function testCheckHistoryInitFiresWhenSentInitialHash() {
        var called = false,
            handler = function (newHash, oldHash) {
                called = true;
            },
            h = new HistoryManager(handler);

        setHash(h, 'old');
        h.init('new');
        assertTrue(h.isActive);
        assertEquals('new', h.currentHash);
        assertTrue(called);

        called = false;
        h.init('new');

        assertFalse(called);
    }

    public function testGetWindowHash() {
        var h = new HistoryManager();
        setHash(h, '#testHash');
        assertEquals(h.getWindowHash(), 'testHash');

        setHash(h, 'testHash');
        assertEquals(h.getWindowHash(), 'testHash');

        setHash(h, '');
        assertEquals(h.getWindowHash(), '');
    }

    public function testRegisterChange() {
        var called = false,
            handler = function (newHash, oldHash) {
                assertEquals('new', newHash);
                assertEquals('old', oldHash);
                called = true;
            },
            h = new HistoryManager(handler);

        h.currentHash = 'old';
        h.registerChange('/new');
        assertTrue(called);
    }

    public function testCheckHistoryOnChange() {
        var called = false,
            handler = function (newHash, oldHash) {
                assertEquals('new', newHash);
                assertEquals('old', oldHash);
                called = true;
            },
            h = new HistoryManager(handler);

        h.currentHash = 'old';
        setHash(h, 'new');
        h.checkHistory();
        assertTrue(called);
    }

    public function testCheckHistoryOnNoChange() {
        var called = false,
            handler = function (newHash, oldHash) {
                assertEquals('new', newHash);
                assertEquals('old', oldHash);
                called = true;
            },
            h = new HistoryManager(handler);

        h.currentHash = 'old';
        setHash(h, 'old');
        h.checkHistory();
        assertFalse(called);
    }
}

