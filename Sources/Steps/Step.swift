//
//  Step.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Represents a step which is performed as part of the scraping pipeline flow.
/// The `StepRunner` will execute each step by calling the `run()` method,
/// and using the result of the callback to determine what to do next.
public protocol Step {

    /// Execute the step.
    ///
    /// When all work is done, the `completion` should be called, 
    /// and indicate what to do next (i.e. control flow instruction).
    ///
    /// - parameter browser: The `Browser` used for web scraping.
    /// - parameter model: A JSON model that allows data to be passed from step to step in the pipeline.
    /// - parameter completion: The completion called to indicate what to do next (i.e. control flow instruction).
    ///   The JSON model must be passed back here, to pass onto the next step.
    func run(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback)
}
