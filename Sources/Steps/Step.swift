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
/// proceeding to the next step if the `StepCompletion` is successful.
public protocol Step {

    /// Execute the step.
    ///
    /// - parameter browser: The `Browser` used for web scraping.
    /// - parameter model: A JSON model that allows data to be passed from step to step in the pipeline.
    /// - parameter completion: The completion called to indicate success or failure.
    ///   If successful, the JSON model must be returned to pass onto the next step.
    func run(with browser: Browser, model: JSON, completion: @escaping StepCompletion)
}
