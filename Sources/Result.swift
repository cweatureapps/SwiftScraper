//
//  Result.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

public enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}
