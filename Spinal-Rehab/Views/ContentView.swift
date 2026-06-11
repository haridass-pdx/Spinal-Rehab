//
//  ContentView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/4/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var globalData: globalDataRec
    @State var patientList: [PatientData] = []
    @State var patientRecord = PatientData()
    @State private var selectedPt: Int? // patient.ID?
    @State private var disableTable: Bool = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all // or .doubleColumn
    var body: some View {
       
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack {
                Table(patientList, selection: $selectedPt) {
                    TableColumn("Name", value: \.fullname)
                }
                .disabled(disableTable)
                .onChange(of: selectedPt) {oldValue, newValue in
                    if let specificIndex = patientList.firstIndex(where: { $0.id == newValue }) {
                        patientRecord = patientList[specificIndex]
                    }
                }
                .onChange(of: globalData.disablePtList) {oldValue, newValue in
                    disableTable = globalData.disablePtList
                    print("disableTable: \(disableTable)")
                    print("globalData.disablePtList: \(globalData.disablePtList)")
                }
              }
            
            .padding()
            .task {
                await loadPatientList()
            }
          
     
        }  // NavSplit
        detail: {
            if(patientRecord.id != 0) {
                NavigationStack {
                    PatientEditView(patient: $patientRecord)
                }
            }
            else {
                Text("No Record Selected")

            }
        }
      //  .onAppear { print("[ContentView] onAppear") }
    } // body
      
    
    
    func loadPatientList() async {
        let myConnection = patientClass()
        let list = await myConnection.buildPatientist()
        patientList = list
    }

}

#Preview {
    ContentView()
}
