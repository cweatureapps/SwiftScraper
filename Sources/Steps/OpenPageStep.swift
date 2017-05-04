//
//  OpenPageStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that loads a new page.
public class OpenPageStep: Step, NavigableStep {
    private var path: String
    var assertionName: String?

    /// Initializer.
    ///
    /// - parameter path: The address of the page to load, as you would type into the browser address bar.
    /// - parameter assertionName: Name of JavaScript function that checks whether the page loaded correctly.
    public init(path: String, assertionName: String? = nil) {
        self.path = path
        self.assertionName = assertionName
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback) {
        browser.load(path: path) { [weak self] result in
            guard let this = self else { return }
            if case .failure(let error) = result {
                completion(.failure(error, model))
                return
            }
            this.assertNavigation(with: browser, model: model, completion: completion)
        }
    }
}
