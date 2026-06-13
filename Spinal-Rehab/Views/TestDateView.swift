//
//  TestDateView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/9/26.
//

import SwiftUI

struct TestDateView: View {
    @Binding var theRec: TestDateData
    @Binding var tablesDisabled: Bool
    @State private var originalRec = TestDateData()
    @Environment(\.dismiss) var dismiss
    let fWidth = 150.0

    init(theRec: Binding<TestDateData>, tablesDisabled: Binding<Bool>) {
        _theRec = theRec
        _tablesDisabled = tablesDisabled
        _originalRec = State(initialValue: theRec.wrappedValue)
    }

    var body: some View {
        Form{
            VStack{
                DateTextField("Test Date", selection: $theRec.testdate)
                    .frame(width: 300, height: 50, alignment: .trailing)
                    .padding(.leading, 200) 
                    
                HStack{
                    VStack{
                        Toggle("Cervical", isOn: $theRec.cervical)
                        Toggle("Lumbar", isOn: $theRec.lumbar)
                    }
                    .frame(width: fWidth)
                    Divider()
                    VStack{
                        Toggle("Cardio", isOn: $theRec.cardio)
                        Toggle("Is Baseline", isOn: $theRec.is_baseline)
                    }
                    .frame(width: fWidth)
                }.frame(width: 300, height: 125, alignment: .center )

                HStack{
                    Spacer()
                    Button("Save") {
                        Task {
                            await saveAndDismiss()
                        }
                    }
                    Button("Cancel") {
                        theRec = originalRec
                        dismiss()
                    }
                    .disabled(theRec == originalRec)
                    Spacer()
                }
            }
            .frame(width: 500, height: 500)
            .padding(.trailing, 200 )
            
        }
        .navigationTitle(Text("Test Date"))
        .onDisappear {
            tablesDisabled = false
        }
    }

    func saveAndDismiss() async {
        var localRec = theRec
        await localRec.saveRec()
        theRec = localRec
        originalRec = localRec
        dismiss()
    }
}

#Preview {
    //TestDateView()
}
