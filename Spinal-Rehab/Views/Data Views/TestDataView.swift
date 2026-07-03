//
//  DataView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/15/26.
//

import SwiftUI

struct TestDataView: View {
    @EnvironmentObject var globalData: globalDataRec
    @State private var testList: [test_tableData] = []
    @State private var testEditRec = test_tableData()
    @State private var selectedTest: Int?
    @State private var showTestEdit: Bool = false
    @State private var physicianList: [PhysicianRec] = []
    @State private var thePhysician = PhysicianRec()
    @State private var selectedPhysican: Int?
    @State private var showPhysicianEdit: Bool = false
    var body: some View {
        VStack( spacing: 10){
            Text("Test List")
                .font(.title2)
                .task {
                    await getTestList()
                    await getPhysicianList()
                }
            Table(testList, selection: $selectedTest){
                TableColumn("Test Name", value: \.name)
            }
            .onChange(of: selectedTest) {
                if let theID = $0{
                    if let theTDRec  = testList.first(where: {$0.id == theID}){
                        testEditRec = theTDRec
                        showTestEdit = true
                    }
                }
             }
            .navigationDestination(isPresented: $showTestEdit){
                TestEditView(theTest:  $testEditRec)
                    .navigationTitle(Text("Back to List"))
                
            }
            Spacer()
            PhysicianView()
            Spacer()
        }
        .frame(width: 300.0, height: 600.0)
    }
    
    
    func getTestList()  async {
        let ttc = test_tableClass()
        let result = await ttc.buildTesttist()
        testList = result
        
    }
    
    func getPhysicianList()  async {
        let phc = physicianClass()
        let result = await phc.buildPhysicianList()
        physicianList = result
    }
}

#Preview {
    // DataView()
}
