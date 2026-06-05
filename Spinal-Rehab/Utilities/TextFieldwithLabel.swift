//
//  TextFieldwithLabel.swift
//  FRI2_SwiftUI
//
//  Created by Hari Dass Khalsa on 3/19/21.
//

import SwiftUI
//import Combine


struct TextFieldwithLabel: View {
    var label: String
    var placeHolder: String
    @Binding var    theVal: String
    
    
    var body: some View {
        HStack(alignment:   .center) {
            Text("\(label): ").bold().padding(.leading)
            TextField(placeHolder, text: $theVal)//.padding(.leading)
        }.padding(.bottom)
    }
}

//struct TextFieldwithLabel_Previews: PreviewProvider {
//    @State var theName: String = ""
//    
//    static var previews: some View {
//        TextFieldwithLabel(label: "Name", placeHolder: "Enter Name", theVal: $theName)
//    }
//}
