//
//  JavaScriptGenerator.swift
//  SwiftScraper
//
//  Created by Ken Ko on 24/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

enum JavaScriptGenerator {

    static func generateScript(moduleName: String, functionName: String, params: [Any] = []) throws -> String {
        guard !params.isEmpty else {
            return "\(moduleName).\(functionName)()"
        }

        let args = try params.map { try stringify(param: $0) }
        let argsJoined = args.joined(separator: ",")
        return "\(moduleName).\(functionName)(\(argsJoined))"
    }

    private static func stringify(param: Any) throws -> String {
        if let string = param as? String {
            return "\"\(string)\""
        } else if let bool = param as? Bool {
            return bool ? "true" : "false"
        } else if param is Int || param is Double {
            return "\(param)"
        } else if param is NSNull {
            return "null"
        } else if JSONSerialization.isValidJSONObject(param),
            let prettyJsonData = try? JSONSerialization.data(withJSONObject: param, options: []) {
            return String(decoding: prettyJsonData, as: UTF8.self)
        }
        throw SwiftScraperError.parameterSerialization
    }
}
