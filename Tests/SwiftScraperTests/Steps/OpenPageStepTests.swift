@testable import SwiftScraper
import XCTest

class OpenPageStepTests: StepRunnerCommonTests {

    func testOpenPageStep() throws {
        let exp = expectation(description: #function)
        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .success])
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

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), .success])
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

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), TestHelper.failureResult])
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

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), TestHelper.failureResult])
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

}
