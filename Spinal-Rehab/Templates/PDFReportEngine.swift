//
//  PDFReportEngine.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//


import Foundation
import WebKit
import AppKit
import UniformTypeIdentifiers

/// Loads an HTML document into a headless `WKWebView` and, once loaded, prints or
/// exports it through `NSPrintOperation`.
///
/// The operation is run as a **sheet** on the key window (`runModal(for:)`), not
/// app-modal (`run()`). This matters: WebKit only paints into the print context when
/// the operation is driven through a window's sheet run loop — `run()` on an
/// unhosted web view spools blank pages. Under the debugger this path may pause once
/// on a benign WebKit print assertion (Resume continues); it does not occur in a
/// normal, non-debug run.
@MainActor
final class PDFReportEngine: NSObject {

    enum Output {
        case print
        case savePDF(URL)
    }

    // Retained while the headless web view loads and prints; cleared on completion.
    private var webView: WKWebView?
    private var pending: Output?

    // MARK: - Public API

    func printHTML(_ fullHTML: String) {
        run(html: fullHTML, output: .print)
    }

    func exportPDF(_ fullHTML: String, suggestedName: String = "Report") {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(suggestedName).pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        run(html: fullHTML, output: .savePDF(url))
    }

    // MARK: - HTML document assembly

    /// Wrap body HTML in a print-ready document. Store only the body (with `{tokens}`)
    /// in the DB; the CSS wrapper lives here so CSS braces never reach the token parser.
    static func wrap(body: String, css: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"><style>\(css)</style></head>
        <body>\(body)</body>
        </html>
        """
    }

    // MARK: - Core pipeline

    private func run(html: String, output: Output) {
        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 792)) // letter, points
        wv.navigationDelegate = self
        webView = wv
        pending = output
        wv.loadHTMLString(html, baseURL: nil)
    }

    private func makePrintInfo() -> NSPrintInfo {
        let info = NSPrintInfo()
        info.paperSize = NSSize(width: 612, height: 792) // US Letter
        info.leftMargin = 54; info.rightMargin = 54      // 0.75in
        info.topMargin = 54;  info.bottomMargin = 54
        info.horizontalPagination = .automatic
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = false
        info.isVerticallyCentered = false
        return info
    }

    private func cleanup() {
        webView = nil
        pending = nil
    }
}

// MARK: - WKNavigationDelegate
extension PDFReportEngine: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let output = pending else { return }
        pending = nil // fire once

        let info = makePrintInfo()
        let op: NSPrintOperation
        switch output {
        case .print:
            op = webView.printOperation(with: info)
            op.showsPrintPanel = true
            op.showsProgressPanel = true
        case .savePDF(let url):
            info.jobDisposition = .save
            info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
            op = webView.printOperation(with: info)
            op.showsPrintPanel = false
            op.showsProgressPanel = false
        }

        // Sheet-drive the operation so WebKit paints into the print context.
        if let window = NSApp.keyWindow {
            op.runModal(for: window,
                        delegate: self,
                        didRun: #selector(printOperation(_:didRun:contextInfo:)),
                        contextInfo: nil)
        } else {
            op.run()
            cleanup()
        }
    }

    @objc private func printOperation(_ op: NSPrintOperation,
                                      didRun success: Bool,
                                      contextInfo: UnsafeMutableRawPointer?) {
        cleanup()
    }
}
