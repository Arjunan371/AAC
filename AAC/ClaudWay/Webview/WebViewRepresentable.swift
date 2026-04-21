//
//  WebViewRepresentable.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import SwiftUI
import WebKit

#if os(iOS)
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
#endif

struct WebViewRepresentable: PlatformViewRepresentable {
    
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        createWebView(context: context)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
    #elseif os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        createWebView(context: context)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}
    #endif

    private func createWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "iosListener")
        config.userContentController = controller
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        if let fileURL = Bundle.main.url(forResource: "webIndex", withExtension: "html") {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
}

// MARK: - Coordinator

class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    // MARK: Navigation control
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            print("👉 Navigating:", url.absoluteString)

            if url.scheme == "myapp" {
                handleCustomURL(url)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    // MARK: JS → Swift
    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {

        guard message.name == "iosListener" else { return }

        print("📩 JS:", message.body)

        if let dict = message.body as? [String: Any],
           let action = dict["action"] as? String {

            handleWebAction(action: action, data: dict)
        }
    }

    // MARK: Actions

    private func handleCustomURL(_ url: URL) {
        print("🔗 Custom URL:", url)
    }

    private func handleWebAction(action: String, data: [String: Any]) {
        switch action {
        case "startExam":
            print("🚀 Start Exam")
            NotificationCenter.default.post(name: .startExam, object: nil, userInfo: ["status": true])
        case "submitExam":
            print("📤 Submit Exam")
            NotificationCenter.default.post(name: .submitExam, object: nil, userInfo: ["status": true])

        case "openCamera":
            print("📷 Open Camera")

        default:
            print("⚠️ Unknown action:", action)
        }
    }
}
