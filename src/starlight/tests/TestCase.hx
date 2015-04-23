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

    function assertHas(m:Map<String, Dynamic>, key:String, ?c : PosInfos ) {
        currentTest.done = true;
        if (!m.exists(key)){
            currentTest.success = false;
            currentTest.error   = 'expected $m to have key "$key".';
            currentTest.posInfos = c;
            throw currentTest;
        }
    }

    function assertNotEquals( a: Dynamic, b:Dynamic, ?c : PosInfos ) : Void {
        currentTest.done = true;
        if (a == b){
            currentTest.success = false;
            currentTest.error   = 'expected $a to not equal $b.';
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
