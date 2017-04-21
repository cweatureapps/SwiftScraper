//
//  StepRunner.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation
import Observable

public enum StepRunnerState {
    case notStarted
    case inProgress(index: Int)
    case success
    case failure
}

public class StepRunner {
    public var state: Observable<StepRunnerState> = Observable(.notStarted)
    public let browser: Browser
    private var steps: [Step]
    private var index = 0

    init(
        moduleName: String,
        customUserAgent: String? = nil,
        steps: [Step]) {
        browser = Browser(moduleName: moduleName, customUserAgent: customUserAgent)
        self.steps = steps
    }

    public func run() {
        guard let firstStep = steps.first else {
            state ^= .success
            return
        }
        state ^= .inProgress(index: index)
        firstStep.run(with: browser) { [weak self] success in
            guard let this = self else { return }
            if success {
                _ = this.steps.removeFirst()
                this.index += 1
                this.run()
            } else {
                this.state ^= .failure
            }
        }
    }
    
}
