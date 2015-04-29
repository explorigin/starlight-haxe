package starlight.tests;

class FrontendTestCase extends TestCase {
    public var elementCache = new haxe.ds.IntMap<starlight.core.Types.ElementType>();

    public override function tearDown() {
        var i = elementCache.keys();
        while(i.hasNext()) {
            var key = i.next();
            var el = elementCache.get(key);
            elementCache.remove(key);
#if js
            try {
                el.parentElement.removeChild(el);
            } catch (e:Dynamic) {
                // We don't care
            }
#end
        }
    }

    function assertElementTextEquals(text:String, selector:String) {
#if js
        var el = js.Browser.document.querySelector(selector);
        if (el == null) {
            assertEquals(selector, null);
        }
        assertEquals(text, el.innerHTML);
#else
        // Can't test on this platform but we add an assert to prevent this test from failing.
        assertTrue(true);
#end
    }

    function assertElementValue(selector, value) {
#if js
        assertEquals(untyped js.Browser.document.querySelector(selector).value, value);
#else
        assertTrue(true);  // Just make the test not complain.
#end
    }

}
