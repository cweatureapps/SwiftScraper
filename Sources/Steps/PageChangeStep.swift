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
    var navigationAssertionFunctionName: String?
    public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        navigationAssertionFunctionName: String? = nil) {
        self.functionName = functionName
        self.params = params
        self.paramsKeys = paramsKeys
        self.navigationAssertionFunctionName = navigationAssertionFunctionName
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletion) {
        let params: [Any]
        if paramsKeys.isEmpty {
            params = self.params
        } else {
            params = paramsKeys.map { model[$0] ?? NSNull() }
        }
        browser.runPageChangeScript(functionName: functionName, params: params) { [weak self] success in
            guard let this = self else { return }
            guard success else {
                completion(.failure(StepError()))
                return
            }
            this.assertNavigation(with: browser, model: model, completion: completion)
        }
    }
}
