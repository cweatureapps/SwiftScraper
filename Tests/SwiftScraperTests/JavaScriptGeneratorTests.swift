//
//  BrowserTests.swift
//  SwiftScraper
//
//  Created by Ken Ko on 24/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

@testable import SwiftScraper
import XCTest

class JavaScriptGeneratorTests: XCTestCase {

    func testGenerateScriptNoArg() {
        let script = try? JavaScriptGenerator.generateScript(moduleName: "MyModule", functionName: "doSomething")
        XCTAssertEqual(script, "MyModule.doSomething()")
    }

    func testInvalidArg() {
        XCTAssertThrowsError(try JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                                    functionName: "doSomething",
                                                                    params: [SwiftScraperError.timeout])) {
            if case .parameterSerialization = $0 as? SwiftScraperError {
                // Pass
            } else {
                XCTFail("Expected parameterSerialization error")
            }
        }
    }

    func testGenerateNullArg() {
        let script = try? JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                             functionName: "doSomething",
                                                             params: [NSNull()])
        XCTAssertEqual(script, "MyModule.doSomething(null)")
    }

    func testGenerateScriptStringArg() {
        let script = try? JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                             functionName: "doSomething",
                                                             params: ["hello"])
        XCTAssertEqual(script, "MyModule.doSomething(\"hello\")")
    }

    func testGenerateScriptNumericArg() {
        let script1 = try? JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                              functionName: "doSomething",
                                                              params: [3])
        XCTAssertEqual(script1, "MyModule.doSomething(3)")

        let script2 = try? JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                              functionName: "doSomething",
                                                              params: [75.26])
        XCTAssertEqual(script2, "MyModule.doSomething(75.26)")
    }

    func testGenerateScriptArrayArg() {
        let script1 = try? JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                              functionName: "doSomething",
                                                              params: [[1, 2, 3]])
        XCTAssertEqual(script1, "MyModule.doSomething([1,2,3])")

        let script2 = try? JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                              functionName: "doSomething",
                                                              params: [["a", "b"]])
        XCTAssertEqual(script2, "MyModule.doSomething([\"a\",\"b\"])")
    }

    func testGenerateMultipleArgs() {
        let script1 = try? JavaScriptGenerator.generateScript(
            moduleName: "MyModule",
            functionName: "doSomething",
            params: ["lorem", 45, 0.544])
        XCTAssertEqual(script1, "MyModule.doSomething(\"lorem\",45,0.544)")

        let script2 = try? JavaScriptGenerator.generateScript(
            moduleName: "MyModule",
            functionName: "doSomething",
            params: ["lorem", NSNull(), ["message": "foo"]])
        XCTAssertEqual(script2, "MyModule.doSomething(\"lorem\",null,{\"message\":\"foo\"})")
    }

    func testGenerateScriptJSONArg() throws {
        let json: JSON = [
            "someString": "lorem ipsum",
            "someInt": 3,
            "someDouble": 5.6,
            "someBool": true,
            "someArray": [1, 2, 3],
            "someObject": [
                "message": "hello world!"
            ]
        ]
        let script = try JavaScriptGenerator.generateScript(moduleName: "MyModule",
                                                            functionName: "doSomething",
                                                            params: [json])
        XCTAssertTrue(script.hasPrefix("MyModule.doSomething("))
        XCTAssertTrue(script.hasSuffix(")"))

        // convert the parameter back into Swift JSON to assert
        let paramString = script.replacingOccurrences(of: "MyModule.doSomething(", with: "")
                            .replacingOccurrences(of: ")", with: "")
        let jsonData = paramString.data(using: String.Encoding.utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? JSON
        XCTAssertEqual(jsonObject?["someString"] as? String, "lorem ipsum")
        XCTAssertEqual(jsonObject?["someInt"] as? Int, 3)
        XCTAssertEqual(jsonObject?["someDouble"] as? Double, 5.6)
        XCTAssert(jsonObject?["someBool"] as? Bool == true)
        XCTAssertEqual(jsonObject?["someArray"] as? [Int], [1, 2, 3])

        let innerObject = jsonObject?["someObject"] as? JSON
        XCTAssertEqual(innerObject?["message"] as? String, "hello world!")
    }
}
