//
//  PtReportView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//

import SwiftUI

struct PtReportView: View {
    @Binding var theRec: TestDateData
    @Environment(\.dismiss) var dismiss
    @State private var text: String = ""
    
   // theRec.testdate

    var body: some View {
        VStack {
            Text("Report View")
                .padding(10)
                .font(.title2)
                .task {
                   text = await ReportDataClass.getReportData(reportID: 1)
                }
            TextEditor(text: $text)
                .padding(10)
            Button("Close") {
                dismiss()
            }
            .padding(10)
        }
       .frame(width: 600,height: 600, alignment: .init(horizontal: .center, vertical: .top))
    }
}

#Preview {
   // PtReportView()
}
