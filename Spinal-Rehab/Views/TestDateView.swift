//
//  TestDateView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/9/26.
//

import SwiftUI

struct TestDateView: View {
    @Binding var theRec: TestDateData
    @State private var originalRec = TestDateData()
    var onSaved: () async -> Void = {}
    @Environment(\.dismiss) var dismiss

    init(theRec: Binding<TestDateData>, onSaved: @escaping () async -> Void = {}) {
        _theRec = theRec
        _originalRec = State(initialValue: theRec.wrappedValue)
        self.onSaved = onSaved
    }

    var body: some View {
        VStack{
            Form{
                DateTextField("Test Date", selection: $theRec.testdate)
                    .frame(width: 300, height: 50, alignment: .trailing)
                    .offset(x: 150, y: 0)
                HStack(spacing: 10){
                    Toggle("Cervical", isOn: $theRec.cervical)
                    Toggle("Lumbar", isOn: $theRec.lumbar)
                    Toggle("Cardio", isOn: $theRec.cardio)
                }
                .padding(.vertical, 10)
                Toggle("Is Baseline", isOn: $theRec.is_baseline)

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
            .environment(\.layoutDirection, .leftToRight)  // already default
            // or, on macOS 13+:
           // .formStyle(.grouped)
        }
        .navigationTitle(Text("Test Date"))
    }

    func saveAndDismiss() async {
        var localRec = theRec
        await localRec.saveRec()
        theRec = localRec
        originalRec = localRec
        await onSaved()
        dismiss()
    }
}

#Preview {
    //TestDateView()
}
