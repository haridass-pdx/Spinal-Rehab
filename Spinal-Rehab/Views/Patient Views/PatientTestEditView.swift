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
    @State var nameList: [String] = []
    
    init(theRec: Binding<PatienttestData>) {
        _theRec = theRec
        //  _tablesDisabled = tablesDisabled
        _originalRec = State(initialValue: theRec.wrappedValue)
        //print(_theRec)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0){
            Form(){
                Text("Test ID: \(theRec.id)")
                ComboBoxView(theValue: $theRec.testname, suggestions: $nameList, prompt: "Test Name")
              //  TextField("Test Name", text: $theRec.testname)
                TextField("Test Value", value: $theRec.testvalue, format: .number)
                    .onChange(of: theRec.testvalue) {oldValue, newValue in
                        let tempScore = getScore(for: newValue)
                        
                    }
      
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
            .frame(width: 350,height: 400, alignment: .init(horizontal: .center, vertical: .top))
            Spacer()
                .task {
                    nameList = await test_tableClass.getTestNameList()
                }
           
            
        }.navigationTitle("Back to Test Date")
    }
    
    func saveRecord()  {
        Task{
            var localRec = theRec
            await   localRec.saveRec()
            theRec = localRec
        }

    }
    
    func getScore(for test: Double) -> String {
        var score: String = ""
        
       return score
    }
    
}

#Preview {
    //PatientTestEditView()
}
