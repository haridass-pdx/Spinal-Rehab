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

/// Renders an HTML document with WebKit and emits it to **both** the printer and a
/// PDF file through a single `NSPrintOperation` pipeline. Using one pipeline for
/// both outputs guarantees the printed page and the saved PDF are laid out and
/// paginated identically — which `WKWebView.createPDF()` does not reliably do for
/// multi-page documents.
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

    /// Print a full HTML document (native print panel, which also offers "Save as PDF").
    func printHTML(_ fullHTML: String) {
        run(html: fullHTML, output: .print)
    }

    /// Export a full HTML document straight to a chosen PDF file (no print panel).
    func exportPDF(_ fullHTML: String, suggestedName: String = "Report") {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(suggestedName).pdf"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.run(html: fullHTML, output: .savePDF(url))
        }
    }

    /// Backward-compatible entry point used by the older demo views: wraps plain
    /// text in a minimal page. Prefer `printHTML`/`exportPDF` with real HTML.
    func processReport(text: String, printImmediately: Bool) {
        let body = text.replacingOccurrences(of: "\n", with: "<br>")
        let html = Self.wrap(body: body, css: Self.plainTextCSS)
        if printImmediately {
            printHTML(html)
        } else {
            exportPDF(html, suggestedName: String(text.prefix(15)).trimmingCharacters(in: .whitespacesAndNewlines))
        }
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

    static let plainTextCSS = """
        @page { size: letter; margin: 0.75in; }
        body { font-family: -apple-system, "Helvetica Neue", sans-serif; font-size: 12pt; line-height: 1.5; color: #111; }
        """

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
        let info = makePrintInfo()

        switch output {
        case .print:
            let op = webView.printOperation(with: info)
            op.showsPrintPanel = true
            op.showsProgressPanel = true
            if let window = NSApp.keyWindow {
                op.runModal(for: window,
                            delegate: self,
                            didRun: #selector(printOperation(_:didRun:contextInfo:)),
                            contextInfo: nil)
            } else {
                op.run()
                cleanup()
            }

        case .savePDF(let url):
            // Print-to-PDF: same pagination as the printer, written silently to disk.
            info.jobDisposition = .save
            info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
            let op = webView.printOperation(with: info)
            op.showsPrintPanel = false
            op.showsProgressPanel = false
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
