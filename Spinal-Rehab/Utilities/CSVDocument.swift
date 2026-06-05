//
//  CSVDocument.swift
//  KPRC-Payroll-Nio
//
//  Created by Hari Dass Khalsa on 4/25/26.
//


import SwiftUI
import UniformTypeIdentifiers

// 1. Define the CSV document structure
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String

    init(text: String = "") {
        self.text = text
    }

    // Load existing data
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            throw CocoaError(.fileReadUnknown)
        }
    }

    // Save data to the chosen location
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
