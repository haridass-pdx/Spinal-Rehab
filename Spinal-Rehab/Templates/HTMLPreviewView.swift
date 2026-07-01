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
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground") // Matches your app theme background
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Inject a basic font layout just for the on-screen preview bounds
        let systemStyledHTML = """
        <style>
            body { font-family: -apple-system; font-size: 13px; color: currentColor; }
            table { width: 100%; border-collapse: collapse; margin: 12px 0; }
            th { background: rgba(0,0,0,0.05); text-align: left; padding: 6px; border-bottom: 2px solid rgba(0,0,0,0.1); }
            td { padding: 6px; border-bottom: 1px solid rgba(0,0,0,0.05); }
        </style>
        \(htmlContent)
        """
        nsView.loadHTMLString(systemStyledHTML, baseURL: nil)
    }
}
