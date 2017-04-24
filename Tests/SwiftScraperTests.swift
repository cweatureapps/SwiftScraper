//
//  SwiftScraperTests.swift
//  SwiftScraperTests
//
//  Created by Ken Ko on 20/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import XCTest
@testable import SwiftScraper

class SwiftScraperTests: XCTestCase {

    func waitForExpectations() {
        waitForExpectations(timeout: 5) { error in
            guard let error = error else { return }
            XCTFail(error.localizedDescription)
        }
    }

    func path(for filename: String) -> String {
        return Bundle(for: SwiftScraperTests.self).url(forResource: filename, withExtension: "html")!.absoluteString
    }

    func makeStepRunner(steps: [Step]) -> StepRunner {
        return StepRunner(
            moduleName: "SwiftScraperTests",
            scriptBundle: Bundle(for: SwiftScraperTests.self),
            steps: steps)
    }

    func testOpenPageStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            navigationAssertionFunctionName: "assertPage1Title")

        let stepRunner = makeStepRunner(steps: [step1])
        var stepIndex = 0
        stepRunner.state.afterChange.add { change in
            switch stepIndex {
            case 0:
                XCTAssertTrue(change.newValue == .inProgress(index: 0), "state should be in progress")
            case 1:
                XCTAssertTrue(change.newValue == .success, "state should be success, was \(change.newValue)")
                exp.fulfill()
            default:
                break
            }
            stepIndex += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStep() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            navigationAssertionFunctionName: "assertPage1Title")

        let step2 = ScriptStep(functionName: "getInnerText", params: ["h1"]) { response in
            XCTAssertEqual(response as? String, "Hello world!")
            exp.fulfill()
        }

        let stepRunner = makeStepRunner(steps: [step1, step2])
        var stepIndex = 0
        stepRunner.state.afterChange.add { change in
            switch stepIndex {
            case 0:
                XCTAssertTrue(change.newValue == .inProgress(index: 0), "state should be inProgress(0)")
            case 1:
                XCTAssertTrue(change.newValue == .inProgress(index: 1), "state should be inProgress(1)")
            case 2:
                XCTAssertTrue(change.newValue == .success, "state should be success, was \(change.newValue)")
            default:
                break
            }
            stepIndex += 1
        }
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepCanReturnDifferentTypes() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            navigationAssertionFunctionName: "assertPage1Title")

        let step2 = ScriptStep(functionName: "getString") { response in
            XCTAssertEqual(response as? String, "hello world")
        }

        let step3 = ScriptStep(functionName: "getBooleanTrue") { response in
            XCTAssertTrue(response as! Bool)
        }

        let step4 = ScriptStep(functionName: "getBooleanFalse") { response in
            XCTAssertFalse(response as! Bool)
        }

        let step5 = ScriptStep(functionName: "getNumber") { response in
            XCTAssertEqual(response as? Double, 3.45)
        }

        let step6 = ScriptStep(functionName: "getJsonObject") { response in
            let json = response as! JSON
            XCTAssertEqual(json["message"] as? String, "something")
        }

        let step7 = ScriptStep(functionName: "getJsonArray") { response in
            let jsonArray = response as! [JSON]
            XCTAssertEqual(jsonArray[0]["fruit"] as? String, "apple")
            XCTAssertEqual(jsonArray[1]["fruit"] as? String, "pear")
            exp.fulfill()
        }

        let stepRunner = makeStepRunner(steps: [step1, step2, step3, step4, step5, step6, step7])
        stepRunner.run()

        waitForExpectations()
    }

    func testScriptStepWithMultipleArgumentsCanBeEchoedBack() {
        let exp = expectation(description: #function)

        let step1 = OpenPageStep(
            path: path(for: "page1"),
            navigationAssertionFunctionName: "assertPage1Title")

        let step2 = ScriptStep(
            functionName: "multiArg",
            params: [7.89, true, "lorem", [1,2,3], ["foo": "bar"]],
            handler: { response in
                let json = response as! JSON
                XCTAssertEqual(json["number"] as! Double, 7.89)
                XCTAssertTrue(json["bool"] as! Bool)
                XCTAssertEqual(json["text"] as! String, "lorem")
                XCTAssertEqual(json["numArr"] as! [Int], [1,2,3])
                XCTAssertEqual((json["obj"] as! JSON)["foo"] as! String, "bar")
                exp.fulfill()
        })

        let stepRunner = makeStepRunner(steps: [step1, step2])
        stepRunner.run()

        waitForExpectations()
    }
}
