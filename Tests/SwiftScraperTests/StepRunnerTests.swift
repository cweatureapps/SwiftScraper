//
//  SwiftScraperTests.swift
//  SwiftScraperTests
//
//  Created by Ken Ko on 20/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

@testable import SwiftScraper
import XCTest

/// End-to-end tests for the `StepRunner`, which is the engine that runs the step pipeline.
class StepRunnerTests: XCTestCase { // swiftlint:disable:this type_body_length

    private let error = NSError(domain: "Random", code: 456, userInfo: nil)

    private let openPageOneStep = OpenPageStep(path: Bundle.module.url(forResource: "page1",
                                                                       withExtension: "html")!.absoluteString,
                                               assertionName: "assertPage1Title")

    private let openWaitPageStep = OpenPageStep(path: Bundle.module.url(forResource: "waitTest",
                                                                        withExtension: "html")!.absoluteString,
                                                assertionName: "assertWaitTestTitle")

    private let doNotExecuteStep = ProcessStep { _ in
        XCTFail("This step should not run")
        return .proceed
    }

    private var stepRunnerStates: [StepRunnerState] = []

    private func makeStepRunner(steps: [Step]) throws -> StepRunner {
        let runner = try StepRunner(moduleName: "StepRunnerTests", scriptBundle: Bundle.module, steps: steps)
        runner.stateObservers.append { newValue in
            self.stepRunnerStates.append(newValue)
        }
        return runner
    }

    private func waitForExpectations() {
        waitForExpectations(timeout: 5) { error in
            guard let error = error else {
                return
            }
            XCTFail(error.localizedDescription)
        }
    }

    private func assertStates(_ states: [StepRunnerState]) {
        XCTAssertEqual(stepRunnerStates, states)
    }

    private func assertModel(_ model: JSON) {
        XCTAssertEqual(model["number"] as? Double, 987.6)
        XCTAssertEqual(model["bool"] as? Bool, true)
        XCTAssertEqual(model["text"] as? String, "lorem")
        XCTAssertEqual(model["numArr"] as? [Int], [1, 2, 3])
        XCTAssertEqual((model["obj"] as? JSON)?["foo"] as? String, "bar")
    }

    // MARK: - OpenPageStep

