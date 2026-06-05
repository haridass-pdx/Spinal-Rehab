//
//  PasswordView.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/19/25.
//

import SwiftUI
import Foundation
internal import Combine
// import Combine

class PersistOj: ObservableObject{
    @Published var doShow: Bool = false
}

struct PasswordView: View {
    @Binding var password: String
    @Binding var result: Bool
    @Binding var showAlert: Bool
    @State var attempPW: String = ""
    @StateObject private var showingAlert = PersistOj()
    
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Text("Enter Password")
            .font(.largeTitle)
            .padding()
        
        
        Form{
            SecureField("Password", text: $attempPW)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200 )
                .padding()
            HStack{
                let buttonwidth : CGFloat = 70
                Button(action: {
                    if password.count < 10 {
                        password = password.encrypt()
                    }
                    
                    result = (attempPW.encrypt() == password)
                    showAlert = !result
                    dismiss()}){
                        Text("OK")
                            .frame(width: buttonwidth )
                    }
                    .keyboardShortcut(.defaultAction)
                  .padding()
                
                Button(action: {
                    result = false
                    dismiss()

                }){
                    Text(  "Cancel")
                        .frame(width: buttonwidth)
                                        
                }

                 .padding()
            }

               // .padding()
            
        }.presentationSizing(.form)
           
//            .alert("Incorrect Password", isPresented: $showingAlert.doShow) {
//                Button("OK", role: .cancel) {
//                    dismiss()
//                }
//            }
    }
}

#Preview {
    // PasswordView()
}
