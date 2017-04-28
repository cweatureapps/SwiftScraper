var StepRunnerTests = (function() {
    function assertPage1Title() {
        return document.title == 'Page 1';
    }

    function assertPage2Title() {
        return document.title == 'Page 2';
    }

    function assertWaitTestTitle() {
        return document.title == 'Wait Test';
    }

    function getInnerText(selector) {
        return document.querySelector(selector).innerText;
    }

    function getString() {
        return 'hello world';
    }

    function getBooleanTrue(b) {
        return true;
    }

    function getBooleanFalse(b) {
        return false;
    }

    function getNumber() {
        return 3.45;
    }
    
    function getJsonObject() {
        return {message: 'something'};
    }

    function getJsonArray() {
        return [{ fruit: 'apple' }, { fruit: 'pear' }];
    }

    function multiArg(n, b, s, numArr, obj) {
        return {
            number: n,
            bool: b,
            text: s,
            numArr: numArr,
            obj: obj
        };
    }

    function testParamsFromModel(text, number, nullVariable, obj) {
        return text === "hello world" && number === 987.6 && nullVariable === null && obj["foo"] === "bar";
    }

    function goToPage2() {
        window.location = "page2.html"
    }

    function goToPage2WithParams(fruit, color) {
        window.location = 'page2.html?fruit=' + fruit + '&color=' + color;
    }

    function getStringAsync() {
        setTimeout(function() {
            SwiftScraper.postMessage('thanks for waiting...hello!');
        }, 200);
    }

    function multiArgAsync(n, b, s, numArr, obj) {
        SwiftScraper.postMessage({
            number: n,
            bool: b,
            text: s,
            numArr: numArr,
            obj: obj
        });
    }

    function testWaitForCondition() {
        return document.getElementById('foo').innerText == 'modified';
    }

    return {
        assertPage1Title: assertPage1Title,
        assertPage2Title: assertPage2Title,
        assertWaitTestTitle: assertWaitTestTitle,
        getInnerText: getInnerText,
        getString: getString,
        getBooleanTrue: getBooleanTrue,
        getBooleanFalse: getBooleanFalse,
        getNumber: getNumber,
        getJsonObject: getJsonObject,
        getJsonArray: getJsonArray,
        multiArg: multiArg,
        testParamsFromModel: testParamsFromModel,
        goToPage2: goToPage2,
        goToPage2WithParams: goToPage2WithParams,
        getStringAsync: getStringAsync,
        multiArgAsync: multiArgAsync,
        testWaitForCondition: testWaitForCondition
    };
})();
