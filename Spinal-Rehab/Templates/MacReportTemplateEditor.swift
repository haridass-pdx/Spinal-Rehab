//
//  MacReportTemplateEditor.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//


import SwiftUI

// 1. Core Template Engine
extension String {
    func resolveTemplate(with values: [String: String]) -> String {
        var resolved = self
        for (key, value) in values {
            resolved = resolved.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return resolved
    }
}

struct MacReportTemplateEditor: View {
    // Simulated database record from Postgres
    @State private var dbTemplateText: String = """
    REPORT SUMMARY
    ---------------------------
    Client Name: {client_name}
    Project Status: {status}
    
    Notes:
    {notes}
    """
    
    // Live app variables to inject into the template
    @State private var clientName: String = "Acme Corp"
    @State private var currentStatus: String = "In Progress"
    @State private var staffNotes: String = "Initial milestones met on schedule."
    
    @FocusState private var isEditorFocused: Bool

    // 2. Computed property for real-time resolution
    var previewOutput: String {
        let dictionary = [
            "client_name": clientName,
            "status": currentStatus,
            "notes": staffNotes
        ]
        return dbTemplateText.resolveTemplate(with: dictionary)
    }

    var body: some View {
        HSplitView { // Native macOS resizable split view
            // Left Side: Template Editor
            VStack(alignment: .leading, spacing: 10) {
                Text("Database Template Editor")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $dbTemplateText)
                    .font(.system(.body, design: .monospaced))
                    .focused($isEditorFocused)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isEditorFocused ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding()
            .frame(minWidth: 300, maxWidth: .infinity)

            // Right Side: Context Inputs & Live Preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Live Preview & Variables")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Variable Inputs
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Client:")
                        TextField("Enter client name", text: $clientName)
                    }
                    GridRow {
                        Text("Status:")
                        TextField("Enter status", text: $currentStatus)
                    }
                    GridRow {
                        Text("Notes:")
                        TextField("Enter notes", text: $staffNotes)
                    }
                }
                .textFieldStyle(.roundedBorder)
                
                Divider()
                
                // Rendered Output Block
                ScrollView {
                    Text(previewOutput)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                }
            }
            .padding()
            .frame(minWidth: 350, maxWidth: .infinity)
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            isEditorFocused = true // Auto-focus editor on launch
        }
    }
}
