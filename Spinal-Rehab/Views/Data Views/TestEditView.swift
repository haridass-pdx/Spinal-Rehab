//
//  TestEditView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/15/26.
//

import SwiftUI

struct TestEditView: View {
    @Binding var theTest:  test_tableData
    var body: some View {
        VStack{
            Text("Test Edit # \(theTest.id)!")
                .font(.title)
            VStack(alignment: .leading, spacing: 20.0){
                
                Form{
                    TextField("Name", text: $theTest.name)
                    TextField("Description",text: $theTest.description)
                    Toggle("Greater is Better", isOn: $theTest.greaterisbetter)
                }
                
            }
            .frame(width: 300, height: 300)
            Spacer()
        }
           
    }
}

#Preview {
  //  TestEditView()
}
