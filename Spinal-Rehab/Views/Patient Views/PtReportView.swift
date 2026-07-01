//
//  PtReportView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//

import SwiftUI

struct PtReportView: View {
    @Binding var theRec: TestDateData
    @Environment(\.dismiss) var dismiss
    @State private var html: String = ""
    @State private var isLoading = true
    @State private var engine = PDFReportEngine()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Performance Report").font(.title2)
                Spacer()
                Button("Export PDF…") { engine.exportPDF(html, suggestedName: "Performance Report") }
                    .disabled(html.isEmpty)
                Button("Print…") { engine.printHTML(html) }
                    .disabled(html.isEmpty)
                    .keyboardShortcut("p")
                Button("Close") { dismiss() }
            }
            .padding(10)
            Divider()

            if isLoading {
                ProgressView("Building report…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HTMLPreviewView(htmlContent: html)
            }
        }
        .frame(minWidth: 700, minHeight: 800)
        .task(id: theRec.id) {
            isLoading = true
            let values = await ReportContext.build(testDate: theRec)
            html = ReportRenderer.fullHTML(values: values)
            isLoading = false
        }
    }
}

#Preview {
   // PtReportView()
}
