@testable import SwiftScraper
import XCTest

class AsyncScriptStepTests: StepRunnerCommonTests {

    func testAsyncScriptStep() throws {
        let exp = expectation(description: #function)

        let step2 = AsyncScriptStep(functionName: "getStringAsync") { response, _ in
            XCTAssertEqual(response as? String, "thanks for waiting...hello!")
            exp.fulfill()
            return .proceed
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), .success])
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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()
    }

}
