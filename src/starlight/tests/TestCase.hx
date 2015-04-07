package starlight.tests;

import haxe.PosInfos;

class TestCase extends haxe.unit.TestCase {
    function assertContains(arr:Array<Dynamic>, item:Dynamic, ?c : PosInfos ) {
        currentTest.done = true;
        if (arr.indexOf(item) == -1){
            currentTest.success = false;
            currentTest.error   = 'expected $arr to contain "$item".';
            currentTest.posInfos = c;
            throw currentTest;
        }
    }

    override function assertTrue( b:Bool, ?c : PosInfos ) : Void {
        return assertEquals(true, b, c);
    }

    override function assertFalse( b:Bool, ?c : PosInfos ) : Void {
        return assertEquals(false, b, c);
    }

}
