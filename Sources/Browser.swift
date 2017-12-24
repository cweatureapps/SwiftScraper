//
//  Browser.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation
import WebKit

// MARK: - Types

/// The result of the browser navigation.
typealias NavigationResult = Result<Void, SwiftScraperError>

/// Invoked when the page navigation has completed or failed.
typealias NavigationCallback = (_ result: NavigationResult) -> Void

/// The result of some JavaScript execution.
///
/// If successful, it contains the response from the JavaScript;
/// If it failed, it contains the error.
typealias ScriptResponseResult = Result<Any?, SwiftScraperError>

/// Invoked when the asynchronous call to some JavaScript is completed, containing the response or error.
typealias ScriptResponseResultCallback = (_ result: ScriptResponseResult) -> Void

// MARK: - Browser

/// The browser used to perform the web scraping.
///
/// This class encapsulates the webview and its delegates, providing an closure based API.
public class Browser: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    // MARK: - Constants

    private enum Constants {
        static let coreScript = "SwiftScraper"
        static let messageHandlerName = "swiftScraperResponseHandler"
    }

    // MARK: - Properties

    private let moduleName: String
    private (set) public var webView: WKWebView!
    private let userContentController = WKUserContentController()
    private var navigationCallback: NavigationCallback?
    private var asyncScriptCallback: ScriptResponseResultCallback?

    // MARK: - Setup

    /// Initialize the Browser object.
    ///
    /// - parameter moduleName: The name of the JavaScript module. By convention, the filename of the JavaScript file is the same as the module name.
    /// - parameter scriptBundle: The bundle from which to load the JavaScript file. Defaults to the main bundle.
    /// - parameter customUserAgent: The custom user agent string (only works for iOS 9+).
    init(moduleName: String, scriptBundle: Bundle = Bundle.main, customUserAgent: String? = nil) {
        self.moduleName = moduleName
        super.init()
        setupWebView(moduleName: moduleName, customUserAgent: customUserAgent, scriptBundle: scriptBundle)
    }

    private func setupWebView(moduleName: String, customUserAgent: String?, scriptBundle: Bundle) {

        let coreScriptURL = moduleResourceBundle().path(forResource: Constants.coreScript, ofType: "js")
        let coreScriptContent = try! String(contentsOfFile: coreScriptURL!)
        let coreScript = WKUserScript(source: coreScriptContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(coreScript)

        let moduleScriptURL = scriptBundle.path(forResource: moduleName, ofType: "js")
        let moduleScriptContent = try! String(contentsOfFile: moduleScriptURL!)  // TODO: prevent force try, propagate error
        let moduleScript = WKUserScript(source: moduleScriptContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(moduleScript)

        userContentController.add(self, name: Constants.messageHandlerName)

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController

        webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        if #available(iOS 9.0, *) {
            webView.customUserAgent = customUserAgent
        }
    }

    /// Returns the resource bundle for this Pod where all the resources are kept, 
    /// or defaulting to the framework module bundle (e.g. when running unit tests).
    private func moduleResourceBundle() -> Bundle {
        let moduleBundle = Bundle(for: Browser.self)
        guard let resourcesBundleURL = moduleBundle.url(forResource: "SwiftScraper", withExtension: ".bundle"),
            let resourcesBundle = Bundle(url: resourcesBundleURL) else {
            return moduleBundle
        }
        return resourcesBundle
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinishNavigation was called")
        callNavigationCompletion(result: .success(()))
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation")
        let navigationError = SwiftScraperError.navigationFailed(error: error)
        callNavigationCompletion(result: .failure(navigationError))
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFailNavigation was called")
        let nsError = error as NSError
        if nsError.domain == "NSURLErrorDomain" && nsError.code == NSURLErrorCancelled {
            return
        }
        let navigationError = SwiftScraperError.navigationFailed(error: error)
        callNavigationCompletion(result: .failure(navigationError))
    }

    private func callNavigationCompletion(result: NavigationResult) {
        guard let navigationCompletion = self.navigationCallback else { return }
        // Make a local copy of closure before setting to nil, to due async nature of this,
        // there is a timing issue if simply setting to nil after calling the completion.
        // This is because the completion is the code that triggers the next step.
        self.navigationCallback = nil
        navigationCompletion(result)
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKScriptMessage didReceiveMessage")
        guard message.name == Constants.messageHandlerName else {
            print("Ignoring message with name of \(message.name)")
            return
        }
        asyncScriptCallback?(.success(message.body))
    }

    // MARK: - API

    /// Insert the WebView at index 0 of the given parent view,
    /// using AutoLayout to pin all 4 sides to the parent.
    func insertIntoView(parent: UIView) {
        parent.insertSubview(webView, at: 0)
        webView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 9.0, *) {
            webView.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
            webView.leadingAnchor.constraint(equalTo: parent.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: parent.trailingAnchor).isActive = true
        } else {
            NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: parent, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: parent, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: parent, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: parent, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        }
    }

    /// Loads a page with the given path into the WebView.
    func load(path: String, completion: @escaping NavigationCallback) {
        self.navigationCallback = completion
        webView.load(URLRequest(url: URL(string: path)!))
    }

    /// Run some JavaScript with error handling and logging.
    func runScript(functionName: String, params: [Any] = [], completion: @escaping ScriptResponseResultCallback) {
        guard let script = try? JavaScriptGenerator.generateScript(moduleName: moduleName, functionName: functionName, params: params) else {
            completion(.failure(SwiftScraperError.parameterSerialization))
            return
        }
        print("script to run:", script)
        webView.evaluateJavaScript(script) { response, error in
            if let nsError = error as NSError?,
                nsError.domain == WKError.errorDomain,
                nsError.code == WKError.Code.javaScriptExceptionOccurred.rawValue {
                let jsErrorMessage = nsError.userInfo["WKJavaScriptExceptionMessage"] as? String ?? nsError.localizedDescription
                print("javaScriptExceptionOccurred error: \(jsErrorMessage)")
                completion(.failure(SwiftScraperError.javascriptError(errorMessage: jsErrorMessage)))
            } else if let error = error {
                print("javascript error: \(error.localizedDescription)")
                completion(.failure(SwiftScraperError.javascriptError(errorMessage: error.localizedDescription)))
            } else {
                print("javascript response:")
                print(response ?? "(no response)")
                completion(.success(response))
            }
        }
    }

    /// Run some JavaScript that results in a page being loaded (i.e. navigation happens).
    func runPageChangeScript(functionName: String, params: [Any] = [], completion: @escaping NavigationCallback) {
        self.navigationCallback = completion
        runScript(functionName: functionName, params: params) { result in
            if case .failure(let error) = result {
                completion(.failure(error))
                self.navigationCallback = nil
            }
        }
    }

    /// Run some JavaScript asynchronously, the completion being called when a script message is received from the JavaScript.
    func runAsyncScript(functionName: String, params: [Any] = [], completion: @escaping ScriptResponseResultCallback) {
        self.asyncScriptCallback = completion
        runScript(functionName: functionName, params: params) { result in
            if case .failure = result {
                completion(result)
                self.asyncScriptCallback = nil
            }
        }
    }
}
