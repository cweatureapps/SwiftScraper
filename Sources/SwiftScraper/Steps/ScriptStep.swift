//
//  ScriptStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

// MARK: - Types

/// Callback invoked when a `ScriptStep` or `AsyncScriptStep` is finished.
///
/// - parameter response: Data returned from JavaScript.
/// - parameter model: The model JSON dictionary which can be modified by the step.
/// - returns: The `StepFlowResult` which allows control flow of the steps.
public typealias ScriptStepHandler = (_ response: Any?, _ model: inout JSON) -> StepFlowResult

// MARK: - ScriptStep

/// Step that runs some JavaScript which will return a result immediately from the JavaScript function.
///
/// The `StepFlowResult` returned by the `handler` can be used to drive control flow of the steps.
public class ScriptStep: Step {
    private var functionName: String
    var params: [Any]
    private var paramsKeys: [String]
    private var handler: ScriptStepHandler

    /// Initializer.
    ///
    /// - parameter functionName: The name of the JavaScript function to call. The module namespace is automatically added.
    /// - parameter params: Parameters which will be passed to the JavaScript function.
    /// - parameter paramsKeys: Look up the values from the JSON model dictionary using these keys,
    ///   and pass them as the parameters to the JavaScript function. If provided, these are used instead of `params`.
    /// - parameter handler: Callback function which returns data from JavaScript, and passes the model JSON dictionary for modification.
    public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        handler: @escaping ScriptStepHandler) {
        self.functionName = functionName
        self.params = params
        self.paramsKeys = paramsKeys
        self.handler = handler
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback) {
        let params: [Any]
        if paramsKeys.isEmpty {
            params = self.params
        } else {
            params = paramsKeys.map { model[$0] ?? NSNull() }
        }
        runScript(browser: browser, functionName: functionName, params: params) { [weak self] result in
            guard let this = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error, model))
            case .success(let response):
                var modelCopy = model
                let result = this.handler(response, &modelCopy)
                completion(result.convertToStepCompletionResult(with: modelCopy))
            }
        }
    }

    func runScript(browser: Browser, functionName: String, params: [Any], completion: @escaping ScriptResponseResultCallback) {
        browser.runScript(functionName: functionName, params: params, completion: completion)
    }

}
