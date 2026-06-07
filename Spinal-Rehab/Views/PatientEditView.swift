//
//  PatientEditView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/6/26.
//

import SwiftUI

struct PatientEditView: View {
    @Binding var patient: PatientData
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        Text(patient.fullname)
    }
}

#Preview {
   // PatientEditView()
}
