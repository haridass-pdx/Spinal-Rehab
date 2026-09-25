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

    @State private var items: [PatientRehabListData] = []
    @State private var exerciseLookup: [Int: ExerciseData] = [:]
    @State private var editItem: PatientRehabListData?

    var body: some View {
        VStack {
            Text("Rehab Programs")
                .font(.headline)

            programTable
            actionButtons

            if selected != nil {
                Divider()
                exercisesSection
            }
        }
        .task {
            await load()
        }
        .onChange(of: patient.id) { _, _ in
            Task { await load() }
        }
        .onChange(of: selected) { _, newValue in
            Task { await loadItems(newValue) }
        }
        .sheet(isPresented: $showPrint) {
            printSheet
        }
        .sheet(item: $editItem, onDismiss: {
            Task { await loadItems(selected) }
        }) { item in
            editSheet(for: item)
        }
    }

    private var programTable: some View {
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
    }

    private var actionButtons: some View {
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

    private var exercisesSection: some View {
        VStack {
            HStack {
                Text("Exercises").font(.subheadline).bold()
                Spacer()
                Button("Sync All to Defaults") {
                    Task { await syncAllToDefaults() }
                }
                .disabled(items.isEmpty)
            }
            .frame(width: 300)

            if items.isEmpty {
                Text("No exercises in this program")
                    .foregroundColor(.secondary)
                    .frame(width: 300, height: 60)
            } else {
                exercisesList
            }
        }
    }

    private var exercisesList: some View {
        List(items) { item in
            exerciseRow(for: item)
        }
        .frame(width: 300, height: 150)
    }

    private func exerciseRow(for item: PatientRehabListData) -> some View {
        HStack {
            Text(exerciseName(for: item))
            Spacer()
            Text(repsSetsLabel(for: item))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { editItem = item }
    }

    @ViewBuilder
    private var printSheet: some View {
        if let id = selected, let rec = assignedList.first(where: { $0.id == id }) {
            PatientRehabProgramPrintView(program: rec, patientName: patient.fullname)
        }
    }

    private func editSheet(for item: PatientRehabListData) -> some View {
        let exercise = exerciseLookup[item.exercise_id]
        return PatientRehabItemEditView(item: item,
                                         exerciseName: exercise?.name ?? "Exercise \(item.exercise_id)",
                                         defaultReps: exercise?.def_reps ?? 0,
                                         defaultSets: exercise?.def_sets ?? 0,
                                         defaultHold: exercise?.def_hold ?? 0)
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

    func exerciseName(for item: PatientRehabListData) -> String {
        exerciseLookup[item.exercise_id]?.name ?? "Exercise \(item.exercise_id)"
    }

    func repsSetsLabel(for item: PatientRehabListData) -> String {
        "Reps: \(item.reps)  Sets: \(item.sets)  Hold: \(item.hold)"
    }

    /// Loads the exercise rows for the selected assigned program, along with
    /// the linked exercise (for its name and current defaults).
    func loadItems(_ programId: Int?) async {
        guard let programId else {
            items = []
            exerciseLookup = [:]
            return
        }
        items = await patient_rehab_listClass().buildExerciseList(programId: programId)

        let exC = exerciseClass()
        var lookup: [Int: ExerciseData] = [:]
        for item in items where lookup[item.exercise_id] == nil {
            if let exercise = await exC.getExercise(id: item.exercise_id) {
                lookup[item.exercise_id] = exercise
            }
        }
        exerciseLookup = lookup
    }

    /// Re-seeds every item's reps/sets from the linked exercise's current
    /// defaults, overwriting whatever was stored at assignment time. Mutates
    /// `items` directly (rather than reloading from the DB afterward) so the
    /// on-screen list updates immediately.
    func syncAllToDefaults() async {
        for index in items.indices {
            guard let exercise = exerciseLookup[items[index].exercise_id] else { continue }
            var rec = items[index]
            rec.reps = exercise.def_reps
            rec.sets = exercise.def_sets
            rec.hold = exercise.def_hold
            await rec.saveRec()
            items[index] = rec
        }
    }
}

/// Edits the reps/sets for a single exercise within a patient's assigned
/// program. These start as a snapshot of the exercise's defaults (see
/// patient_rehab_programClass.addProgram) but can drift from them, so this
/// also offers a one-tap way to pull the current defaults back in.
struct PatientRehabItemEditView: View {
    @State var item: PatientRehabListData
    let exerciseName: String
    let defaultReps: Int
    let defaultSets: Int
    let defaultHold: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(exerciseName)
                .font(.title2)

            Form {
                TextField("Reps", value: $item.reps, format: .number)
                TextField("Sets", value: $item.sets, format: .number)
                TextField("Hold", value: $item.hold, format: .number)
            }

            Button("Reset to Defaults (\(defaultReps) reps / \(defaultSets) sets / \(defaultHold) hold)") {
                item.reps = defaultReps
                item.sets = defaultSets
                item.hold = defaultHold
            }

            HStack {
                Button("Save") { Task { await save(); dismiss() } }
                Button("Cancel") { dismiss() }
                Spacer()
            }
        }
        .frame(width: 320)
        .padding()
    }

    private func save() async {
        var rec = item
        await rec.saveRec()
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
