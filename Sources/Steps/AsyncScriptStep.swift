//
//  AsyncScriptStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that runs some script which will return a result asynchronously via `SwiftScraper.postMessage()`.
public class AsyncScriptStep: ScriptStep {

    // Manully override due to Swift unsupported warning:
    // "Synthesizing a variadic inherited initializer for subclass is unsupported"
    override public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        handler: @escaping (Any?, inout JSON) -> Void) {
        super.init(
            functionName: functionName,
            params: [],         // Can't pass to super here. e.g. if params is ['a', 3], then the single array with 2 elems would get passed to super.init
            paramsKeys: paramsKeys,
            handler: handler)
        super.params = params   // set the params here
    }

    override func runScript(browser: Browser, functionName: String, params: [Any], completion: @escaping ScriptResponseResultCompletion) {
        browser.runAsyncScript(functionName: functionName, params: params, completion: completion)
    }
}

