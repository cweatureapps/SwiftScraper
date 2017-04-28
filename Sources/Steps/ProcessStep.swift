//
//  ProcessStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 26/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

// MARK: - Types

/// Handler that allows some custom action to be performed for `ProcessStep`,
/// with the return value used to drive control flow of the steps.
///
/// - parameter model: The model JSON dictionary which can be modified by the step.
/// - returns: The `StepFlowResult` which allows control flow of the steps.
public typealias ProcessStepHandler = (_ model: inout JSON) -> StepFlowResult


// MARK: - ProcessStep

/// Step that performs some processing, can update the model dictionary, 
/// and can be used to drive control flow of the steps.
public class ProcessStep: Step {

    private var handler: ProcessStepHandler

    /// Initializer.
    ///
    /// - parameter handler: The action to perform in this step.
    public init(handler: @escaping ProcessStepHandler) {
        self.handler = handler
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback) {
        var modelCopy = model
        let result = handler(&modelCopy)
        completion(result.convertToStepCompletionResult(with: modelCopy))
    }
}

