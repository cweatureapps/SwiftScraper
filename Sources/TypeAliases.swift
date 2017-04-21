//
//  Types.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

public typealias JSON = [String: Any]

public typealias StepCompletion = (Bool) -> Void
public typealias NavigationCompletion = (Bool) -> Void
public typealias ScriptResponseCompletion = (Any?) -> Void
public typealias ScriptResponseResultCompletion = (Result<Any?, BrowserError>) -> Void
