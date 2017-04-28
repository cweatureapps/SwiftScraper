//
//  StepFlowResult.swift
//  SwiftScraper
//
//  Created by Ken Ko on 28/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Result which defines control flow of the steps.
public enum StepFlowResult {
    /// Proceed to the next step.
    case proceed

    /// Jump to the step at the given index in the `Step` array and continue execution from there.
    case jumpToStep(Int)

    /// StepRunnerState stops executing, and finishes immediately with a state of `StepRunnerState.success`.
    case finish

    /// StepRunnerState stops executing, and finishes immediately with a state of `StepRunnerState.failure`.
    case failure(Error)

    /// Converts to a StepCompletionResult.
    func convertToStepCompletionResult(with model: JSON) -> StepCompletionResult {
        switch self {
        case .proceed:
            return .proceed(model)
        case .finish:
            return .finish(model)
        case .jumpToStep(let step):
            return .jumpToStep(step, model)
        case .failure(let error):
            return .failure(error, model)
        }
    }
}
