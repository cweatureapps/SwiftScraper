//
//  SwiftScraperTests.swift
//  SwiftScraperTests
//
//  Created by Ken Ko on 20/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

@testable import SwiftScraper
import XCTest

enum TestHelper {

    static let failureResult = StepRunnerState.failure(error: NSError(domain: "Random", code: 456, userInfo: nil))

    static let openPageOneStep = OpenPageStep(path: Bundle.module.url(forResource: "page1",
                                                                      withExtension: "html")!.absoluteString,
                                              assertionName: "assertPage1Title")

}

class StepRunnerCommonTests: XCTestCase {

    var stepRunnerStates: [StepRunnerState] = [] // swiftlint:disable:this test_case_accessibility

    func makeStepRunner(steps: [Step]) throws -> StepRunner { // swiftlint:disable:this test_case_accessibility
        let runner = try StepRunner(moduleName: "StepRunnerTests", steps: steps, scriptBundle: Bundle.module)
        runner.stateObservers.append { newValue in
            self.stepRunnerStates.append(newValue)
        }
        return runner
    }

}

class StepRunnerTests: StepRunnerCommonTests {

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

        let stepRunner = try makeStepRunner(steps: [TestHelper.openPageOneStep, step2, step3, step4])
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

        XCTAssertEqual(stepRunnerStates,
                       [.notStarted, .inProgress(index: 0), .inProgress(index: 1), .inProgress(index: 2), .success])
    }
}

extension XCTestCase {

    func waitForExpectations() {
        waitForExpectations(timeout: 5) { error in
            guard let error = error else {
                return
            }
            XCTFail(error.localizedDescription)
        }
    }

    func assertModel(_ model: JSON) {
        XCTAssertEqual(model["number"] as? Double, 987.6)
        XCTAssertEqual(model["bool"] as? Bool, true)
        XCTAssertEqual(model["text"] as? String, "lorem")
        XCTAssertEqual(model["numArr"] as? [Int], [1, 2, 3])
        XCTAssertEqual((model["obj"] as? JSON)?["foo"] as? String, "bar")
    }

}
