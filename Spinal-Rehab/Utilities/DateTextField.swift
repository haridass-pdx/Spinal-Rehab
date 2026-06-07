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
        formatter.dateStyle = .short // e.g., "12/18/2025"
        formatter.timeStyle = .none
        return formatter
    }()

    init(_ label: String, selection: Binding<Date?>) {
        self.label = label
        self._selection = selection
    }

    var body: some View {
        HStack(alignment: .center) {
            Text("\(label): ").bold().padding(.leading)
            TextField("MM/dd/yyyy", value: $selection, formatter: dateFormatter)
                .textFieldStyle(.roundedBorder)
        }
    }
}


#Preview {
  //  DaterTextField()
}
