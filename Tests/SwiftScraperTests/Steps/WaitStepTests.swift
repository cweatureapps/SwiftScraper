@testable import SwiftScraper
import XCTest

class WaitStepTests: StepRunnerCommonTests {

    func testWaitStep() throws {
        var startDate: Date!

        let exp = expectation(description: #function)

        let step2 = WaitStep(waitTimeInSeconds: 0.5)

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2])
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

}
