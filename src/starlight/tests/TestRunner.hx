package starlight.tests;

class TestRunner {

    static function main(){
        var r = new haxe.unit.TestRunner();
        r.add(new starlight.lens.tests.TestVirtualElement());
        r.add(new starlight.lens.tests.TestLens());

        r.run();
    }
}
