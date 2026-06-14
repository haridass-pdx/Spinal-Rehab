//
//  PatientTestEditView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/14/26.
//

import SwiftUI

struct PatientTestEditView: View {
    @Binding var theRec: PatienttestData
    @Environment(\.dismiss) var dismiss
   
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0){
            Form(){
                Text("Test ID: \(theRec.id)")
                TextField("Test Name", text: $theRec.testname)
                TextField("Test Value", value: $theRec.testvalue, format: .number)
      
                TextField("Test Score", text: $theRec.testscores)
                    .padding(.bottom, 40.0)
                
                HStack{
                    Button("Save"){
                    print("Save")
                    dismiss()
                }
                    Button("Cancel"){
                        print("Cancel")
                        dismiss()
                    }
                }
          
                
            }
            .frame(width: 300,height: 400, alignment: .init(horizontal: .center, vertical: .top))
            Spacer()
           
            
        }.navigationTitle("Back to Test Date")
    }
}

#Preview {
    //PatientTestEditView()
}
