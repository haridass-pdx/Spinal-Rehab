//
//  ComboBox.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/22/26.
//


import SwiftUI

struct ComboBoxView: View {
    @Binding var theValue:  String
    @Binding var suggestions: [String]
    @State var prompt: String
    
    var body: some View {
        HStack {
            TextField(prompt, text: $theValue)
                .textFieldStyle(.roundedBorder)
            
            Menu {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        theValue = suggestion
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
            .fixedSize()
        }
        .padding()
    }
}

#Preview {
 //   ComboBox()
}
