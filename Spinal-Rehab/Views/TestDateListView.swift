//
//  TestDateListView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/7/26.
//

import SwiftUI

struct TestDateListView: View {
    @Binding var patient: PatientData
    @State var tdList: [TestDateData] = []
    @State private var selectedTDR: Int? // patient.ID?
   
    
    var body: some View {
        Text("Test Date List!")
            .task {
                await loadTestDates()
            }
        Text("Records in list \(tdList.count)")
            .onChange(of: patient){
                Task{
                    await loadTestDates()

                }
            }
        Table(tdList,selection: $selectedTDR){
            TableColumn("Date"){ (tdRec: TestDateData) in
                if let theDate = tdRec.testdate {
                    Text(theDate, format: .dateTime.month().day().year())
                }
                else{
                    Text("No Date Available")
                }
                
        
                
            }
        }
        .frame(width: 300, height: 300)

    }
            
    func loadTestDates() async{
        let tdC = testDateClass()
        await tdList = tdC.buildPatientist(ptid: patient.id)
    }
        
    }


#Preview {
 //   TestDateListView()
}
