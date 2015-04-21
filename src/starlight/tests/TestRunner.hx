package starlight.tests;

class TestRunner {
    static function runTests() {
#if js
        js.Browser.document.querySelector('#notice').style.display = "None";
#end

        var r = new haxe.unit.TestRunner();

        r.add(new starlight.lens.tests.TestVirtualElementTools());
        r.add(new starlight.lens.tests.TestLens.TestLensElement());
        r.add(new starlight.lens.tests.TestLens.TestLensUpdate());
        r.add(new starlight.lens.tests.TestLens.TestLensConsumeUpdates());

        r.run();

#if js
        var body = js.Browser.document.body;
        untyped __js__("setTimeout(function() { body.scrollTop = body.scrollHeight; }, 10)");
#end
    }

    static function main(){
#if js
        // Some tests require the DOM so we have to wait.
        js.Browser.document.addEventListener('DOMContentLoaded', runTests, false);
#else
        runTests();
#end
    }
}
