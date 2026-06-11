//
//  PatientEditView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/6/26.
//

import SwiftUI

struct PatientEditView: View {
    @Binding var patient: PatientData
    @State private var selectedDate: Int? // patient.ID?
   
    @State private var originalPatient = PatientData()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var globalData: globalDataRec
   
    init(patient: Binding<PatientData>){
        _patient = patient
        _originalPatient = State(initialValue: patient.wrappedValue)
    }
  
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Patient Information")
                .font(.title)
                .padding(.horizontal)
            Text("Patient ID: \(patient.id)")
            Form{
                HStack{
                    TextField("First Name", text: $patient.firstname)
                    TextField("Last Name", text: $patient.lastname)
                        .padding(.leading, 10)
                }
                TextField("Street", text: $patient.street)
                HStack{
                    TextField("City", text: $patient.city)
                    TextField("State", text: $patient.state)
                    TextField("Zip", text: $patient.zip)
                }
                HStack{
                    TextField("Phone", text: $patient.phone)
                    TextField("Email", text: $patient.email)
                }
                TextField("Gender", text: $patient.gender)
                HStack{
                    DateTextField("Birthday", selection: $patient.dob)
                        .frame(width: 200)
                    TextField("Age", value: $patient.age, format: .number)
                }
                HStack{
                    Spacer()
                    Button("Save") {
                        SaveRecord()
                        originalPatient = patient
                        dismiss()
                    }
                    Button("Cancel") {
                        // setField()
                        //resetTimeForm()
                        patient = originalPatient
                        dismiss()
                        //Temp()
                    }
                    .disabled(patient == originalPatient)
                    Spacer()
                }.frame(alignment: .center)
            }
            
            .frame(width: 450)
            .environment(\.layoutDirection, .leftToRight)  // already default
            // or, on macOS 13+:
            .formStyle(.grouped)
           
        }
        .padding(10)
        TestDateListView(patient: $patient)
        Spacer()
    }
    
   func SaveRecord(){
       Task{
           var localPatient = patient
           await localPatient.saveRec()
           patient = localPatient
       }

    }
}

#Preview {
   // PatientEditView()
}
