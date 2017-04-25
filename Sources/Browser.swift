//
//  Browser.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation
import WebKit

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
    private var navigationCompletion: NavigationCompletion?
    private var asyncScriptCompletion: ScriptResponseResultCompletion?

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
        callNavigationCompletion(true)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation")
        callNavigationCompletion(false)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFailNavigation was called")
        callNavigationCompletion(false)
    }

    private func callNavigationCompletion(_ success: Bool) {
        guard let navigationCompletion = self.navigationCompletion else { return }
        // Make a local copy of closure before setting to nil, to due async nature of this,
        // there is a timing issue if simply setting to nil after calling the completion.
        // This is because the completion is the code that triggers the next step.
        self.navigationCompletion = nil
        navigationCompletion(success)
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKScriptMessage didReceiveMessage")
        guard message.name == Constants.messageHandlerName else {
            print("Ignoring message with name of \(message.name)")
            return
        }
        asyncScriptCompletion?(.success(message.body))
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
    func load(path: String, completion: @escaping NavigationCompletion) {
        self.navigationCompletion = completion
        webView.load(URLRequest(url: URL(string: path)!))
    }

    /// Run some JavaScript with error handling and logging.
    func runScript(functionName: String, params: [Any] = [], completion: @escaping ScriptResponseResultCompletion) {
        guard let script = try? JavaScriptGenerator.generateScript(moduleName: moduleName, functionName: functionName, params: params) else {
            completion(.failure(SwiftScraperError.parameterSerialization))
            return
        }
        print("script to run:", script)
        webView.evaluateJavaScript(script) { response, error in
            if let nsError = error as? NSError,
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
    func runPageChangeScript(functionName: String, params: [Any] = [], completion: @escaping NavigationCompletion) {
        self.navigationCompletion = completion
        runScript(functionName: functionName, params: params) { result in
            if case .failure = result {
                completion(false)
                self.navigationCompletion = nil
            }
        }
    }

    /// Run some JavaScript asynchronously, the completion being called when a script message is received from the JavaScript.
    func runAsyncScript(functionName: String, params: [Any] = [], completion: @escaping ScriptResponseResultCompletion) {
        self.asyncScriptCompletion = completion
        runScript(functionName: functionName, params: params) { result in
            if case .failure = result {
                completion(result)
                self.asyncScriptCompletion = nil
            }
        }
    }
}