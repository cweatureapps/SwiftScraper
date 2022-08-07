//
//  WaitStep.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

/// Step that waits for a fixed number of seconds.
public class WaitStep: Step {

    private var waitTimeInSeconds: TimeInterval

    /// Initializer.
    ///
    /// - parameter waitTimeInSeconds: The number of seconds to wait before proceeding to the next step
    public init(waitTimeInSeconds: TimeInterval) {
        self.waitTimeInSeconds = waitTimeInSeconds
    }

    public func run(with browser: Browser, model: JSON, completion: @escaping StepCompletionCallback) {
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTimeInSeconds) {
            completion(.proceed(model))
        }
    }
}

