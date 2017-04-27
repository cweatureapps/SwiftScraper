//
//  ProcessStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 26/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

// MARK: - Types

/// The return result for `ProcessStepHandler`, which allows control flow of the steps.
public enum ProcessStepResult {
    /// Proceed to the next step.
    case proceed

    /// Jump to the step at the given index in the `Step` array and continue execution from there.
    case jumpToStep(Int)

    /// StepRunnerState stops executing, and finishes immediately with a state of `StepRunnerState.success`.
    case finish

    /// StepRunnerState stops executing, and finishes immediately with a state of `StepRunnerState.failure`.
    case failure(Error)
}

/// Handler that allows some custom action to be performed for `ProcessStep`,
/// with the return value used to drive control flow of the steps.
///
/// - parameter model: The model JSON dictionary which can be modified by the step.
/// - returns: The `ProcessStepResult` which allows control flow of the steps.
public typealias ProcessStepHandler = (_ model: inout JSON) -> ProcessStepResult


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
        switch result {
        case .proceed:
            completion(.proceed(modelCopy))
        case .finish:
            completion(.finish(modelCopy))
        case .jumpToStep(let step):
            completion(.jumpToStep(step, modelCopy))
        case .failure(let error):
            completion(.failure(error, modelCopy))
        }
    }
}

