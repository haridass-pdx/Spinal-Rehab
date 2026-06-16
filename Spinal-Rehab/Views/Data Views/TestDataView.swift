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
    var body: some View {
        VStack{
            Text("Test List")
                .task {
                    await getTestList()
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
        }
        .frame(width: 300.0, height: 300.0)
    }
    
    
    func getTestList()  async {
        let ttc = test_tableClass()
        let result = await ttc.buildTesttist()
        testList = result
        
    }
}

#Preview {
    // DataView()
}