    func testOpenPageStep() throws {
        let exp = expectation(description: #function)
        let stepRunner = try makeStepRunner(steps: [openPageOneStep])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .success])
    }

    func testOpenPageStepWithoutAssertion() throws {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(path: Bundle.module.url(forResource: "page1", withExtension: "html")!.absoluteString)

        let step2 = ScriptStep(functionName: "assertPage1Title") { response, _ in
            XCTAssertEqual(response as? Bool, true)
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [step1, step2])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .success])
    }

    func testOpenPageAssertionFailed() throws {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(path: Bundle.module.url(forResource: "page1", withExtension: "html")!.absoluteString,
                                 assertionName: "assertPage2Title")

        let stepRunner = try makeStepRunner(steps: [step1])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .failure(error: error)])
        if case StepRunnerState.failure(let error as SwiftScraperError) = stepRunner.state {
            if case SwiftScraperError.contentUnexpected = error {
               // Pass
            } else {
                XCTFail("Expected that the step should fail with a contentUnexpected error")
            }
        } else {
            XCTFail("Expected that the step should fail")
        }
    }

    func testOpenPageStepFailed() throws {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(path: "http://qwerasdfzxcv")

        let stepRunner = try makeStepRunner(steps: [step1])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .failure(error: error)])
        if case StepRunnerState.failure(let error as SwiftScraperError) = stepRunner.state {
            XCTAssertEqual(error.errorDescription, "Something went wrong when navigating to the page")
            if case SwiftScraperError.navigationFailed(let innerError as NSError) = error {
                XCTAssertEqual(innerError.domain, "NSURLErrorDomain")
                let codeMatches = innerError.code == NSURLErrorCannotFindHost ||
                    innerError.code == NSURLErrorNotConnectedToInternet
                XCTAssertTrue(codeMatches, "Error should be cannot find host, or internet connection error")

            } else {
                XCTFail("Expected that the step should fail with a navigationFailed error")
            }
        } else {
            XCTFail("Expected that the step should fail")
        }
    }

    // MARK: - WaitStep

    func testWaitStep() throws {
        var startDate: Date!

        let exp = expectation(description: #function)

        let step2 = WaitStep(waitTimeInSeconds: 0.5)

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        var stateChangeCounter = 0
        stepRunner.stateObservers.append { newValue in
            switch stateChangeCounter {
            case 0:
                XCTAssertEqual(newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                XCTAssertEqual(newValue, StepRunnerState.inProgress(index: 1))
                startDate = Date()
            case 2:
                XCTAssertEqual(newValue, StepRunnerState.success)
                let endDate = Date()
                XCTAssertTrue(endDate.timeIntervalSince(startDate) > 0.49)
                exp.fulfill()
            default:
                XCTFail("Too many state changes")
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    // MARK: - WaitForConditionStep

    func testWaitForConditionStep() throws {
        let exp = expectation(description: #function)

        let step2 = WaitForConditionStep(
            assertionName: "testWaitForCondition",
            timeoutInSeconds: 2)

        let step3 = ScriptStep(functionName: "getInnerText", params: "#foo") { response, _ in
            XCTAssertEqual(response as? String, "modified")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openWaitPageStep, step2, step3])
        stepRunner.run()
        waitForExpectations()
        assertStates([.inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 2), .success])
    }

    func testWaitForConditionStepTimeout() throws {
        let exp = expectation(description: #function)

        let step2 = WaitForConditionStep(
            assertionName: "testWaitForCondition",
            timeoutInSeconds: 0.4)

        let stepRunner = try makeStepRunner(steps: [openWaitPageStep, step2])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
        if case StepRunnerState.failure(error: let error) = stepRunner.state {
            switch error {
            case SwiftScraperError.timeout:
                break  // Pass
            default:
                XCTFail("Expected state to be failed with timeout")
            }
        } else {
            XCTFail("Expected state to be failed with timeout")
        }
    }

    func testWaitForConditionStepAssertionFailure() throws {
        let exp = expectation(description: #function)

        // Tests what happens if the assertion fails. This function doesn't exist.
        let step2 = WaitForConditionStep(
            assertionName: "foobarThisWillFail",
            timeoutInSeconds: 2)

        let stepRunner = try makeStepRunner(steps: [openWaitPageStep, step2])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
        if case StepRunnerState.failure(error: let error) = stepRunner.state {
            switch error {
            case SwiftScraperError.javascriptError:
                break // Pass
            default:
                XCTFail("Expected state to be failed with javascriptError")
            }
        } else {
            XCTFail("Expected state to be failed with javascriptError")
        }
    }

    func testWaitForConditionStepModelPassing() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["foo"] = "bar"
            return .proceed
        }

        let step3 = WaitForConditionStep(assertionName: "testWaitForCondition", timeoutInSeconds: 2)

        let stepRunner = try makeStepRunner(steps: [openWaitPageStep, step2, step3])
        stepRunner.run {
            XCTAssertEqual(stepRunner.model["foo"] as? String, "bar")
            exp.fulfill()
        }
        waitForExpectations()
    }

    // MARK: - ProcessStep

    func testProcessStep() throws {
        let exp = expectation(description: #function)

        // model is updated here
        let step2 = ProcessStep { model in
            model["number"] = 987.6
            model["bool"] = true
            model["text"] = "lorem"
            model["numArr"] = [1, 2, 3]
            model["obj"] = ["foo": "bar"]
            return .proceed
        }

        let step3 = ProcessStep { model in
            self.assertModel(model)
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 2), .success])
        self.assertModel(stepRunner.model)
    }

    func testProcessStepFinishEarly() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2"] = 123
            exp.fulfill()
            return .finish // finish early
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .success])
        XCTAssertEqual(stepRunner.model["step2"] as? Int, 123)
    }

    func testProcessStepFailEarly() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2"] = 123
            let error = NSError(domain: "StepRunnerTests", code: 12_345, userInfo: nil)
            exp.fulfill()
            return .failure(error) // fail early
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
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

    func testProcessStepSkipStep() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2"] = 123
            return .jumpToStep(3)
        }

        let step4 = ProcessStep { model in
            model["step4"] = 345
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, doNotExecuteStep, step4])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 3), .success])
        XCTAssertEqual(stepRunner.model["step2"] as? Int, 123)
        XCTAssertEqual(stepRunner.model["step4"] as? Int, 345)
    }

    func testProcessStepSkipToInvalidStep() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2"] = 123
            return .jumpToStep(4)
        }
        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
        XCTAssertEqual(stepRunner.model["step2"] as? Int, 123)
        if case StepRunnerState.failure(let error as SwiftScraperError) = stepRunner.state {
            if case SwiftScraperError.incorrectStep = error {
               // Pass
            } else {
                XCTFail("Expected that the step should fail with a incorrectStep error")
            }
        } else {
            XCTFail("Expected that the step should fail")
        }
    }

    func testProcessStepSkipStepToLoop() throws {
        var counter1 = 0
        var counter2 = 0

        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2-\(counter1)"] = counter1
            counter1 += 1
            return .proceed
        }

        let step3 = ProcessStep { model in
            model["step3-\(counter2)"] = counter2
            counter2 += 1
            if counter2 == 3 {
                return .proceed  // continue as normal after 3 increments
            } else {
                return .jumpToStep(1)  // loop back to step2 again
            }
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3])
        stepRunner.run {
            // assert that the steps are called the correct number of times
            XCTAssertEqual(counter1, 3)
            XCTAssertEqual(counter2, 3)

            // asert the model can be updated
            XCTAssertEqual(stepRunner.model["step2-0"] as? Int, 0)
            XCTAssertEqual(stepRunner.model["step3-0"] as? Int, 0)
            XCTAssertEqual(stepRunner.model["step2-1"] as? Int, 1)
            XCTAssertEqual(stepRunner.model["step3-1"] as? Int, 1)
            XCTAssertEqual(stepRunner.model["step2-2"] as? Int, 2)
            XCTAssertEqual(stepRunner.model["step3-2"] as? Int, 2)
            exp.fulfill()
        }
        waitForExpectations()
    }

    // MARK: - ScriptStep

    func testScriptStep() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "Hello world!")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .success])
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

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3, step4, step5, step6, step7])
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

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
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

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .success])
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

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()
    }

    func testScriptStepFailed() throws {
        let exp = expectation(description: #function)

        let step2 = ScriptStep(functionName: "foobarThisWillFail") { _, _ in
            XCTFail("Should not call handler if script fails")
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
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

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
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

    // MARK: - PageChangeStep

    func testPageChangeStep() throws {
        let exp = expectation(description: #function)

        let step2 = PageChangeStep(functionName: "goToPage2", assertionName: "assertPage2Title")

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .success])
    }

    func testPageChangeStepWithParams() throws {
        let exp = expectation(description: #function)

        let step2 = PageChangeStep(
            functionName: "goToPage2WithParams",
            params: "apple",
            "red",
            assertionName: "assertPage2Title"
        )

        let step3 = ScriptStep(
            functionName: "getInnerText",
            params: "#paramsSpan"
        ) { response, _ in
            XCTAssertEqual(response as? String, "fruit is apple, color is red")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()
    }

    func testPageChangeStepWithModelParams() throws {
        let exp = expectation(description: #function)

        // model is updated here
        let step2 = ProcessStep { model in
            model["fruit"] = "apple"
            model["color"] = "red"
            return .proceed
        }

        // parameters for step 3 comes from the model
        let step3 = PageChangeStep(
            functionName: "goToPage2WithParams",
            paramsKeys: ["fruit", "color"],
            assertionName: "assertPage2Title")

        let step4 = ScriptStep(
            functionName: "getInnerText",
            params: "#paramsSpan") { response, _ in
                XCTAssertEqual(response as? String, "fruit is apple, color is red")
                exp.fulfill()
                return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3, step4])
        stepRunner.run()
        waitForExpectations()
    }

    func testPageChangeStepFailJavaScript() throws {
        let exp = expectation(description: #function)

        let step2 = PageChangeStep(functionName: "generateException") // Call JS which has exception

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .failure(error: error)])
        if case StepRunnerState.failure(let error as SwiftScraperError) = stepRunner.state {
            if case SwiftScraperError.javascriptError(let errorMessage) = error {
                XCTAssertEqual(errorMessage, "JavaScript exception thrown")
            } else {
                XCTFail("Expected that the step should fail with a javascriptError")
            }
        } else {
            XCTFail("Expected that the step should fail")
        }
    }

    // MARK: - AsyncScriptStep

    func testAsyncScriptStep() throws {
        let exp = expectation(description: #function)

        let step2 = AsyncScriptStep(functionName: "getStringAsync") { response, _ in
            XCTAssertEqual(response as? String, "thanks for waiting...hello!")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()

        assertStates([.inProgress(index: 0), .inProgress(index: 1), .success])
    }

    func testAsyncScriptStepWithMultipleArgumentsCanBeEchoedBack() throws {
        let exp = expectation(description: #function)

        let step2 = AsyncScriptStep(
            functionName: "multiArgAsync",
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

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()
    }

    func testAsyncScriptStepTakesParamsFromModel() throws {
        let exp = expectation(description: #function)

        // model is updated here
        let step2 = ProcessStep { model in
            model["number"] = 987.6
            model["bool"] = true
            model["text"] = "lorem"
            model["numArr"] = [1, 2, 3]
            model["obj"] = ["foo": "bar"]
            return .proceed
        }

        // parameters for step 3 comes from the model
        let step3 = AsyncScriptStep(
            functionName: "multiArgAsync",
            paramsKeys: ["number", "bool", "text", "numArr", "obj"]) { response, _ in
                let json = response as? JSON
                self.assertModel(json!)
                exp.fulfill()
                return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()
    }

    // MARK: - Reusing Step Runner

    func testReuse() throws {
        let exp = expectation(description: #function)

        // Arrange - load a screen and modify the heading

        let step2 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "Hello world!")
            return .proceed
        }

        let step3 = ScriptStep(functionName: "modifyPage1Heading", params: "heading changed") { _, _ in .proceed }

        let step4 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "heading changed")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [openPageOneStep, step2, step3, step4])
        stepRunner.run()
        waitForExpectations()

        // Act and Assert - process more steps on a step runner that has finished executing

        let exp2 = expectation(description: #function + "2")

        let step5 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "heading changed", "Browser should retain state of the web page")
            return .proceed
        }

        let step6 = ScriptStep(functionName: "modifyPage1Heading", params: "changing heading 2") { _, _ in .proceed }

        let step7 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "changing heading 2")
            exp2.fulfill()
            return .proceed
        }

        stepRunnerStates = []
        stepRunner.run(steps: [step5, step6, step7])
        waitForExpectations()

        assertStates([.notStarted, .inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 2), .success])
    }
} // swiftlint:disable:this file_length
