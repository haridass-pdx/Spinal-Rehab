//
//  TestDateListView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/7/26.
//

import SwiftUI

struct TestDateListView: View {
    @Binding var patient: PatientData
    @Binding var tablesDisabled: Bool
    @State var tdList: [TestDateData] = []
    @State private var selectedTDR: Int? // patient.ID?
    @State private var selTDRec = TestDateData()
    @State private var showTD: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Test Date List!")
            .onAppear(perform:{
                Task{
                    await loadTestDates()
                }
            })
        /*    .task {
                await loadTestDates()
            }*/
                      
        Text("Records in list \(tdList.count)")
            .onChange(of: patient){
                Task{
                    await loadTestDates()
                    
                }
            }
        
        Table(tdList,selection: $selectedTDR){
            TableColumn("Date"){ (tdRec: TestDateData) in
                if let theDate = tdRec.testdate {
                    Text(theDate, format: .dateTime.month(.twoDigits).day(.twoDigits).year(.defaultDigits))
                }
                else{
                    Text("No Date Available")
                }
                
                
                
            }
        }
        .frame(width: 300, height: 150)
        .onChange(of: selectedTDR){
            if let theID = $0{
                print("Selected \(theID)")
                if let theTD = tdList.first(where: {$0.id == theID}){
                    selTDRec = theTD
                    showTD = true
                }
            }
        }
        
        .navigationDestination(isPresented: $showTD) {
            TestDateView(theRec: $selTDRec, tablesDisabled: $tablesDisabled)
        }
        .onChange(of: showTD) { _, newValue in
            tablesDisabled = newValue
            if !newValue {
                syncEditedRecord()
            }
        }
        
    }
    
    func loadTestDates() async{
        let tdC = testDateClass()
        await tdList = tdC.buildPatientist(ptid: patient.id)
        print("load test dates")
    }

    func syncEditedRecord() {
        guard selTDRec.id != 0 else { return }
        if let idx = tdList.firstIndex(where: { $0.id == selTDRec.id }) {
            tdList[idx] = selTDRec
        } else {
            tdList.append(selTDRec)
        }
    }
    
}


#Preview {
    //   TestDateListView()
}
