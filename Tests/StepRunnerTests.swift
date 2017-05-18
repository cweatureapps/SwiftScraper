//
//  SwiftScraperTests.swift
//  SwiftScraperTests
//
//  Created by Ken Ko on 20/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import XCTest
@testable import SwiftScraper

/// End-to-end tests for the `StepRunner`, which is the engine that runs the step pipeline.
class StepRunnerTests: XCTestCase {

    func waitForExpectations() {
        waitForExpectations(timeout: 5) { error in
            guard let error = error else { return }
            XCTFail(error.localizedDescription)
        }
    }

    func path(for filename: String) -> String {
        return Bundle(for: StepRunnerTests.self).url(forResource: filename, withExtension: "html")!.absoluteString
    }

    func makeStepRunner(steps: [Step]) -> StepRunner {
        return StepRunner(
            moduleName: "StepRunnerTests",
            scriptBundle: Bundle(for: StepRunnerTests.self),
            steps: steps)
    }

    // MARK: - OpenPageStep

    func testOpenPageStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let stepRunner = makeStepRunner(steps: [step1])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                assertState(change.newValue, StepRunnerState.success)
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testOpenPageStepFailed() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(path: "http://qwerasdfzxcv")

        let stepRunner = makeStepRunner(steps: [step1])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                if case StepRunnerState.failure(let error as SwiftScraperError) = change.newValue {
                    XCTAssertEqual(error.errorDescription, "Something went wrong when navigating to the page")
                    if case SwiftScraperError.navigationFailed(let innerError as NSError) = error {
                        XCTAssertEqual(innerError.domain, "NSURLErrorDomain")
                        let codeMatches = innerError.code == NSURLErrorCannotFindHost ||
                            innerError.code == NSURLErrorNotConnectedToInternet
                        XCTAssertTrue(codeMatches, "Error should be cannot find host, or an internet connection error if there is no internet")

                    } else {
                        XCTFail("Expected that the step should fail with a navigationFailed error")
                    }
                } else {
                    XCTFail("Expected that the step should fail")
                }
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    // MARK: - WaitStep

    func testWaitStep() {
        var startDate: Date!

        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = WaitStep(waitTimeInSeconds: 0.5)

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            print("afterChange called")
            switch stateChangeCounter {
            case 0:
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                assertState(change.newValue, StepRunnerState.inProgress(index: 1))
                startDate = Date()
            case 2:
                assertState(change.newValue, StepRunnerState.success)
                let endDate = Date()
                XCTAssertTrue(endDate.timeIntervalSince(startDate) > 0.49)
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    // MARK: - WaitForConditionStep

    func testWaitForConditionStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "waitTest"),
            assertionName: "assertWaitTestTitle")

        let step2 = WaitForConditionStep(
            assertionName: "testWaitForCondition",
            timeoutInSeconds: 2)

