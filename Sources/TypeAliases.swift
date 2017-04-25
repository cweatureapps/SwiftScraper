//
//  TypeAliases.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

public typealias JSON = [String: Any]

/// Callback to indicate success or failure of each step's run.
///
/// - parameter result: Result indicating success or failure.
///   If success, the JSON model must be returned to pass onto the next step.
public typealias StepCompletion = (_ result: Result<JSON, SwiftScraperError>) -> Void

public typealias NavigationCompletion = (Bool) -> Void
public typealias ScriptResponseCompletion = (Any?) -> Void
public typealias ScriptResponseResultCompletion = (Result<Any?, SwiftScraperError>) -> Void

/// Callback invoked when a `ScriptStep` or `AsyncScriptStep` is finished.
///
/// - parameter response: Data returned from JavaScript.
/// - parameter model: The model JSON dictionary which can be modified by the step.
public typealias ScriptStepHandler = (_ response: Any?, _ model: inout JSON) -> Void
