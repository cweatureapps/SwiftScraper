//
//  NavigableStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that will navigate to a new page.
protocol NavigableStep: Step {

    /// Name of JavaScript function that checks whether the page loaded correctly and returns a Boolean.
    var navigationAssertionFunctionName: String? { get set }
}

extension NavigableStep {
    func assertNavigation(with browser: Browser, completion: @escaping StepCompletion) {
        guard let navigationAssertionFunctionName = self.navigationAssertionFunctionName else {
            completion(true)
            return
        }
        browser.runScript(functionName: navigationAssertionFunctionName) { result in
            switch result {
            case .success(let ok as Bool) where ok:
                completion(true)
            default:
                completion(false)
            }
        }
    }
}
