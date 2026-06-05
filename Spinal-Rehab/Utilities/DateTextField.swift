//
//  DaterTextField.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/18/25.
//

import SwiftUI

import SwiftUI

struct DateTextField: View {
    @Binding  var eventDate: Date
    //= Date() // (1) Bind to a Date instance
    
    let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short // e.g., "12/18/2025"
            formatter.timeStyle = .none
            return formatter
        }()


    var body: some View {
        VStack {
            TextField("Enter date (MM/dd/yyyy)", value: $eventDate, formatter: dateFormatter) // (2)
                .textFieldStyle(.roundedBorder)
                .padding()

           //  Text("Stored Date Object: \(eventDate.description)") // (3)
        }
    }
}


#Preview {
  //  DaterTextField()
}
