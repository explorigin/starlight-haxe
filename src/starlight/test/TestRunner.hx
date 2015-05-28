package starlight.test;

class TestRunner {
#if js
    static function getCodeElement():Dynamic {
        var document = js.Browser.document;
        return (untyped document.querySelectorAll('code'))[1];
    }
#end

    static function runTests() {
#if js
        js.Browser.document.querySelector('#notice').style.display = "None";
#end

#if (!neko)
        var logger = mcover.coverage.MCoverage.getLogger();
#end

        var r = new haxe.unit.TestRunner();

        r.add(new starlight.test.router.TestHistoryManager());
        r.add(new starlight.test.view.TestVirtualElementTools());
        r.add(new starlight.test.view.TestVirtualElementTools.TestElementCreation());
        r.add(new starlight.test.view.TestView.TestViewUpdate());
        r.add(new starlight.test.view.TestView.TestViewConsumeUpdates());
        r.add(new starlight.test.view.TestView.TestViewHelperFunctions());

        r.run();

#if js
        var el = getCodeElement();
        var testResults = el.innerHTML;
        el.innerHTML = '';
        trace(testResults);
#end

#if (!neko)
        logger.report();
#end

#if js
        var coverageResults = el.innerText;
        el.innerHTML = coverageResults;
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