        let step3 = ScriptStep(functionName: "getInnerText", params: "#foo") { response, _ in
            XCTAssertEqual(response as? String, "modified")
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2, step3])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...2:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 3:
                assertState(change.newValue, StepRunnerState.success)
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testWaitForConditionStepTimeout() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "waitTest"),
            assertionName: "assertWaitTestTitle")

        let step2 = WaitForConditionStep(
            assertionName: "testWaitForCondition",
            timeoutInSeconds: 0.4)

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...1:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 2:
                if case StepRunnerState.failure(error: let error) = change.newValue {
                    switch error {
                    case SwiftScraperError.timeout: break  // Pass
                    default: XCTFail("Expected state to be failed with timeout")
                    }
                } else {
                    XCTFail("Expected state to be failed with timeout")
                }
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testWaitForConditionStepAssertionFailure() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "waitTest"),
            assertionName: "assertWaitTestTitle")

        let step2 = WaitForConditionStep(
            assertionName: "foobarThisWillFail",  // Tests what happens if the assertion fails. This function doesn't exist.
            timeoutInSeconds: 2)

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...1:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 2:
                if case StepRunnerState.failure(error: let error) = change.newValue {
                    switch error {
                    case SwiftScraperError.javascriptError: break  // Pass
                    default: XCTFail("Expected state to be failed with javascriptError")
                    }
                } else {
                    XCTFail("Expected state to be failed with javascriptError")
                }
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testWaitForConditionStepModelPassing() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "waitTest"),
            assertionName: "assertWaitTestTitle")

        let step2 = ProcessStep { model in
            model["foo"] = "bar"
            return .proceed
        }

        let step3 = WaitForConditionStep(
            assertionName: "testWaitForCondition",
            timeoutInSeconds: 2)

        let stepRunner = makeStepRunner(steps: [step1, step2, step3])
        stepRunner.state.afterChange.add { change in
            if case StepRunnerState.success = change.newValue {
                XCTAssertEqual(stepRunner.model["foo"] as? String, "bar")
                exp.fulfill()
            }
        }
        stepRunner.run()
        waitForExpectations()
    }

    // MARK: - ProcessStep

    func testProcessStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        // model is updated here
        let step2 = ProcessStep { model in
            model["number"] = 987.6
            model["bool"] = true
            model["text"] = "lorem"
            model["numArr"] = [1,2,3]
            model["object"] = ["foo": "bar"]
            return .proceed
        }

        let step3 = ProcessStep { model in
            XCTAssertEqual(model["number"] as? Double, 987.6)
            XCTAssertEqual(model["bool"] as? Bool, true)
            XCTAssertEqual(model["text"] as? String, "lorem")
            XCTAssertEqual(model["numArr"] as! [Int], [1,2,3])
            XCTAssertEqual((model["object"] as? JSON)?["foo"] as? String, "bar")
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2, step3])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...2:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 3:
                assertState(change.newValue, StepRunnerState.success)

                // assert the model
                let model = stepRunner.model
                XCTAssertEqual(model["number"] as? Double, 987.6)
                XCTAssertEqual(model["bool"] as? Bool, true)
                XCTAssertEqual(model["text"] as? String, "lorem")
                XCTAssertEqual(model["numArr"] as! [Int], [1,2,3])
                XCTAssertEqual((model["object"] as? JSON)?["foo"] as? String, "bar")
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testProcessStepFinishEarly() {
        let exp = expectation(description: #function)

        let step0 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step1 = ProcessStep { model in
            model["step1"] = 123
            return .finish // finish early
        }

        let step2 = ProcessStep { model in
            XCTFail("step 2 should not run")
            return .proceed
        }

        let step3 = ProcessStep { model in
            XCTFail("step 3 should not run")
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step0, step1, step2, step3])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                // Step 0 OpenPageStep
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                // Step 1 ProcessStep - this will call .finish
                assertState(change.newValue, StepRunnerState.inProgress(index: 1))
            case 2:
                assertState(change.newValue, StepRunnerState.success)
                XCTAssertEqual(stepRunner.model["step1"] as? Int, 123)
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testProcessStepFailEarly() {
        let exp = expectation(description: #function)

        let step0 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step1 = ProcessStep { model in
            model["step1"] = 123
            let error = NSError(domain: "StepRunnerTests", code: 12345, userInfo: nil)
            return .failure(error) // fail early
        }

        let step2 = ProcessStep { model in
            XCTFail("step 2 should not run")
            return .proceed
        }

        let step3 = ProcessStep { model in
            XCTFail("step 3 should not run")
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step0, step1, step2, step3])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                // Step 0 OpenPageStep
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                // Step 1 ProcessStep - this will call .failure
                assertState(change.newValue, StepRunnerState.inProgress(index: 1))
            case 2:
                if case .failure(let error) = change.newValue {
                    // assert that error is correct
                    XCTAssertEqual((error as NSError).domain, "StepRunnerTests")
                    XCTAssertEqual((error as NSError).code, 12345)

                    // assert that model is correct
                    XCTAssertEqual(stepRunner.model["step1"] as? Int, 123)
                } else {
                    XCTFail("state should be failure, but was \(change.newValue)")
                }
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testProcessStepSkipStep() {
        var wasCalled = false

        let exp = expectation(description: #function)

        let step0 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step1 = ProcessStep { model in
            model["step1"] = 123
            return .jumpToStep(3)
        }

        let step2 = ProcessStep { model in
            XCTFail("step 2 should be skipped and not run")
            return .proceed
        }

        let step3 = ProcessStep { model in
            model["step3"] = 345
            wasCalled = true
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step0, step1, step2, step3])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                // Step 0 open page
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                // Step 1 jump step
                assertState(change.newValue, StepRunnerState.inProgress(index: 1))
            case 2:
                // Step 3
                assertState(change.newValue, StepRunnerState.inProgress(index: 3))
                assertState(change.oldValue, StepRunnerState.inProgress(index: 1))
            case 3:
                assertState(change.newValue, StepRunnerState.success)
                XCTAssertTrue(wasCalled)
                XCTAssertEqual(stepRunner.model["step1"] as? Int, 123)
                XCTAssertEqual(stepRunner.model["step3"] as? Int, 345)
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    func testProcessStepSkipStepToLoop() {
        var counter1 = 0
        var counter2 = 0

        let exp = expectation(description: #function)

        let step0 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step1 = ProcessStep { model in
            model["step1-\(counter1)"] = counter1
            counter1 += 1
            return .proceed
        }

        let step2 = ProcessStep { model in
            model["step2-\(counter2)"] = counter2
            counter2 += 1
            if counter2 == 3 {
                return .proceed  // continue as normal after 3 increments
            } else {
                return .jumpToStep(1)  // loop back to step1 again
            }
        }

        let stepRunner = makeStepRunner(steps: [step0, step1, step2])
        stepRunner.state.afterChange.add { change in
            if change.newValue == .success {
                // assert that the steps are called the correct number of times
                XCTAssertEqual(counter1, 3)
                XCTAssertEqual(counter2, 3)

                // asert the model can be updated
                XCTAssertEqual(stepRunner.model["step1-0"] as? Int, 0)
                XCTAssertEqual(stepRunner.model["step2-0"] as? Int, 0)
                XCTAssertEqual(stepRunner.model["step1-1"] as? Int, 1)
                XCTAssertEqual(stepRunner.model["step2-1"] as? Int, 1)
                XCTAssertEqual(stepRunner.model["step1-2"] as? Int, 2)
                XCTAssertEqual(stepRunner.model["step2-2"] as? Int, 2)
                exp.fulfill()
            }
        }
        stepRunner.run()
        waitForExpectations()
    }

    // MARK: - ScriptStep

    func testScriptStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = ScriptStep(functionName: "getInnerText", params: "h1") { response, _ in
            XCTAssertEqual(response as? String, "Hello world!")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                assertState(change.newValue, StepRunnerState.inProgress(index: 1))
            case 2:
                assertState(change.newValue, StepRunnerState.success)
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepCanReturnDifferentTypes() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = ScriptStep(functionName: "getString") { response, _ in
            XCTAssertEqual(response as? String, "hello world")
            return .proceed
        }

        let step3 = ScriptStep(functionName: "getBooleanTrue") { response, _ in
            XCTAssertTrue(response as! Bool)
            return .proceed
        }

        let step4 = ScriptStep(functionName: "getBooleanFalse") { response, _ in
            XCTAssertFalse(response as! Bool)
            return .proceed
        }

        let step5 = ScriptStep(functionName: "getNumber") { response, _ in
            XCTAssertEqual(response as? Double, 3.45)
            return .proceed
        }

        let step6 = ScriptStep(functionName: "getJsonObject") { response, _ in
            let json = response as! JSON
            XCTAssertEqual(json["message"] as? String, "something")
            return .proceed
        }

        let step7 = ScriptStep(functionName: "getJsonArray") { response, _ in
            let jsonArray = response as! [JSON]
            XCTAssertEqual(jsonArray[0]["fruit"] as? String, "apple")
            XCTAssertEqual(jsonArray[1]["fruit"] as? String, "pear")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2, step3, step4, step5, step6, step7])
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepWithMultipleArgumentsCanBeEchoedBack() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = ScriptStep(
            functionName: "multiArg",
            params: 7.89, true, "lorem", [1,2,3], ["foo": "bar"],
            handler: { response, _ in
                let json = response as! JSON
                XCTAssertEqual(json["number"] as! Double, 7.89)
                XCTAssertTrue(json["bool"] as! Bool)
                XCTAssertEqual(json["text"] as! String, "lorem")
                XCTAssertEqual(json["numArr"] as! [Int], [1,2,3])
                XCTAssertEqual((json["obj"] as! JSON)["foo"] as! String, "bar")
                exp.fulfill()
                return .proceed
        })

        let stepRunner = makeStepRunner(steps: [step1, step2])
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepUpdatesModel() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = ScriptStep(functionName: "getInnerText", params: "h1") { response, model in
            let responseString = response as? String
            XCTAssertEqual(responseString, "Hello world!")
            model["step2"] = responseString // model is updated here
            return .proceed
        }

        var stateChangeCounter = 0
        let stepRunner = makeStepRunner(steps: [step1, step2])
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...1:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 2:
                assertState(change.newValue, StepRunnerState.success)
                XCTAssertEqual(stepRunner.model["step2"] as? String, "Hello world!") // Check that it is saved to the model
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepTakesParamsFromModel() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        // model is updated here
        let step2 = ProcessStep { model in
            model["text"] = "hello world"
            model["number"] = 987.6
            model["object"] = ["foo": "bar"]
            return .proceed
        }

        // parameters for step 3 comes from the model
        let step3 = ScriptStep(
            functionName: "testParamsFromModel",
            paramsKeys: ["text", "number", "doesntExistShouldBeNull", "object"]) { response, _ in
            XCTAssertTrue(response as! Bool, "JavaScript failed assertion when checking the parameters passed from the model")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2, step3])
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepFailEarly() {
        let exp = expectation(description: #function)

        let step0 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step1 = ScriptStep(
            functionName: "getString") { _, model in
                model["step1"] = 123
                let error = NSError(domain: "StepRunnerTests", code: 12345, userInfo: nil)
                return .failure(error) // fail early
        }

        let step2 = ProcessStep { model in
            XCTFail("step 2 should not run")
            return .proceed
        }

        let step3 = ProcessStep { model in
            XCTFail("step 3 should not run")
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step0, step1, step2, step3])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0:
                // Step 0 OpenPageStep
                assertState(change.newValue, StepRunnerState.inProgress(index: 0))
            case 1:
                // Step 1 ProcessStep - this will call .failure
                assertState(change.newValue, StepRunnerState.inProgress(index: 1))
            case 2:
                if case .failure(let error) = change.newValue {
                    // assert that error is correct
                    XCTAssertEqual((error as NSError).domain, "StepRunnerTests")
                    XCTAssertEqual((error as NSError).code, 12345)

                    // assert that model is correct
                    XCTAssertEqual(stepRunner.model["step1"] as? Int, 123)
                } else {
                    XCTFail("state should be failure, but was \(change.newValue)")
                }
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()
        waitForExpectations()
    }

    // MARK: - PageChangeStep

    func testPageChangeStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = PageChangeStep(
            functionName: "goToPage2",
            assertionName: "assertPage2Title")

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...1:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 2:
                assertState(change.newValue, StepRunnerState.success)
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testPageChangeStepWithParams() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = PageChangeStep(
            functionName: "goToPage2WithParams",
            params: "apple", "red",
            assertionName: "assertPage2Title")

        let step3 = ScriptStep(
            functionName: "getInnerText",
            params: "#paramsSpan") { response, _ in
            XCTAssertEqual(response as? String, "fruit is apple, color is red")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2, step3])
        stepRunner.run()

        waitForExpectations()
    }

    func testPageChangeStepWithModelParams() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        // model is updated here
        let step2 = ProcessStep{ model in
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

        let stepRunner = makeStepRunner(steps: [step1, step2, step3, step4])
        stepRunner.run()
        
        waitForExpectations()
    }

    func testPageChangeStepFailJavaScript() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = PageChangeStep(functionName: "generateException") // Call JS which has exception

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...1:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 2:
                if case StepRunnerState.failure(let error as SwiftScraperError) = change.newValue {
                    if case SwiftScraperError.javascriptError(let errorMessage) = error {
                        XCTAssertEqual(errorMessage, "JavaScript exception thrown")
                    } else {
                        XCTFail("Expected that the step should fail with a javascriptError")
                    }
                } else {
                    XCTFail("Expected that the step should fail")
                }
                exp.fulfill()
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    // MARK: - AsyncScriptStep

    func testAsyncScriptStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = AsyncScriptStep(functionName: "getStringAsync") { response, _ in
            XCTAssertEqual(response as? String, "thanks for waiting...hello!")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stateChangeCounter = 0
        stepRunner.state.afterChange.add { change in
            switch stateChangeCounter {
            case 0...1:
                assertState(change.newValue, StepRunnerState.inProgress(index: stateChangeCounter))
            case 2:
                assertState(change.newValue, StepRunnerState.success)
            default:
                break
            }
            stateChangeCounter += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testAsyncScriptStepWithMultipleArgumentsCanBeEchoedBack() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        let step2 = AsyncScriptStep(
            functionName: "multiArgAsync",
            params: 7.89, true, "lorem", [1,2,3], ["foo": "bar"],
            handler: { response, _ in
                let json = response as! JSON
                XCTAssertEqual(json["number"] as! Double, 7.89)
                XCTAssertTrue(json["bool"] as! Bool)
                XCTAssertEqual(json["text"] as! String, "lorem")
                XCTAssertEqual(json["numArr"] as! [Int], [1,2,3])
                XCTAssertEqual((json["obj"] as! JSON)["foo"] as! String, "bar")
                exp.fulfill()
                return .proceed
        })

        let stepRunner = makeStepRunner(steps: [step1, step2])
        stepRunner.run()

        waitForExpectations()
    }

    func testAsyncScriptStepTakesParamsFromModel() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            assertionName: "assertPage1Title")

        // model is updated here
        let step2 = ProcessStep { model in
            model["number"] = 987.6
            model["bool"] = true
            model["text"] = "lorem"
            model["numArr"] = [1,2,3]
            model["object"] = ["foo": "bar"]
            return .proceed
        }

        // parameters for step 3 comes from the model
        let step3 = AsyncScriptStep(
            functionName: "multiArgAsync",
            paramsKeys: ["number", "bool", "text", "numArr", "object"],
            handler: { response, _ in
                let json = response as! JSON
                XCTAssertEqual(json["number"] as! Double, 987.6)
                XCTAssertTrue(json["bool"] as! Bool)
                XCTAssertEqual(json["text"] as! String, "lorem")
                XCTAssertEqual(json["numArr"] as! [Int], [1,2,3])
                XCTAssertEqual((json["obj"] as! JSON)["foo"] as! String, "bar")
                exp.fulfill()
                return .proceed
        })

        let stepRunner = makeStepRunner(steps: [step1, step2, step3])
        stepRunner.run()
        
        waitForExpectations()
    }
}

/// Assert that the two given states are equal.
private func assertState(_ actual: StepRunnerState, _ expected: StepRunnerState, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(actual == expected, "state should be \(expected) but was \(actual)", file: file, line: line)
}
