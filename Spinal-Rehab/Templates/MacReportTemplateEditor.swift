//
//  MacReportTemplateEditor.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//
//  Edits the performance-report body template stored in reports.thetext
//  (row ReportDataClass.performanceReportID). The right pane renders the
//  edited text through ReportRenderer with the same sample values as
//  SpinalReportSlice, so token typos show up before the template is saved.
//

import SwiftUI

struct MacReportTemplateEditor: View {
    @State private var templateText: String = ""
    @State private var savedText: String = ""
    @State private var previewHTML: String = ""
    @State private var isLoading = true
    @State private var statusMessage: String = ""

    @FocusState private var isEditorFocused: Bool

    /// Tokens typed in the template that the report code doesn't supply.
    /// Saving is blocked while any exist, so a typo like {physican_name}
    /// can't end up printed in a patient report as "{Missing: ...}".
    private var unknownTokens: [String] {
        let known = SpinalReportSlice.sampleValues
        let tokens = ParsedTemplate(rawText: templateText).segments.compactMap { segment in
            if case .token(let key) = segment { return key }
            return nil
        }
        return Array(Set(tokens.filter { known[$0] == nil })).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Report Template").font(.title2)
                Spacer()
                Button("Restore Default") { templateText = ReportRenderer.bodyTemplate }
                Button("Revert") { templateText = savedText }
                    .disabled(templateText == savedText)
                Button("Save") { Task { await save() } }
                    .disabled(templateText == savedText || !unknownTokens.isEmpty)
                    .keyboardShortcut("s")
            }
            .padding(10)

            if !unknownTokens.isEmpty {
                Text("Unknown token\(unknownTokens.count == 1 ? "" : "s"): "
                     + unknownTokens.map { "{\($0)}" }.joined(separator: ", ")
                     + " — fix before saving")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            } else if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            }
            Divider()

            if isLoading {
                ProgressView("Loading template…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    TextEditor(text: $templateText)
                        .font(.system(.body, design: .monospaced))
                        .focused($isEditorFocused)
                        .padding(4)
                        .frame(minWidth: 300, maxWidth: .infinity)

                    HTMLPreviewView(htmlContent: previewHTML)
                        .frame(minWidth: 350, maxWidth: .infinity)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            templateText = await ReportDataClass.loadBodyTemplate()
            savedText = templateText
            isLoading = false
            isEditorFocused = true
        }
        .task(id: templateText) {
            // Debounce so the web view isn't reloaded on every keystroke.
            try? await Task.sleep(for: .milliseconds(400))
            if Task.isCancelled { return }
            previewHTML = ReportRenderer.fullHTML(template: templateText,
                                                  values: SpinalReportSlice.sampleValues)
        }
    }

    private func save() async {
        let ok = await ReportDataClass.saveReportData(
            reportID: ReportDataClass.performanceReportID, text: templateText)
        if ok {
            savedText = templateText
            statusMessage = "Saved"
        } else {
            statusMessage = "Save failed — check the database connection"
        }
    }
}

#Preview {
    MacReportTemplateEditor()
}
