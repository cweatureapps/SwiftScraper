//
//  ScriptStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that runs some script which will return a result directly from the function.
public class ScriptStep: Step {
    private var functionName: String
    private var params: [Any]
    private var paramsKeys: [String]
    private var handler: (Any?, inout JSON) -> Void
    public init(
        functionName: String,
        params: Any...,
        paramsKeys: [String] = [],
        handler: @escaping (Any?, inout JSON) -> Void) {
        self.functionName = functionName
        self.params = params
        self.paramsKeys = paramsKeys
        self.handler = handler
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletion) {
        let params: [Any]
        if paramsKeys.isEmpty {
            params = self.params
        } else {
            params = paramsKeys.map { model[$0] ?? NSNull() }
        }
        runScript(browser: browser, functionName: functionName, params: params) { [weak self] result in
            guard let this = self else { return }
            switch result {
            case .failure:
                completion(.failure(StepError()))
            case .success(let response):
                var modelCopy = model
                this.handler(response, &modelCopy)
                completion(.success(modelCopy))
            }
        }
    }

    func runScript(browser: Browser, functionName: String, params: [Any], completion: @escaping ScriptResponseResultCompletion) {
        browser.runScript(functionName: functionName, params: params, completion: completion)
    }

}
