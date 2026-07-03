//
//  TestEditView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/15/26.
//

import SwiftUI

struct TestEditView: View {
    @Binding var theTest:  test_tableData
    @State var dataList: [normalData] = []
    @State var selectedTest: Int? = nil
    @State var showTestEdit: Bool = false
    @State var testEditRec = normalData()
    var body: some View {
        VStack{
            Text("Test Edit # \(theTest.id)!")
                .font(.title)
                .task{
                    await  buildTestList()
                }
            
            
            VStack(alignment: .leading, spacing: 30.0){
                
                Form{
                    TextField("Name", text: $theTest.name)
                    TextField("Description",text: $theTest.description)
                    Toggle("Greater is Better", isOn: $theTest.greaterisbetter)
                    Toggle("Age Groups", isOn: $theTest.agegroups)
                    
                }
                Table( dataList,selection: $selectedTest){
                    TableColumn("id"){ (ndrec: normalData) in
                        Text("\(ndrec.id)")
                    }
                    TableColumn("gender"){ (ndrec: normalData) in
                        Text("\(ndrec.gender)")
                    }
                    TableColumn("age range"){ (ndrec: normalData) in
                        Text("\(ndrec.agerange)")
                        // print(ndrec.agerange)
                    }
                    TableColumn("excellent"){ (ndrec: normalData) in
                        Text("\(ndrec.excellent)")
                    }
                    
                    TableColumn("poor"){ (ndrec: normalData) in
                        Text("\(ndrec.poor)")
                    }
                    
                    TableColumn("low age"){ (ndrec: normalData) in
                        Text("\(ndrec.lowage)")
                    }
                    
                    TableColumn("high age"){ (ndrec: normalData) in
                        Text("\(ndrec.highage)")
                    }
                    
                }
                .onChange(of: selectedTest){
                    if let theID = $0{
                        if  let theTestRec = dataList.first(where: {$0.id == theID}){
                            testEditRec = theTestRec
                            showTestEdit = true
                        }
                       // buildTestList()
                    }
                }
                
            }
            .frame(width: 300, height: 300)
            .navigationDestination(isPresented: $showTestEdit){
                EditNormalData(normData:   $testEditRec)
                    .navigationTitle(Text("Back to List"))
            }
                Spacer()
            }
        
           
    }
    
    func buildTestList() async{
        
        let ndc = normal_dataClass()
        dataList =  await ndc.buildNormalList(id: theTest.id)
      //  print(dataList)
        
    }
}

#Preview {
  //  TestEditView()
}
