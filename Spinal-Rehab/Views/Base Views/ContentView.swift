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
       
      //  NavigationSplitView(columnVisibility: $columnVisibility) {
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
              }
            .frame(width: 400, height: 300)
            
            .padding()
            .task {
                await loadPatientList()
            }
          
     
      
            DetailView(patientRecord: $patientRecord, disableTable: $disableTable)
            .padding(.bottom, 30.0)
     
        
        
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
