package starlight.tests;

class TestRunner {
    static function runTests() {
        var r = new haxe.unit.TestRunner();

        r.add(new starlight.lens.tests.TestVirtualElement());
        r.add(new starlight.lens.tests.TestLens.TestLensElement());
        r.add(new starlight.lens.tests.TestLens.TestLensUpdate());
        r.add(new starlight.lens.tests.TestLens.TestLensViewModel());

        r.run();
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
