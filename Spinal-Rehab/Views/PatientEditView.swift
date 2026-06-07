//
//  PatientEditView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/6/26.
//

import SwiftUI

struct PatientEditView: View {
    @Binding var patient: PatientData
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var globalData: globalDataRec
  
    var body: some View {
        VStack{
            Form{
                HStack{
                    Button("Save") {
                        dismiss()

                    }
                    Button("Cancel") {
                        // setField()
                        //resetTimeForm()
                        dismiss()
                        //Temp()
                        
                    }
                }.padding(10)
                HStack{
                    TextField("First Name", text: $patient.firstname)
                      TextField("Last Name", text: $patient.lastname)
                }.padding(10)
            }
            .frame(width: 400    )
            //Form
            //  Text(patient.fullname)
            Spacer()
        }
    }
}

#Preview {
   // PatientEditView()
}
