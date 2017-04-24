//
//  JavaScriptGenerator.swift
//  SwiftScraper
//
//  Created by Ken Ko on 24/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation

struct JavaScriptGenerator {

    static func generateScript(moduleName: String, functionName: String, params: [Any] = []) -> String? {
        guard !params.isEmpty else {
            return "\(moduleName).\(functionName)()"
        }

        let args = params.flatMap { stringify(param: $0) }
        guard args.count == params.count else { return nil }

        let argsJoined = args.joined(separator: ",")
        return "\(moduleName).\(functionName)(\(argsJoined))"
    }

    private static func stringify(param: Any) -> String? {
        if let s = param as? String {
            return "\"\(s)\""
        } else if let b = param as? Bool {
            return b ? "true" : "false"
        } else if param is Int || param is Double {
            return "\(param)"
        } else if JSONSerialization.isValidJSONObject(param),
            let prettyJsonData = try? JSONSerialization.data(withJSONObject: param, options: []),
            let jsonString = NSString(data: prettyJsonData, encoding: String.Encoding.utf8.rawValue) as? String {
            return jsonString
        }
        return nil
    }
}
