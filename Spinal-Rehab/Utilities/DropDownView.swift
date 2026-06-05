//
//  DropDownView.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/31/25.
//


import SwiftUI

struct DropdownView: View {
    var label: String
      var options: [String]
    @Binding  var selectedOption: String
  
    var body: some View {
        Picker(label , selection: $selectedOption) {
            ForEach(options , id: \.self) { option in
                Text(option)
            }
        }
        .pickerStyle(.menu) // Applies the dropdown menu style
    }
}
