@testable import SwiftScraper
import XCTest

final class SwiftScraperErrorTests: XCTestCase {

    func testDownloadErrorString() {
         XCTAssertEqual(
            "\(SwiftScraperError.parameterSerialization.localizedDescription)",
            "Could not serialize the parameters to pass to the script"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.contentUnexpected.localizedDescription)",
            "Something went wrong, the page contents was not what was expected"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.javascriptError(errorMessage: "message1").localizedDescription)",
            "A JavaScript error occurred: message1"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.navigationFailed(error: SwiftScraperError.timeout).localizedDescription)",
            "Something went wrong when navigating to the page"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.incorrectStep.localizedDescription)",
            "An incorrect step was specified"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.timeout.localizedDescription)",
            "Timeout occurred while waiting for a step to complete"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.commonScriptNotFound.localizedDescription)",
            "Could not load SwiftScraper.js"
        )
         XCTAssertEqual(
            "\(SwiftScraperError.scriptNotFound(name: "name1").localizedDescription)",
            "Could not load name1"
        )
    }

}
