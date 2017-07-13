//
//  StepRunner.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation
import Observable

// MARK: - StepRunnerState

/// Indicates the progress and status of the `StepRunner`.
public enum StepRunnerState {
    /// Not yet started, `run()` has not been called.
    case notStarted

    /// The pipeline is running, and currently executing the step at the index.
    case inProgress(index: Int)

    /// The execution finished successfully.
    case success

    /// The execution failed with the given error.
    case failure(error: Error)
}

public func == (lhs: StepRunnerState, rhs: StepRunnerState) -> Bool {
    switch (lhs, rhs) {
    case (.notStarted, .notStarted): return true
    case (.success, .success): return true
    case (.failure, .failure): return true
    case (.inProgress(let lhsIndex), .inProgress(let rhsIndex)):
        return lhsIndex == rhsIndex
    default: return false
    }
}

public func != (lhs: StepRunnerState, rhs: StepRunnerState) -> Bool {
    return !(lhs == rhs)
}

// MARK: - StepRunner

/// The `StepRunner` is the engine that runs the steps in the pipeline.
///
/// Once initialized, call the `run()` method to execute the steps,
/// and observe the `state` property to be notified of progress and status.
public class StepRunner {

    /// The observable state which indicates the progress and status.
    public private(set) var state: Observable<StepRunnerState> = Observable(.notStarted)

    /// A model dictionary which can be used to pass data from step to step.
    public private(set) var model: JSON = [:]

    private let browser: Browser
    private var steps: [Step]
    private var index = 0

    /// Initializer to create the `StepRunner`.
    ///
    /// - parameter moduleName: The name of the JavaScript module which has your customer functions. 
    ///   By convention, the filename of the JavaScript file is the same as the module name.
    /// - parameter scriptBundle: The bundle from which to load the JavaScript file. Defaults to the main bundle.
    /// - parameter customUserAgent: The custom user agent string (only works for iOS 9+).
    /// - parameter steps: The steps to run in the pipeline.
    public init(
        moduleName: String,
        scriptBundle: Bundle = Bundle.main,
        customUserAgent: String? = nil,
        steps: [Step]) {
        browser = Browser(moduleName: moduleName, scriptBundle: scriptBundle, customUserAgent: customUserAgent)
        self.steps = steps
    }

    /// Execute the steps.
    public func run() {        
        guard index < steps.count else {
            state ^= .failure(error: SwiftScraperError.incorrectStep)
            return
        }
        let stepToExecute = steps[index]
        state ^= .inProgress(index: index)
        stepToExecute.run(with: browser, model: model) { [weak self] result in
            guard let this = self else { return }
            this.model = result.model
            switch result {
            case .finish:
                this.state ^= .success
            case .proceed:
                this.index += 1
                guard this.index < this.steps.count else {
                    this.state ^= .success
                    return
                }
                this.run()
            case .jumpToStep(let nextStep, _):
                this.index = nextStep
                this.run()
            case .failure(let error, _):
                this.state ^= .failure(error: error)
            }
        }
    }

    /// Resets the existing StepRunner and execute the given steps in the existing browser.
    ///
    /// Use this to perform more steps on a StepRunner which has previously finished processing.
    public func run(steps: [Step]) {
        state ^= .notStarted
        self.steps = steps
        index = 0
        run()
    }

    /// Insert the WebView used for scraping at index 0 of the given parent view, using AutoLayout to pin all 4 sides to the parent.
    ///
    /// Useful if the app would like to see the scraping in the foreground.
    public func insertWebViewIntoView(parent: UIView) {
        browser.insertIntoView(parent: parent)
    }
}
