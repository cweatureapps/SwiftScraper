@testable import SwiftScraper
import XCTest

class ProcessStepTests: StepRunnerCommonTests {

    private let doNotExecuteStep = ProcessStep { _ in
        XCTFail("This step should not run")
        return .proceed
    }

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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates,
                       [.inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 2), .success])
        self.assertModel(stepRunner.model)
    }

    func testProcessStepFinishEarly() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2"] = 123
            exp.fulfill()
            return .finish // finish early
        }

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), .success])
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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, doNotExecuteStep, step4])
        stepRunner.run()
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates,
                       [.inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 3), .success])
        XCTAssertEqual(stepRunner.model["step2"] as? Int, 123)
        XCTAssertEqual(stepRunner.model["step4"] as? Int, 345)
    }

    func testProcessStepSkipToInvalidStep() throws {
        let exp = expectation(description: #function)

        let step2 = ProcessStep { model in
            model["step2"] = 123
            return .jumpToStep(4)
        }
        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, doNotExecuteStep, doNotExecuteStep])
        stepRunner.run {
            exp.fulfill()
        }
        waitForExpectations()

        XCTAssertEqual(stepRunnerStates, [.inProgress(index: 0), .inProgress(index: 1), TestHelper.failureResult])
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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3])
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

}
