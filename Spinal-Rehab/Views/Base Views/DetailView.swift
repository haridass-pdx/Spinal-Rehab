//
//  DetailView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/12/26.
//

import SwiftUI

struct DetailView: View {
    @Binding var patientRecord: PatientData
    @Binding var disableTable: Bool
    var addingPatient: Bool = false
    var body: some View {
        if(patientRecord.id != 0 || addingPatient) {
         //   NavigationStack {
                PatientEditView(patient: $patientRecord, tablesDisabled: $disableTable)
                    .id(patientRecord.id) // fresh @State (originalPatient) per record
        //    }
        }
        else {
            Text("No Record Selected")

        }

        
    }
}

#Preview {
   // DetailView()
}
