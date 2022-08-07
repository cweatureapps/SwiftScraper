@testable import SwiftScraper
import XCTest

class WaitForConditionStepTests: StepRunnerCommonTests {

    private let openWaitPageStep = OpenPageStep(path: Bundle.module.url(forResource: "waitTest",
                                                                        withExtension: "html")!.absoluteString,
                                                assertionName: "assertWaitTestTitle")

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
        XCTAssertEqual(stepRunnerStates,
                       [.inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 2), .success])
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

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), TestHelper.failureResult])
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

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), TestHelper.failureResult])
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

}
