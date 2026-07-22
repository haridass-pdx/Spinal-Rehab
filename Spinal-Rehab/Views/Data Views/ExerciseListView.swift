//
//  ExerciseListView.swift
//  Spinal-Rehab
//
//  List + edit views for the exercise library, including adding multiple
//  images (exercise_images) per exercise. Follows the PhysicianView pattern.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
                TableColumn("ID", value: \.id.description)
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
    @State private var dropTargeted = false

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
                Button("Paste") { pasteFromClipboard() }
                    .disabled(!clipboardHasImage)
                Button("Add Images…") { showImporter = true }
            }

            Group {
                if images.isEmpty {
                    Text("Drag images here, paste, or use Add Images…")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: thumb)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: thumb), spacing: 10)], spacing: 10) {
                            ForEach(images) { img in
                                Image(nsImage: img.nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: thumb, height: thumb)
                                    .background(Color.gray.opacity(0.1))
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
            }
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(dropTargeted ? Color.accentColor : Color.gray.opacity(0.3),
                                  style: StrokeStyle(lineWidth: dropTargeted ? 2 : 1, dash: [5]))
            )
            .onDrop(of: [.fileURL, .image], isTargeted: $dropTargeted) { providers in
                loadDropped(providers)
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
            appendJPEG(fromFileAt: url)
        }
    }

    /// Normalize raw image bytes and append as a pending image.
    private func appendNormalized(_ raw: Data) {
        guard let jpeg = ImageEncoding.normalizedJPEG(from: raw),
              let ns = NSImage(data: jpeg) else { return }
        images.append(EditableImage(dbId: nil, data: jpeg, nsImage: ns))
    }

    private func appendJPEG(fromFileAt url: URL) {
        guard let jpeg = ImageEncoding.normalizedJPEG(fromFileAt: url),
              let ns = NSImage(data: jpeg) else { return }
        images.append(EditableImage(dbId: nil, data: jpeg, nsImage: ns))
    }

    // MARK: - Drag & drop

    private func loadDropped(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                handled = true
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    DispatchQueue.main.async { appendJPEG(fromFileAt: url) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                handled = true
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data else { return }
                    DispatchQueue.main.async { appendNormalized(data) }
                }
            }
        }
        return handled
    }

    // MARK: - Paste

    private var clipboardHasImage: Bool {
        let pb = NSPasteboard.general
        return pb.canReadObject(forClasses: [NSImage.self], options: nil)
            || pb.canReadObject(forClasses: [NSURL.self],
                                options: [.urlReadingContentsConformToTypes: [UTType.image.identifier]])
    }

    private func pasteFromClipboard() {
        let pb = NSPasteboard.general
        // Prefer file references (keeps original bytes), else fall back to raw image data.
        if let urls = pb.readObjects(forClasses: [NSURL.self],
                                     options: [.urlReadingContentsConformToTypes: [UTType.image.identifier]]) as? [URL],
           !urls.isEmpty {
            for url in urls { appendJPEG(fromFileAt: url) }
        } else if let pasted = pb.readObjects(forClasses: [NSImage.self]) as? [NSImage] {
            for img in pasted {
                if let tiff = img.tiffRepresentation { appendNormalized(tiff) }
            }
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
