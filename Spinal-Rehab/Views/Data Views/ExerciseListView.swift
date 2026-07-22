//
//  ExerciseListView.swift
//  Spinal-Rehab
//
//  List + edit views for the exercise library, including adding multiple
//  images (exercise_images) per exercise. Follows the PhysicianView pattern.
//

import SwiftUI

struct ExerciseListView: View {
    @State private var exerciseList: [ExerciseData] = []
    @State private var selected: Int?
    @State private var editRec = ExerciseData()
    @State private var showEdit = false

    var body: some View {
        VStack {
            HStack {
                Text("Exercises").font(.title2)
                Spacer()
                Button("Add") {
                    editRec = ExerciseData()
                    showEdit = true
                }
            }
            .padding(.horizontal)

            Table(exerciseList, selection: $selected) {
                TableColumn("Name", value: \.name)
                TableColumn("Description", value: \.description)
                TableColumn("Reps") { Text("\($0.def_reps)") }
                TableColumn("Sets") { Text("\($0.def_sets)") }
            }
            .onChange(of: selected) {
                if let id = $0, let rec = exerciseList.first(where: { $0.id == id }) {
                    editRec = rec
                    showEdit = true
                }
            }
        }
        .frame(minWidth: 520, minHeight: 360)
        .task { await load() }
        .sheet(isPresented: $showEdit, onDismiss: {
            selected = nil
            Task { await load() }
        }) {
            ExerciseEditView(exercise: $editRec)
        }
    }

    func load() async {
        exerciseList = await exerciseClass().buildExerciseList()
    }
}

struct ExerciseEditView: View {
    @Binding var exercise: ExerciseData
    @Environment(\.dismiss) var dismiss

    /// One image shown in the editor. `dbId` is nil for images added this
    /// session that haven't been written yet.
    private struct EditableImage: Identifiable {
        let id = UUID()
        var dbId: Int?
        var data: Data
        var nsImage: NSImage
    }

    @State private var images: [EditableImage] = []
    @State private var removedDbIds: [Int] = []
    @State private var showImporter = false
    @State private var isBusy = false

    private let thumb = 120.0

    var body: some View {
        VStack(spacing: 16) {
            Text(exercise.id == 0 ? "New Exercise" : "Exercise \(exercise.id)")
                .font(.title)

            Form {
                TextField("Name", text: $exercise.name)
                TextField("Description", text: $exercise.description, axis: .vertical)
                    .lineLimit(2...5)
                HStack {
                    TextField("Default Reps", value: $exercise.def_reps, format: .number)
                    TextField("Default Sets", value: $exercise.def_sets, format: .number)
                }
            }

            Divider()

            HStack {
                Text("Images").font(.headline)
                Spacer()
                Button("Add Images…") { showImporter = true }
            }

            if images.isEmpty {
                Text("No images")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: thumb)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: thumb), spacing: 10)], spacing: 10) {
                        ForEach(images) { img in
                            Image(nsImage: img.nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: thumb, height: thumb)
                                .clipped()
                                .cornerRadius(6)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        remove(img)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 300)
            }

            HStack {
                Button("Save") { Task { await saveRecord(); dismiss() } }
                    .disabled(isBusy || exercise.name.isEmpty)
                Button("Cancel") { dismiss() }
                Spacer()
                if exercise.id != 0 {
                    Button("Delete", role: .destructive) {
                        Task { await deleteRecord(); dismiss() }
                    }
                    .disabled(isBusy)
                }
            }
        }
        .frame(width: 520)
        .padding()
        .task { await loadImages() }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.image],
                      allowsMultipleSelection: true) { result in
            handleImport(result)
        }
    }

    // MARK: - Data

    private func loadImages() async {
        guard exercise.id != 0 else { return }
        let rows = await exercise_imagesClass().buildImageList(exerciseId: exercise.id)
        images = rows.compactMap { row in
            guard let ns = NSImage(data: row.image) else { return nil }
            return EditableImage(dbId: row.id, data: row.image, nsImage: ns)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let jpeg = ImageEncoding.normalizedJPEG(fromFileAt: url),
                  let ns = NSImage(data: jpeg) else { continue }
            images.append(EditableImage(dbId: nil, data: jpeg, nsImage: ns))
        }
    }

    private func remove(_ img: EditableImage) {
        if let dbId = img.dbId { removedDbIds.append(dbId) }
        images.removeAll { $0.id == img.id }
    }

    private func saveRecord() async {
        isBusy = true
        defer { isBusy = false }

        var localRec = exercise
        await localRec.saveRec()
        exercise = localRec

        let imgClass = exercise_imagesClass()
        // New images (no dbId yet) now have an exercise id to link to.
        for img in images where img.dbId == nil {
            _ = await imgClass.saveImage(exerciseId: localRec.id, image: img.data)
        }
        // Images the user removed this session.
        for dbId in removedDbIds {
            await imgClass.deleteImage(id: dbId)
        }
        removedDbIds.removeAll()
    }

    private func deleteRecord() async {
        isBusy = true
        defer { isBusy = false }
        await exercise_imagesClass().deleteImages(exerciseId: exercise.id)
        await exercise.deleteRec()
    }
}

#Preview {
    ExerciseListView()
}
