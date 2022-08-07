//
//  StepCompletionCallback.swift
//  SwiftScraper
//
//  Created by Ken Ko on 27/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Result that indicates what to do next (i.e. control flow instruction)
/// when a step's `run` method is complete.
/// This also contains the model which is passed betweeen the steps.
public enum StepCompletionResult {
    /// Proceed to the next step.
    case proceed(JSON)

    /// Jump to the step at the given index in the `Step` array and continue execution from there.
    case jumpToStep(Int, JSON)

    /// StepRunnerState stops executing, and finishes immediately with a state of `StepRunnerState.success`.
    case finish(JSON)

    /// StepRunnerState stops executing, and finishes immediately with a state of `StepRunnerState.failure`.
    case failure(Error, JSON)

    /// The associated JSON model for the result.
    var model: JSON {
        switch self {
        case .proceed(let model): return model
        case .finish(let model): return model
        case .jumpToStep(_, let model): return model
        case .failure(_, let model): return model
        }
    }
}

/// Callback that should be invoked when the step's `run` method is complete,
/// and can provides instruction on what to do next (e.g. proceed or fail).
///
/// - parameter result: Result indicating what to do next (i.e. control flow instruction).
///   The JSON model must be provided to pass onto the next step.
public typealias StepCompletionCallback = (_ result: StepCompletionResult) -> Void
