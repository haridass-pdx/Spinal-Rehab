//
//  SettingsView.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 3/25/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var isChecking = false
    @State private var resultMessage: String = ""
    @State private var showResult = false

    var body: some View {
        VStack{
            Form{
                Text("Hello, World!")

                Section("Database Maintenance") {
                    Button(isChecking ? "Checking…" : "Fix ID Sequences") {
                        Task { await runFix() }
                    }
                    .disabled(isChecking)
                    Text("Checks every table's id sequence against its actual data and advances any that have fallen behind (which can happen after a bulk import). Safe to run any time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("ID Sequence Check", isPresented: $showResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resultMessage)
        }
    }

    private func runFix() async {
        isChecking = true
        let drift = await SequenceMaintenance.checkAll()
        let fixed = await SequenceMaintenance.fixDrifted(drift)
        isChecking = false

        if fixed.isEmpty {
            resultMessage = "All \(drift.count) id sequences are already in sync."
        } else {
            let lines = fixed.map { "• \($0.table).\($0.column): \($0.seqVal) → \($0.maxId)" }.joined(separator: "\n")
            resultMessage = "Fixed \(fixed.count) sequence\(fixed.count == 1 ? "" : "s"):\n\(lines)"
        }
        showResult = true
    }
}

#Preview {
    SettingsView()
}
