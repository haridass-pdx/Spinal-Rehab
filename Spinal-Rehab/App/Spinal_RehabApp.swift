//
//  Spinal_RehabApp.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/4/26.
//

import SwiftUI
internal import Combine

class globalDataRec: ObservableObject{
    @Published var loggedIn: Bool = false
    @Published   var loggedInRec = logInRec()

}

class AlertManager: ObservableObject {
    @Published var isAlertPresented: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    func showCustomAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isAlertPresented = true // Changing this property triggers the UI update
    }
}

@main
struct Spinal_RehabApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var globalData = globalDataRec()

    var body: some View {
        let _ = print("[RootView] body re-evaluating, loggedIn = \(globalData.loggedIn)")
        return Group {
            if globalData.loggedIn {
                ContentView()
            } else {
                LogInIView()
            }
        }
        .environmentObject(globalData)
    }
}
