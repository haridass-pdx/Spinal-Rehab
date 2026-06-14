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
    @State var originalRec = PatienttestData()
    
    init(theRec: Binding<PatienttestData>) {
        _theRec = theRec
        //  _tablesDisabled = tablesDisabled
        _originalRec = State(initialValue: theRec.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0){
            Form(){
                Text("Test ID: \(theRec.id)")
                TextField("Test Name", text: $theRec.testname)
                TextField("Test Value", value: $theRec.testvalue, format: .number)
      
                TextField("Test Score", text: $theRec.testscore)
                    .padding(.bottom, 40.0)
                
                HStack{
                    Button("Save"){
                    print("Save")
                      saveRecord()
                   dismiss()
                }
                   .disabled(theRec == originalRec)
                    
                    Button("Cancel"){
                        print("Cancel")
                        theRec = originalRec
                        dismiss()
                    }
                }
          
                
            }
            .frame(width: 300,height: 400, alignment: .init(horizontal: .center, vertical: .top))
            Spacer()
           
            
        }.navigationTitle("Back to Test Date")
    }
    
    func saveRecord()  {
        Task{
            var localRec = theRec
            await   localRec.saveRec()
            theRec = localRec
        }

    }
    
}

#Preview {
    //PatientTestEditView()
}
