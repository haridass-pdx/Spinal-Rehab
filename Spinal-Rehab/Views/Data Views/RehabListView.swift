//
//  RehabListView.swift
//  Spinal-Rehab
//
//  List + edit view for the rehab_program table (standard recommendation
//  programs). Follows the ExerciseListView pattern.
//
//  Created by Hari Dass Khalsa on 9/18/26.
//

import SwiftUI

struct RehabListView: View {
    @State private var programList: [RehabProgramData] = []
    @State private var selected: Int?
    @State private var editRec = RehabProgramData()
    @State private var showEdit = false

    var body: some View {
        VStack {
            HStack {
                Text("Rehab Programs").font(.title2)
                Spacer()
                Button("Add") {
                    editRec = RehabProgramData()
                    showEdit = true
                }
            }
            .padding(.horizontal)

            Table(programList, selection: $selected) {
                TableColumn("ID", value: \.id.description)
                    .width(min: 50, ideal: 75, max: 200) // Flexible width range
                TableColumn("Name", value: \.name)
            }
            .onChange(of: selected) {
                if let id = $0, let rec = programList.first(where: { $0.id == id }) {
                    editRec = rec
                    showEdit = true
                }
            }
        }
        .frame(minWidth: 420, minHeight: 320)
        .task { await load() }
        .sheet(isPresented: $showEdit, onDismiss: {
            selected = nil
            Task { await load() }
        }) {
            RehabProgramEditView(program: $editRec)
        }
    }

    func load() async {
        programList = await rehab_programClass().buildProgramList()
    }
}

struct RehabProgramEditView: View {
    @Binding var program: RehabProgramData
    @Environment(\.dismiss) var dismiss
    @State private var isBusy = false

    @State private var linkedExercises: [RehabProgramListData] = []
    @State private var exerciseCatalog: [ExerciseData] = []
    @State private var exerciseToAdd: Int?
    @State private var showPrint = false

    var body: some View {
        VStack(spacing: 16) {
            Text(program.id == 0 ? "New Rehab Program" : "Rehab Program \(program.id)")
                .font(.title)

            Form {
                TextField("Name", text: $program.name)
            }

            HStack {
                Button("Save") { Task { await saveRecord(); dismiss() } }
                    .disabled(isBusy || program.name.isEmpty)
                Button("Cancel") { dismiss() }
                Spacer()
                if program.id != 0 {
                    Button("Print…") { showPrint = true }
                    Button("Delete", role: .destructive) {
                        Task { await deleteRecord(); dismiss() }
                    }
                    .disabled(isBusy)
                }
            }

            if program.id != 0 {
                Divider()

                HStack {
                    Text("Exercises").font(.headline)
                    Spacer()
                    Picker("Add exercise", selection: $exerciseToAdd) {
                        Text("Add exercise…").tag(Int?.none)
                        ForEach(availableExercises) { ex in
                            Text(ex.name).tag(Int?(ex.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)
                    .onChange(of: exerciseToAdd) { _, newValue in
                        if let exerciseId = newValue {
                            Task { await addExercise(exerciseId) }
                        }
                    }
                }

                if linkedExercises.isEmpty {
                    Text("No exercises linked yet")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(linkedExercises) { item in
                            HStack {
                                Text(exerciseName(for: item.exercise_id))
                                Spacer()
                                Button {
                                    Task { await removeExercise(item) }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .onMove(perform: moveExercise)
                    }
                    .frame(minHeight: 200, maxHeight: 400)
                }
            }
        }
        .frame(width: 360)
        .padding()
        .task { await loadLinkedExercises() }
        .sheet(isPresented: $showPrint) {
            RehabProgramPrintView(program: program)
        }
    }

    private var availableExercises: [ExerciseData] {
        exerciseCatalog.filter { ex in !linkedExercises.contains { $0.exercise_id == ex.id } }
    }

    private func exerciseName(for exerciseId: Int) -> String {
        exerciseCatalog.first { $0.id == exerciseId }?.name ?? "Exercise \(exerciseId)"
    }

    private func loadLinkedExercises() async {
        guard program.id != 0 else { return }
        linkedExercises = await rehab_program_listClass().buildExerciseList(rehabId: program.id)
        exerciseCatalog = await exerciseClass().buildExerciseList()
    }

    private func addExercise(_ exerciseId: Int) async {
        var rec = RehabProgramListData()
        rec.rehab_id = program.id
        rec.exercise_id = exerciseId
        rec.exercise_order = linkedExercises.count
        await rec.saveRec()
        exerciseToAdd = nil
        await loadLinkedExercises()
    }

    private func removeExercise(_ item: RehabProgramListData) async {
        await item.deleteRec()
        await loadLinkedExercises()
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        linkedExercises.move(fromOffsets: source, toOffset: destination)
        Task { await persistOrder() }
    }

    private func persistOrder() async {
        for (index, item) in linkedExercises.enumerated() where item.exercise_order != index {
            var rec = item
            rec.exercise_order = index
            await rec.saveRec()
        }
        await loadLinkedExercises()
    }

    private func saveRecord() async {
        isBusy = true
        defer { isBusy = false }
        var localRec = program
        await localRec.saveRec()
        program = localRec
    }

    private func deleteRecord() async {
        isBusy = true
        defer { isBusy = false }
        await program.deleteRec()
    }
}

struct RehabProgramPrintView: View {
    let program: RehabProgramData
    @Environment(\.dismiss) var dismiss
    @State private var html: String = ""
    @State private var isLoading = true
    @State private var engine = PDFReportEngine()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Rehab Program Handout").font(.title2)
                Spacer()
                Button("Export PDF…") { engine.exportPDF(html, suggestedName: program.name) }
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
            html = await RehabProgramReportRenderer.buildHTML(program: program)
            isLoading = false
        }
    }
}

#Preview {
    RehabListView()
}
