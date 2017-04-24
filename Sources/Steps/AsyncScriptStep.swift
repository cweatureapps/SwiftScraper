//
//  AsyncScriptStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that runs some script which will return a result asynchronously via `window.webkit.messageHandlers.responseHandler.postMessage()`.
public class AsyncScriptStep: ScriptStep {

    // Manully override due to Swift unsupported warning:
    // "Synthesizing a variadic inherited initiaizer for subclass is unsupported"
    override public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        handler: @escaping (Any?, inout JSON) -> Void) {
        super.init(
            functionName: functionName,
            params: params,
            paramsKeys: paramsKeys,
            handler: handler)
    }

    override func runScript(browser: Browser, functionName: String, params: [Any], completion: @escaping ScriptResponseResultCompletion) {
        browser.runAsyncScript(functionName: functionName, params: params, completion: completion)
    }
}

