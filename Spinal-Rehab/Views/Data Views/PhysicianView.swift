//
//  PhysicianView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 7/1/26.
//

import SwiftUI

struct PhysicianView: View {
    @State private var physicianList: [PhysicianRec] = []
    @State private var selected: Int?
    @State private var editRec = PhysicianRec()
    @State private var showEdit = false

    var body: some View {
        VStack {
            HStack {
                Text("Physicians").font(.title2)
                Spacer()
                Button("Add") {
                    editRec = PhysicianRec()
                    showEdit = true
                }
            }
            .padding(.horizontal)

            Table(physicianList, selection: $selected) {
                TableColumn("Last Name", value: \.lastname)
                TableColumn("First Name", value: \.firstname)
                TableColumn("Degree", value: \.degree)
            }
            .onChange(of: selected) {
                if let id = $0, let rec = physicianList.first(where: { $0.id == id }) {
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
            PhysicianEditView(thePhysician: $editRec)
        }
    }

    func load() async {
        physicianList = await physicianClass().buildPhysicianList()
    }
}

struct PhysicianEditView: View {
    @Binding var thePhysician: PhysicianRec
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20.0) {
            Text(thePhysician.id == 0 ? "New Physician" : "Physician \(thePhysician.id)")
                .font(.title)
            Form {
                TextField("Last Name", text: $thePhysician.lastname)
                TextField("First Name", text: $thePhysician.firstname)
                TextField("Degree", text: $thePhysician.degree)

                HStack {
                    Button("Save") {
                        Task {
                            await saveRecord()
                            dismiss()
                        }
                    }
                    Button("Cancel") { dismiss() }
                    Spacer()
                    if thePhysician.id != 0 {
                        Button("Delete", role: .destructive) {
                            Task {
                                await deleteRecord()
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 400.0)
        .padding()
    }

    func saveRecord() async {
        var localRec = thePhysician
        await localRec.saveRec()
        thePhysician = localRec
    }

    func deleteRecord() async {
        var localRec = thePhysician
        await localRec.deleteRec()
    }
}

#Preview {
    PhysicianView()
}
