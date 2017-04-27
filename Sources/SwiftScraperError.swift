//
//  SwiftScraperError.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

public enum SwiftScraperError: Error, LocalizedError {
    case parameterSerialization
    case parsing
    case contentUnexpected
    case javascriptError(errorMessage: String)
    case navigationFailed
    case incorrectStep

    public var errorDescription: String? {
        switch self {
        case .parameterSerialization: return "Could not serialize the parameters to pass to the script"
        case .parsing: return "Something went wrong when parsing the page"
        case .contentUnexpected: return "Something went wrong, the page contents was not what was expected"
        case .javascriptError(let errorMessage): return "A JavaScript error occurred when trying to process the page: \(errorMessage)"
        case .navigationFailed: return "Something went wrong when navigating to the page"
        case .incorrectStep: return "An incorrect step was specified"
        }
    }
}
