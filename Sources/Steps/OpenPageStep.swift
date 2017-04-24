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
    var navigationAssertionFunctionName: String?

    public init(path: String, navigationAssertionFunctionName: String? = nil) {
        self.path = path
        self.navigationAssertionFunctionName = navigationAssertionFunctionName
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletion) {
        browser.load(path: path) { [weak self] success in
            guard let this = self else { return }
            guard success else {
                completion(.failure(StepError()))
                return
            }
            this.assertNavigation(with: browser, model: model, completion: completion)
        }
    }
}
