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
    private var paramClosure: () -> JSON?
    private var handler: ScriptResponseCompletion
    public init(
        functionName: String,
        param paramClosure: (@escaping @autoclosure () -> JSON?) = nil,
        handler: @escaping ScriptResponseCompletion) {
        self.functionName = functionName
        self.paramClosure = paramClosure
        self.handler = handler
    }

    public func run(with browser: Browser, completion: @escaping StepCompletion) {
        browser.runScript(functionName: functionName, param: paramClosure()) { [weak self] result in
            guard let this = self else { return }
            switch result {
            case .failure:
                completion(false)
            case .success(let response):
                this.handler(response)
                completion(true)
            }
        }
    }
    
}
