import SwiftUI
import LocalAuthentication

struct AuthenticateView: View {
    @State private var isUnlocked = false
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack {
            if isUnlocked {
                Text("Unlocked! Welcome.")
            } else {
                Text("Locked")
                Button("Authenticate") {
                    authenticate()
                }
            }
        }
        .onAppear(){
            authenticate()

        }
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Allow biometrics OR device password
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "We need to unlock your data."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success,  authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                        isAuthenticated = true
                    } else {
                        print("Athentication failed")// Handle error (e.g., face not recognized)
                    }
                }
            }
        } else {
            print("No biometrics")//// No biometrics available
        }
    }
}
