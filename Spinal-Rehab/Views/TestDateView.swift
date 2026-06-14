//
//  TestDateView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/9/26.
//

import SwiftUI

struct TestDateView: View {
    @Binding var theRec: TestDateData
    @State private var originalRec = TestDateData()
    @Environment(\.dismiss) var dismiss
    @State var ptTestList: [PatienttestData] = []
    let fWidth = 150.0
    
    init(theRec: Binding<TestDateData>) {
        _theRec = theRec
        //  _tablesDisabled = tablesDisabled
        _originalRec = State(initialValue: theRec.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Text("Test Date")
                .font(.title)
                .task {
                    await buildTestList()
                }
            VStack(alignment:.center){
                Form{
                    VStack{
                        Text("Teest Date ID : \(theRec.id)")
                        TextField("Enter date", value: $theRec.testdate, format: .dateTime.day().month().year())
                            .textFieldStyle(.roundedBorder)
                            .padding(.leading, 100)
                        
                        
                        HStack{
                            VStack{
                                Toggle("Cervical", isOn: $theRec.cervical)
                                Toggle("Lumbar", isOn: $theRec.lumbar)
                            }
                            .frame(width: fWidth)
                            Divider()
                            VStack(alignment: .leading)
                            {
                                Toggle("Cardio", isOn: $theRec.cardio)
                                Toggle("Is Baseline", isOn: $theRec.is_baseline)
                            }
                            .frame(width: fWidth)
                        }.frame(width: 300, height: 125, alignment: .center )
                        
                        VStack(alignment: .leading, spacing: 10.0){
                            
                            HStack(spacing: 10.0){
                                TextField("FRI", value: $theRec.fri, format: .number)
                                TextField("FRI Pain", value: $theRec.fri_pain, format: .number)
                            }
                            HStack(spacing: 10.0){
                                TextField("Systolic", value: $theRec.bp_systolic, format: .number)
                                TextField("Diastolic", value: $theRec.bp_diastolic, format: .number)
                                TextField("Pulse", value: $theRec.heart_rate, format: .number)
                            }
                            
                        }.padding(.bottom, 10)
                        Text("Count \(ptTestList.count)")
                        TestListView(theList: $ptTestList)
                        
                        HStack{
                            Spacer()
                            Button("Save") {
                                Task {
                                    await saveAndDismiss()
                                }
                            }
                            Button("Cancel") {
                                theRec = originalRec
                                dismiss()
                            }
                            .disabled(theRec == originalRec)
                            Spacer()
                        }
                    }
                }
                .frame(width: 350, height: 500, alignment: .center)
                //.padding(.leading, 200 )
                
                
            }
            
            //
        }.navigationTitle(Text("Test Date"))
    }
    
    func saveAndDismiss() async {
        var localRec = theRec
        await localRec.saveRec()
        theRec = localRec
        originalRec = localRec
        dismiss()
    }
    
    func buildTestList() async {
        let ptc = Patient_testClass()
        ptTestList = await ptc.buildPatientist(pttestid: theRec.id)
    }
}

#Preview {
    //TestDateView()
}
