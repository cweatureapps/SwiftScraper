//
//  PageChangeStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that runs some script, which will result in a new page being loaded.
public class PageChangeStep: Step, NavigableStep {

    private var functionName: String
    private var params: [Any]
    private var paramsKeys: [String]
    var assertionName: String?

    /// Initializer.
    ///
    /// - parameter functionName: The name of the JavaScript function to call. The module namespace is automatically added.
    /// - parameter params: Parameters which will be passed to the JavaScript function.
    /// - parameter paramsKeys: Look up the values from the JSON model dictionary using these keys, 
    ///   and pass them as the parameters to the JavaScript function. If provided, these are used instead of `params`.
    /// - parameter assertionName: Name of JavaScript function that checks whether the page loaded correctly.
    public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        assertionName: String? = nil) {
        self.functionName = functionName
        self.params = params
        self.paramsKeys = paramsKeys
        self.assertionName = assertionName
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback) {
        let params: [Any]
        if paramsKeys.isEmpty {
            params = self.params
        } else {
            params = paramsKeys.map { model[$0] ?? NSNull() }
        }
        browser.runPageChangeScript(functionName: functionName, params: params) { [weak self] result in
            guard let this = self else { return }
            if case .failure(let error) = result {
                completion(.failure(error, model))
                return
            }
            this.assertNavigation(with: browser, model: model, completion: completion)
        }
    }
}
