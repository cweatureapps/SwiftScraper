//
//  AsyncScriptStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that runs some script which will return a result asynchronously via `SwiftScraper.postMessage()`.
///
/// The `StepFlowResult` returned by the `handler` can be used to drive control flow of the steps.
public class AsyncScriptStep: ScriptStep {

    // Note: Manually override init() due to Swift unsupported warning:
    // "Synthesizing a variadic inherited initializer for subclass is unsupported"
    // Won't need this if Swift supports it in the future.

    /// Initializer.
    ///
    /// - parameter functionName: The name of the JavaScript function to call. The module namespace is automatically added.
    /// - parameter params: Parameters which will be passed to the JavaScript function.
    /// - parameter paramsKeys: Look up the values from the JSON model dictionary using these keys,
    ///   and pass them as the parameters to the JavaScript function. If provided, these are used instead of `params`.
    /// - parameter handler: Callback function which returns data from JavaScript, and passes the model JSON dictionary for modification.
    override public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        handler: @escaping ScriptStepHandler) {
        super.init(
            functionName: functionName,
            params: [],         // Can't pass to super here. e.g. if params is ['a', 3], then the single array with 2 elems would get passed to super.init
            paramsKeys: paramsKeys,
            handler: handler)
        super.params = params   // set the params here
    }

    override func runScript(browser: Browser, functionName: String, params: [Any], completion: @escaping ScriptResponseResultCallback) {
        browser.runAsyncScript(functionName: functionName, params: params, completion: completion)
    }
}

