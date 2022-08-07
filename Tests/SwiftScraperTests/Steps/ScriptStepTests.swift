@testable import SwiftScraper
import XCTest

class ScriptStepTests: StepRunnerCommonTests {

    private let doNotExecuteStep = ProcessStep { _ in
        XCTFail("This step should not run")
        return .proceed
    }

    func testScriptStep() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "Hello world!")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), .success])
    }

    func testScriptStepCanReturnDifferentTypes() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "getString") { response, _ in
            XCTAssertEqual(response as? String, "hello world")
            return .proceed
        }

        let step3 = ScriptStep(functionName: "getBooleanTrue") { response, _ in
            XCTAssertEqual(response as? Bool, true)
            return .proceed
        }

        let step4 = ScriptStep(functionName: "getBooleanFalse") { response, _ in
            XCTAssertEqual(response as? Bool, false)
            return .proceed
        }

        let step5 = ScriptStep(functionName: "getNumber") { response, _ in
            XCTAssertEqual(response as? Double, 3.45)
            return .proceed
        }

        let step6 = ScriptStep(functionName: "getJsonObject") { response, _ in
            let json = response as? JSON
            XCTAssertEqual(json?["message"] as? String, "something")
            return .proceed
        }

        let step7 = ScriptStep(functionName: "getJsonArray") { response, _ in
            let jsonArray = response as? [JSON]
            XCTAssertEqual(jsonArray?[0]["fruit"] as? String, "apple")
            XCTAssertEqual(jsonArray?[1]["fruit"] as? String, "pear")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3, step4, step5, step6, step7])
        stepRunner.run()
        waitForExpectations()
    }

    func testScriptStepWithMultipleArgumentsCanBeEchoedBack() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(
            functionName: "multiArg",
            params: 987.6,
            true,
            "lorem",
            [1, 2, 3],
            ["foo": "bar"]) { response, _ in
                let json = response as? JSON
                self.assertModel(json!)
                exp.fulfill()
                return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()
    }

    func testScriptStepUpdatesModel() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "getInnerText", params: "h1") { response, model in
            let responseString = response as? String
            XCTAssertEqual(responseString, "Hello world!")
            model["step2"] = responseString // model is updated here
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), .success])
        XCTAssertEqual(stepRunner.model["step2"] as? String, "Hello world!")
    }

    func testScriptStepTakesParamsFromModel() throws {
        let exp = expectation(description: #function)

        // model is updated here
        let step2 = ProcessStep { model in
            model["text"] = "hello world"
            model["number"] = 987.6
            model["obj"] = ["foo": "bar"]
            return .proceed
        }

        // parameters for step 3 comes from the model
        let step3 = ScriptStep(
            functionName: "testParamsFromModel",
            paramsKeys: ["text", "number", "doesntExistShouldBeNull", "obj"]) { response, _ in
            XCTAssertEqual(response as? Bool,
                           true,
                           "JavaScript failed assertion when checking the parameters passed from the model")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()
    }

    func testScriptStepFailed() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "foobarThisWillFail") { _, _ in
            XCTFail("Should not call handler if script fails")
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), TestHelper.failureResult])
        if case .failure(let errorObject) = stepRunner.state, let error = errorObject as? SwiftScraperError {
            if case .javascriptError(let errorMessage) = error {
                XCTAssert(errorMessage.contains("TypeError: StepRunnerTests.foobarThisWillFail is not a function."))
            } else {
                XCTFail("error should javascriptError, but is \(error)")
            }
        } else {
            XCTFail("state should be failure, but was \(stepRunner.state)")
        }
    }

    func testScriptStepFailEarly() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "getString") { _, model in
                model["step2"] = 123
                let error = NSError(domain: "StepRunnerTests", code: 12_345, userInfo: nil)
                exp.fulfill()
                return .failure(error) // fail early
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), TestHelper.failureResult])
        if case .failure(let error) = stepRunner.state {
            // assert that error is correct
            XCTAssertEqual((error as NSError).domain, "StepRunnerTests")
            XCTAssertEqual((error as NSError).code, 12_345)

            // assert that model is correct
            XCTAssertEqual(stepRunner.model["step2"] as? Int, 123)
        } else {
            XCTFail("state should be failure, but was \(stepRunner.state)")
        }
    }

}
