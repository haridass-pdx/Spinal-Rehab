//
//  MacReportTemplateEditor.swift
//  Spinal-Rehab
//
//  Edits report body templates stored in reports.thetext: the single-visit
//  Performance Report (row ReportDataClass.performanceReportID) and the
//  multi-visit Follow-up Report (row ReportDataClass.followUpReportID). The
//  right pane renders the edited text with each report's own sample values,
//  so token typos show up before the template is saved.
//

import SwiftUI

private enum ReportKind: String, CaseIterable, Identifiable {
    case performance = "Performance Report"
    case followUp = "Follow-up Report"
    var id: String { rawValue }
}

struct MacReportTemplateEditor: View {
    @State private var kind: ReportKind = .performance
    @State private var templateText: String = ""
    @State private var savedText: String = ""
    @State private var previewHTML: String = ""
    @State private var isLoading = true
    @State private var statusMessage: String = ""

    @FocusState private var isEditorFocused: Bool

    /// The known-token dict for whichever report is being edited. Both
    /// reports' sample-value sets are keyed the same way per page, so the
    /// first page's keys are the full set of tokens the renderer supplies.
    private var knownTokens: [String: String] {
        switch kind {
        case .performance: return SpinalReportSlice.sampleValues
        case .followUp: return FollowUpReportRenderer.sampleValues.first ?? [:]
        }
    }

    /// Tokens typed in the template that the report code doesn't supply.
    /// Saving is blocked while any exist, so a typo like {physican_name}
    /// can't end up printed in a patient report as "{Missing: ...}".
    private var unknownTokens: [String] {
        let known = knownTokens
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
                Picker("", selection: $kind) {
                    ForEach(ReportKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(width: 200)
                Spacer()
                Button("Restore Default") { templateText = defaultTemplate }
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
            await load()
        }
        .onChange(of: kind) { _, _ in
            Task {
                isLoading = true
                await load()
            }
        }
        .task(id: templateText) {
            // Debounce so the web view isn't reloaded on every keystroke.
            try? await Task.sleep(for: .milliseconds(400))
            if Task.isCancelled { return }
            previewHTML = renderPreview()
        }
    }

    private var defaultTemplate: String {
        switch kind {
        case .performance: return ReportRenderer.bodyTemplate
        case .followUp: return FollowUpReportRenderer.bodyTemplate
        }
    }

    private func renderPreview() -> String {
        switch kind {
        case .performance:
            return ReportRenderer.fullHTML(template: templateText, values: SpinalReportSlice.sampleValues)
        case .followUp:
            return FollowUpReportRenderer.fullHTML(template: templateText, pages: FollowUpReportRenderer.sampleValues)
        }
    }

    private func load() async {
        switch kind {
        case .performance: templateText = await ReportDataClass.loadBodyTemplate()
        case .followUp: templateText = await ReportDataClass.loadFollowUpTemplate()
        }
        savedText = templateText
        isLoading = false
        isEditorFocused = true
    }

    private func save() async {
        let reportID = kind == .performance ? ReportDataClass.performanceReportID : ReportDataClass.followUpReportID
        let ok = await ReportDataClass.saveReportData(reportID: reportID, text: templateText)
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
