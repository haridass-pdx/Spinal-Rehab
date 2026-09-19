//
//  PatientRehabListView.swift
//  Spinal-Rehab
//
//  Per-patient panel for assigning rehab programs (patient_rehab_program),
//  shown alongside PatientEditView the same way TestDateListView is.
//

import SwiftUI

struct PatientRehabListView: View {
    @Binding var patient: PatientData

    @State private var assignedList: [PatientRehabProgramData] = []
    @State private var catalog: [RehabProgramData] = []
    @State private var programToAssign: Int?
    @State private var selected: Int?
    @State private var showPrint = false

    var body: some View {
        VStack {
            Text("Rehab Programs")
                .font(.headline)

            Table(assignedList, selection: $selected) {
                TableColumn("Date") { (rec: PatientRehabProgramData) in
                    if let d = rec.prdate {
                        Text(d, format: .dateTime.month(.twoDigits).day(.twoDigits).year(.defaultDigits))
                    } else {
                        Text("No Date")
                    }
                }
                TableColumn("Name", value: \.name)
            }
            .frame(width: 300, height: 150)

            HStack(spacing: 12) {
                Picker("Assign program", selection: $programToAssign) {
                    Text("Assign program…").tag(Int?.none)
                    ForEach(catalog) { program in
                        Text(program.name).tag(Int?(program.id))
                    }
                }
                .labelsHidden()
                .frame(width: 200)
                .onChange(of: programToAssign) { _, newValue in
                    if let rehabId = newValue {
                        Task { await assign(rehabId) }
                    }
                }

                Button("Print…") {
                    showPrint = true
                }
                .disabled(selected == nil)

                Button {
                    Task { await removeSelected() }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(selected == nil)
            }
        }
        .task {
            await load()
        }
        .onChange(of: patient.id) { _, _ in
            Task { await load() }
        }
        .sheet(isPresented: $showPrint) {
            if let id = selected, let rec = assignedList.first(where: { $0.id == id }) {
                PatientRehabProgramPrintView(program: rec, patientName: patient.fullname)
            }
        }
    }

    func load() async {
        guard patient.id != 0 else {
            assignedList = []
            return
        }
        assignedList = await patient_rehab_programClass().buildProgramList(patientId: patient.id)
        catalog = await rehab_programClass().buildProgramList()
    }

    func assign(_ rehabId: Int) async {
        _ = await patient_rehab_programClass.addProgram(rehabId: rehabId, patientId: patient.id)
        programToAssign = nil
        await load()
    }

    func removeSelected() async {
        guard let id = selected, let rec = assignedList.first(where: { $0.id == id }) else { return }
        await rec.deleteRec()
        selected = nil
        await load()
    }
}

struct PatientRehabProgramPrintView: View {
    let program: PatientRehabProgramData
    let patientName: String
    @Environment(\.dismiss) var dismiss
    @State private var html: String = ""
    @State private var isLoading = true
    @State private var engine = PDFReportEngine()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Rehab Program Handout").font(.title2)
                Spacer()
                Button("Export PDF…") { engine.exportPDF(html, suggestedName: "\(patientName) - \(program.name)") }
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
        .task {
            isLoading = true
            html = await RehabProgramReportRenderer.buildHTML(patientProgram: program, patientName: patientName)
            isLoading = false
        }
    }
}

#Preview {
   // PatientRehabListView()
}
