//
//  WebView.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//


import SwiftUI
import WebKit

#if os(iOS)
struct CustomWebView: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)

        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsVerticalScrollIndicator = true

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("❌ index.html not found")
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#elseif os(macOS)

struct CustomWebView: NSViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator


        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("❌ index.html not found")
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ HTML loaded successfully")
        }
    }
}

#endif
