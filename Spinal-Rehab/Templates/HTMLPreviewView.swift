//
//  HTMLPreviewView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//


import SwiftUI
import WebKit

struct HTMLPreviewView: NSViewRepresentable {
    let htmlContent: String
    /// Called once with the underlying web view so the parent can print/export it.
    var onMakeWebView: ((WKWebView) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loadedHTML: String?
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground") // match app theme background
        if let onMakeWebView {
            // Defer out of the view-update cycle to avoid mutating parent state mid-update.
            DispatchQueue.main.async { onMakeWebView(webView) }
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Load the full document as-is; its CSS covers both screen and @page print.
        guard context.coordinator.loadedHTML != htmlContent else { return }
        context.coordinator.loadedHTML = htmlContent
        nsView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
