@testable import SwiftScraper
import XCTest

class PageChangeStepTests: StepRunnerCommonTests {

    func testPageChangeStep() throws {
        let exp = expectation(description: #function)

        let step2 = PageChangeStep(functionName: "goToPage2", assertionName: "assertPage2Title")

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), .success])
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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3])
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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3, step4])
        stepRunner.run()
        waitForExpectations()
    }

    func testPageChangeStepFailJavaScript() throws {
        let exp = expectation(description: #function)

        let step2 = PageChangeStep(functionName: "generateException") // Call JS which has exception

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), TestHelper.failureResult])
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

}
