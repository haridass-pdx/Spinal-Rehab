//
//  TestListView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/13/26.
//

import SwiftUI

struct TestListView: View {
    @Binding var theList:[PatienttestData]
    @State var selectedTest: Int?
    @State var ptTestRec = PatienttestData()
    @State var showEdit: Bool = false
    @Binding var alterTest: Bool 
    var body: some View {
        //  Text("Test List View")
        Table(theList,selection: $selectedTest){
            TableColumn("Test Name"){ (pttRec: PatienttestData) in
                Text("\(pttRec.testname)")
            }
            TableColumn("Test Value"){ (pttRec: PatienttestData) in
                Text("\(pttRec.testvalue)")
            }
            TableColumn("Test Score"){ (pttRec: PatienttestData) in
                Text("\(pttRec.testscore)")
            }
            
            
        }  // table
        .onChange(of: selectedTest){
            if let theID = $0{
                print("Selected \(theID)")
                if  let theTestRec = theList.first(where: {$0.id == theID}){
                    ptTestRec = theTestRec
                    showEdit = true
                }
                if let idx = theList.firstIndex(where: { $0.id == ptTestRec.id }) {
                    theList[idx] = ptTestRec
                }
            }
        }


        .navigationDestination(isPresented: $showEdit) {
             PatientTestEditView(theRec: $ptTestRec, alterTest: $alterTest)
        }

    }
}


#Preview {
    //TestListView()
}
