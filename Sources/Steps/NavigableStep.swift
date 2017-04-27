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
    var assertionName: String? { get set }
}

extension NavigableStep {

    /// Runs the assertion function to check whether the page loaded correctly and calling the `StepCompletionCallback`.
    ///
    /// - parameter browser: The `Browser` used for web scraping.
    /// - parameter model: A JSON model that allows data to be passed from step to step in the pipeline.
    /// - parameter completion: The completion called to indicate success or failure.
    func assertNavigation(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback) {
        guard let assertionName = self.assertionName else {
            completion(.proceed(model))
            return
        }
        browser.runScript(functionName: assertionName) { result in
            switch result {
            case .success(let ok as Bool) where ok:
                completion(.proceed(model))
            default:
                completion(.failure(SwiftScraperError.contentUnexpected, model))
            }
        }
    }
}
