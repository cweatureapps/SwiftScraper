//
//  Step.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

public protocol Step {
    func run(with webViewEngine: Browser, completion: @escaping StepCompletion)
}
