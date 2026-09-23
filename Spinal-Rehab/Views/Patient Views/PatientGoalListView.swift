//
//  PatientGoalListView.swift
//  Spinal-Rehab
//
//  Per-patient panel for recording goal-setting sessions (patient_goals),
//  shown alongside PatientEditView the same way PatientRehabListView is.
//

import SwiftUI

struct PatientGoalListView: View {
    @Binding var patient: PatientData

    @State private var goals: [PatientDataGoal] = []
    @State private var selected: Int?
    @State private var editGoal: PatientDataGoal?

    var body: some View {
        VStack {
            Text("Goals")
                .font(.headline)

            goalTable
            actionButtons
        }
        .task {
            await load()
        }
        .onChange(of: patient.id) { _, _ in
            Task { await load() }
        }
        .sheet(item: $editGoal, onDismiss: {
            Task { await load() }
        }) { goal in
            PatientGoalEditView(goal: goal)
        }
    }

    private var goalTable: some View {
        Table(goals, selection: $selected) {
            TableColumn("Date") { (rec: PatientDataGoal) in
                if let d = rec.goal_date {
                    Text(d, format: .dateTime.month(.twoDigits).day(.twoDigits).year(.defaultDigits))
                } else {
                    Text("No Date")
                }
            }
            TableColumn("Cerv. Flexion") { (rec: PatientDataGoal) in
                Text(String(format: "%.1f", rec.cerv_flex_goal))
            }
            TableColumn("Lumbar Ext.") { (rec: PatientDataGoal) in
                Text(String(format: "%.1f", rec.lumbar_ext_goal))
            }
            TableColumn("Sit-Stand") { (rec: PatientDataGoal) in
                Text(String(format: "%.1f", rec.sit_stand_goal))
            }
        }
        .frame(width: 400, height: 150)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Add Goal") {
                var newGoal = PatientDataGoal()
                newGoal.patient_id = patient.id
                newGoal.goal_date = Date()
                editGoal = newGoal
            }

            Button("Edit") {
                if let id = selected, let rec = goals.first(where: { $0.id == id }) {
                    editGoal = rec
                }
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

    func load() async {
        guard patient.id != 0 else {
            goals = []
            return
        }
        goals = await patient_goalsClass().buildGoalList(patientId: patient.id)
    }

    func removeSelected() async {
        guard let id = selected, let rec = goals.first(where: { $0.id == id }) else { return }
        await rec.deleteRec()
        selected = nil
        await load()
    }
}

/// Edits a single goal-setting session: the values and target dates for
/// each of the three tracked measures.
struct PatientGoalEditView: View {
    @State var goal: PatientDataGoal
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Goal")
                .font(.title2)

            Form {
                DateTextField("Goal Date", selection: $goal.goal_date)

                Section("Cervical Flexion") {
                    TextField("Goal", value: $goal.cerv_flex_goal, format: .number)
                    DateTextField("Target Date", selection: $goal.cerv_flex_td)
                }
                Section("Lumbar Extension") {
                    TextField("Goal", value: $goal.lumbar_ext_goal, format: .number)
                    DateTextField("Target Date", selection: $goal.lumbar_ext_td)
                }
                Section("Sit to Stand") {
                    TextField("Goal", value: $goal.sit_stand_goal, format: .number)
                    DateTextField("Target Date", selection: $goal.sit_stand_td)
                }
            }

            HStack {
                Button("Save") { Task { await save(); dismiss() } }
                Button("Cancel") { dismiss() }
                Spacer()
            }
        }
        .frame(width: 360)
        .padding()
    }

    private func save() async {
        var rec = goal
        await rec.saveRec()
    }
}

#Preview {
   // PatientGoalListView()
}
