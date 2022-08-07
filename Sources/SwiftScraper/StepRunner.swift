//
//  StepRunner.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)
/// Platform depended implementation of view
public typealias PlatformView = UIView
#else
/// Platform depended implementation of view
public typealias PlatformView = NSView
#endif

/// JSON dictionary.
public typealias JSON = [String: Any]

// MARK: - StepRunnerState

/// Indicates the progress and status of the `StepRunner`.
public enum StepRunnerState: Equatable {
    /// Not yet started, `run()` has not been called.
    case notStarted

    /// The pipeline is running, and currently executing the step at the index.
    case inProgress(index: Int)

    /// The execution finished successfully.
    case success

    /// The execution failed with the given error.
    case failure(error: Error)
}

/// Checks equality of the runner state, including index of currently running step
public func == (lhs: StepRunnerState, rhs: StepRunnerState) -> Bool {
    switch (lhs, rhs) {
    case (.notStarted, .notStarted):
        return true
    case (.success, .success):
        return true
    case (.failure, .failure):
        return true
    case let (.inProgress(lhsIndex), .inProgress(rhsIndex)):
        return lhsIndex == rhsIndex
    default:
        return false
    }
}

/// Checks inequality of the runner state, including index of currently running step
public func != (lhs: StepRunnerState, rhs: StepRunnerState) -> Bool {
    !(lhs == rhs)
}

// MARK: - StepRunner

/// The `StepRunner` is the engine that runs the steps in the pipeline.
///
/// Once initialized, call the `run()` method to execute the steps,
/// and observe the `state` property to be notified of progress and status.
public class StepRunner {

    /// The observable state which indicates the progress and status.
    public private(set) var state: StepRunnerState = .notStarted {
        didSet {
            if state != oldValue {
                for observer in stateObservers {
                    observer(state)
                }
            }
            switch state {
            case .success, .failure:
                if let completionHandler = completion {
                    completionHandler()
                    completion = nil
                }
            default:
                break
            }
        }
    }

    /// Callbacks which are called on each state change
    public var stateObservers: [(StepRunnerState) -> Void] = []

    /// A model dictionary which can be used to pass data from step to step.
    public private(set) var model: JSON = [:]

    private let browser: Browser
    private var steps: [Step]
    private var index = 0
    private var completion: (() -> Void)?

    /// Initializer to create the `StepRunner`.
    ///
    /// - parameter moduleName: The name of the JavaScript module which has your customer functions.
    ///   By convention, the filename of the JavaScript file is the same as the module name.
    /// - parameter scriptBundle: The bundle from which to load the JavaScript file. Defaults to the main bundle.
    /// - parameter customUserAgent: The custom user agent string (only works for iOS 9+).
    /// - parameter steps: The steps to run in the pipeline.
    public init( // swiftlint:disable:this function_default_parameter_at_end
        moduleName: String,
        scriptBundle: Bundle = Bundle.main,
        customUserAgent: String? = nil,
        steps: [Step],
        completion: (() -> Void)? = nil
    ) throws {
        browser = try Browser(moduleName: moduleName, scriptBundle: scriptBundle, customUserAgent: customUserAgent)
        self.steps = steps
        self.completion = completion
    }

    /// Execute the steps.
    public func run(completion: (() -> Void)? = nil) {
        if let completion = completion {
            self.completion = completion
        }
        guard index < steps.count else {
            state = .failure(error: SwiftScraperError.incorrectStep)
            return
        }
        let stepToExecute = steps[index]
        state = .inProgress(index: index)
        stepToExecute.run(with: browser, model: model) { [weak self] result in
            guard let this = self else {
                return
            }
            this.model = result.model
            switch result {
            case .finish:
                this.state = .success
            case .proceed:
                this.index += 1
                guard this.index < this.steps.count else {
                    this.state = .success
                    return
                }
                this.run()
            case .jumpToStep(let nextStep, _):
                this.index = nextStep
                this.run()
            case .failure(let error, _):
                this.state = .failure(error: error)
            }
        }
    }

    /// Resets the existing StepRunner and execute the given steps in the existing browser.
    ///
    /// Use this to perform more steps on a StepRunner which has previously finished processing.
    public func run(steps: [Step]) {
        state = .notStarted
        self.steps = steps
        index = 0
        run()
    }

    /// Insert the WebView used for scraping at index 0 of the given parent view, using AutoLayout to pin all 4 sides
    /// of the parent.
    ///
    /// Useful if the app would like to see the scraping in the foreground.
    public func insertWebViewIntoView(parent: PlatformView) {
        browser.insertIntoView(parent: parent)
    }
}
