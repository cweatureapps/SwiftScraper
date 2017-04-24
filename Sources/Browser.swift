//
//  Browser.swift
//  SwiftScraper
//
//  Created by Ken Ko on 21/04/2017.
//  Copyright © 2017 Ken Ko. All rights reserved.
//

import Foundation
import WebKit

/// Encapsulates the webview and its delegates, providing an closure based API.
public class Browser: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    // MARK: - Constants

    private enum Constants {
        static let messageHandlerName = "responseHandler"
    }

    // MARK: - Properties

    private let moduleName: String
    private (set) public var webView: WKWebView!
    let userContentController = WKUserContentController()
    var navigationCompletion: NavigationCompletion?
    var asyncScriptCompletion: ScriptResponseResultCompletion?

    // MARK: - Setup

    /// Initialize the Browser object.
    ///
    /// - parameter moduleName: The name of the JavaScript module.
    /// - parameter customUserAgent: The custom user agent string (only works for iOS 9+)
    init(moduleName: String, customUserAgent: String? = nil, scriptBundle: Bundle = Bundle.main) {
        self.moduleName = moduleName
        super.init()
        setupWebView(moduleName: moduleName, customUserAgent: customUserAgent, scriptBundle: scriptBundle)
    }

    private func setupWebView(moduleName: String, customUserAgent: String?, scriptBundle: Bundle) {

        let scriptURL = scriptBundle.path(forResource: moduleName, ofType: "js")
        let scriptContent = try! String(contentsOfFile: scriptURL!)  // swiftlint:disable:this force_try
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        userContentController.addUserScript(script)
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

    // MARK: - public API

    /// Insert the WebView at index 0 of the given parent view,
    /// using AutoLayout to pin all 4 sides to the parent.
    public func insertIntoView(parent: UIView) {
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

    func load(path: String, completion: @escaping NavigationCompletion) {
        self.navigationCompletion = completion
        webView.load(URLRequest(url: URL(string: path)!))
    }

    // Run some javascript with error handling and print logging
    func runScript(functionName: String, params: [Any] = [], completion: @escaping ScriptResponseResultCompletion) {
        guard let script = try? JavaScriptGenerator.generateScript(moduleName: moduleName, functionName: functionName, params: params) else {
            completion(.failure(BrowserError.parameterSerialization))
            return
        }
        print("script to run:", script)
        webView.evaluateJavaScript(script) { response, error in
            if let nsError = error as? NSError,
                nsError.domain == WKError.errorDomain,
                nsError.code == WKError.Code.javaScriptExceptionOccurred.rawValue {
                let jsErrorMessage = nsError.userInfo["WKJavaScriptExceptionMessage"] as? String ?? nsError.localizedDescription
                print("javaScriptExceptionOccurred error: \(jsErrorMessage)")
                completion(.failure(BrowserError.javascriptError(errorMessage: jsErrorMessage)))
            } else if let error = error {
                print("javascript error: \(error.localizedDescription)")
                completion(.failure(BrowserError.javascriptError(errorMessage: error.localizedDescription)))
            } else {
                print("javascript response:")
                print(response ?? "(no response)")
                completion(.success(response))
            }
        }
    }

    func runPageChangeScript(functionName: String, params: [Any] = [], completion: @escaping NavigationCompletion) {
        self.navigationCompletion = completion
        runScript(functionName: functionName, params: params) { result in
            if case .failure = result {
                completion(false)
                self.navigationCompletion = nil
            }
        }
    }

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
