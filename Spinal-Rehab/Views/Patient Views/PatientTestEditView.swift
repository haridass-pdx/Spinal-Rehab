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
    @FocusState private var isValueFocused: Bool
    
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
                    .focused($isValueFocused)
                    .onChange(of: isValueFocused) {oldValue, newValue in
                        if(!newValue){
                            Task{
                                let tempScore = await getScore()
                            }
                        }
                        
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
    
    func getScore() async-> String {
        var score: String = ""
        var gender: String = ""
        var age: Int = 0
        
       // let ptc  = patientClass()
        let result = await patientClass.getGenderAndAge(forId: theRec.patient_id)
        gender = result.0
        age = result.1
        
        score = await    test_tableClass.getScoreForTest(testName: theRec.testname, age: age, Gender: gender, Value: theRec.testvalue)
      
        
                
        
       return score
    }
    
        
}

#Preview {
    //PatientTestEditView()
}
