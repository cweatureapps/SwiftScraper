/**
 * Core JavaScript helper functions for SwiftScraper.
 */
var SwiftScraper = (function() {
    /**
     * Posts a message back to iOS WebView.
     * This is a shortcut for the webkit messageHandlers postMessage function.
     */                
    function postMessage(message) {
        window.webkit.messageHandlers.swiftScraperResponseHandler.postMessage(message);
    }
    return {
        postMessage: postMessage
    };
})();
