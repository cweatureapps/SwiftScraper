//
//  TutorialViewController.swift
//  SwiftScraperExample
//
//  Created by Ken Ko on 18/5/17.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import UIKit

import SwiftScraper

/// This example performs a search on Google, and prints the results.
class TutorialViewController: UIViewController {
    var stepRunner: StepRunner!

    override func viewDidLoad() {
        super.viewDidLoad()

        let step1 = OpenPageStep(
            path: "https://www.google.com",
            assertionName: "assertGoogleTitle")

        let step2 = PageChangeStep(
            functionName: "performSearch",
            params: "SwiftScraper iOS",
            assertionName: "assertSearchResultTitle")

        let step3 = ScriptStep(functionName: "getSearchResults") { response, _ in
            if let responseArray = response as? [JSON] {
                responseArray.forEach { json in
                    if let text = json["text"], let href = json["href"] {
                        print(text, "(", href, ")")
                    }
                }
            }
            return .proceed
        }

        stepRunner = StepRunner(moduleName: "GoogleSearch", steps: [step1, step2, step3])
        stepRunner.insertWebViewIntoView(parent: view)
        stepRunner.state.afterChange.add { change in
            print("-----", change.newValue, "-----")
            switch change.newValue {
            case .inProgress(let index):
                print("About to run step at index", index)
            case .failure(let error):
                print("Failed: ", error.localizedDescription)
            case .success:
                print("Finished successfully")
            default:
                break
            }
        }
        stepRunner.run()
    }

}

