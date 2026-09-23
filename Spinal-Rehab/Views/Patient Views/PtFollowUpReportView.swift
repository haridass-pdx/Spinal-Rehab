//
//  PtFollowUpReportView.swift
//  Spinal-Rehab
//
//  Multi-visit follow-up report: anchors on theRec (the selected test date in
//  TestDateListView), walks back to its nearest prior baseline, and shows one
//  page per test that has both a baseline and at least one follow-up score.
//

import SwiftUI

struct PtFollowUpReportView: View {
    @Binding var patient: PatientData
    @Binding var theRec: TestDateData
    @Environment(\.dismiss) var dismiss
    @State private var html: String = ""
    @State private var isLoading = true
    @State private var hasPages = false
    @State private var engine = PDFReportEngine()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Follow-up Report").font(.title2)
                Spacer()
                Button("Export PDF…") { engine.exportPDF(html, suggestedName: "Follow-up Report") }
                    .disabled(!hasPages)
                Button("Print…") { engine.printHTML(html) }
                    .disabled(!hasPages)
                    .keyboardShortcut("p")
                Button("Close") { dismiss() }
            }
            .padding(10)
            Divider()

            if isLoading {
                ProgressView("Building report…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !hasPages {
                VStack(spacing: 8) {
                    Text("No follow-up data yet")
                        .font(.headline)
                    Text("This patient doesn't have a recorded follow-up score for any goal-tracked test since their baseline visit.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HTMLPreviewView(htmlContent: html)
            }
        }
        .frame(minWidth: 700, minHeight: 800)
        .task(id: theRec.id) {
            isLoading = true
            let pages = await FollowUpReportContext.build(patient: patient, anchorTestDate: theRec)
            hasPages = !pages.isEmpty
            let template = await ReportDataClass.loadFollowUpTemplate()
            html = FollowUpReportRenderer.fullHTML(template: template, pages: pages)
            isLoading = false
        }
    }
}

#Preview {
   // PtFollowUpReportView()
}
