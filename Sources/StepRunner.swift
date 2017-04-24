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

public enum StepRunnerState {
    case notStarted
    case inProgress(index: Int)
    case success
    case failure
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

public class StepRunner {
    public var state: Observable<StepRunnerState> = Observable(.notStarted)
    public let browser: Browser
    public private(set) var model: JSON = [:]
    private var steps: [Step]
    private var index = 0

    public init(
        moduleName: String,
        customUserAgent: String? = nil,
        scriptBundle: Bundle = Bundle.main,
        steps: [Step]) {
        browser = Browser(moduleName: moduleName, customUserAgent: customUserAgent, scriptBundle: scriptBundle)
        self.steps = steps
    }

    public func run() {
        guard let firstStep = steps.first else {
            state ^= .success
            return
        }
        state ^= .inProgress(index: index)
        firstStep.run(with: browser, model: model) { [weak self] result in
            guard let this = self else { return }
            switch result {
            case .success(let model):
                _ = this.steps.removeFirst()
                this.index += 1
                this.model = model
                this.run()
            case .failure:
                this.state ^= .failure
            }
        }
    }

}
