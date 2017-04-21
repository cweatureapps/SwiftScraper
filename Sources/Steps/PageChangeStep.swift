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
    var functionName: String
    var paramClosure: () -> JSON?
    var navigationAssertionFunctionName: String?
    init(
        functionName: String,
        param paramClosure: (@escaping @autoclosure () -> JSON?) = nil,
        navigationAssertionFunctionName: String? = nil) {
        self.functionName = functionName
        self.paramClosure = paramClosure
        self.navigationAssertionFunctionName = navigationAssertionFunctionName
    }

    public func run(with browser: Browser, completion: @escaping StepCompletion) {
        browser.runPageChangeScript(functionName: functionName, param: paramClosure()) { [weak self] success in
            guard let this = self else { return }
            guard success else {
                completion(false)
                return
            }
            this.assertNavigation(with: browser, completion: completion)
        }
    }
}
