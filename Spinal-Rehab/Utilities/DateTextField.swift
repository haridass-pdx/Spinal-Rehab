//
//  DaterTextField.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/18/25.
//

import SwiftUI

import SwiftUI

struct DateTextField: View {
    let label: String
    @Binding var selection: Date?

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"// e.g., "12/18/2025"
        return formatter
    }()

    init(_ label: String, selection: Binding<Date?>) {
        self.label = label
        self._selection = selection
    }

    var body: some View {
        HStack(alignment: .center) {
            Text("\(label): ").bold().padding(.leading)
            TextField("MM/dd/yyyy", text: Binding(
                get: { selection.map { dateFormatter.string(from: $0) } ?? "" },
                set: { selection = dateFormatter.date(from: $0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}


#Preview {
  //  DaterTextField()
}
