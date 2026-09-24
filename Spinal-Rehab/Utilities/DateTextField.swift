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
                set: { selection = dateFormatter.date(from: normalizeTwoDigitYear($0)) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }

    /// A bare 2-digit year (e.g. "04/24/23") parses under the "yyyy" pattern
    /// as the literal year 23, not 2023 — there's no century pivot for a
    /// 4-digit-year format. Rewrite a bare 2-digit year to the current
    /// century before parsing; 1/3/4-digit year input (including mid-typing
    /// partial states) is left untouched.
    private func normalizeTwoDigitYear(_ raw: String) -> String {
        let parts = raw.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[2].count == 2, Int(parts[2]) != nil else { return raw }
        return "\(parts[0])/\(parts[1])/20\(parts[2])"
    }
}


#Preview {
  //  DaterTextField()
}
