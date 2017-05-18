//
//  AdvancedTutorialViewController.swift
//  SwiftScraperExample
//
//  Created by Ken Ko on 18/5/17.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import UIKit

import SwiftScraper

/// This example does a google image search, and then keeps scrolling down to the bottom,
/// until there are no more new images loaded.
class AdvancedTutorialViewController: UIViewController {

    var stepRunner: StepRunner!

    override func viewDidLoad() {
        super.viewDidLoad()

        let step1 = OpenPageStep(path: "https://www.google.com.au/search?tbm=isch")

        let step2 = PageChangeStep(
            functionName: "performSearch",
            params: "ankylosaurus")

        let step3 = AsyncScriptStep(functionName: "scrollAndCountImages") { response, model in
            if let json = response as? JSON {
                if let first = json["first"], let second = json["second"] {
                    print("first: ", first, "second: ", second)

                    // Save the data to the model dictionary
                    model["first"] = first
                    model["second"] = second
                }
            }
            return .proceed
        }

        // Keep looping back to `step3` until the before count and after count are the same
        let conditionStep = ProcessStep { model in
            if let first = model["first"] as? Int,
                let second = model["second"] as? Int,
                first == second {
                return .proceed
            } else {
                return .jumpToStep(2) // This is a zero-based index, i.e. step3
            }
        }

        stepRunner = StepRunner(moduleName: "GoogleSearch", steps: [step1, step2, step3, conditionStep])
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
