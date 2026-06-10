//
//  TestDateView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/9/26.
//

import SwiftUI

struct TestDateView: View {
    @Binding var theRec: TestDateData
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var globalData: globalDataRec
  var body: some View {
        VStack{
            Form{
                DateTextField("Test Date", selection: $theRec.testdate)
                HStack{
                    Toggle("Cervical", isOn: $theRec.cervical)
                    Toggle("Lumbar", isOn: $theRec.lumbar)
                    Toggle("Aerobic", isOn: $theRec.aerobic)
                    
                }
                Toggle("Is Baseline", isOn: $theRec.is_baseline)
           
                
                
            }.frame(width: 500, height: 500)
                .onAppear {
                    globalData.disablePtList = true
                }
        }
        .navigationTitle(Text("Test Date"))
    }
}

#Preview {
    //TestDateView()
}
