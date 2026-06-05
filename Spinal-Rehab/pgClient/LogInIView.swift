//
//  LogInIView.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/18/25.
//

import SwiftUI
import SimpleKeychain

let pwKey = "nmpw"
struct DefaultRec: Codable{
    var hostString: String = "localhost"
    var pastHosts  = ["", "localhost"]
    
}

struct logData: Codable{
    var username: String = "haridass"
    var password: String = "3108"
}

struct logInRec{
    var host: String = "localhost"
    var username: String = "" //= "haridass" // remove
    var password: String   = "" // = "3108"       // remove
    
    var database: String = "payroll_kprc"
    
}

let UserDefaultKey = "dbServers"

struct LogInIView: View {
    @EnvironmentObject var globalData: globalDataRec
    @Environment(\.dismissWindow) var dismissWindow
    @State  var logIn = logInRec()
    @State private var selectedServer = "localhost"
    @State  private var otherServer: String = ""
    @State  var showAlert: Bool = false
    @State var hostStr: String = ""
    @State var nmpw: logData = getNamePW()
    @State var canEdit: Bool = false
    
    @State var defaultRec: DefaultRec = LogInIView.getUserDefaults()
    
    var body: some View {
        //  @AppStorage(UserDefaultKey)  var userDefaults: DefaultRec
        
        
        //    NavigationView { // Often wrapped in a NavigationView for a title
        
        Form {
            Spacer()
            Section(header: Text("Database Login Information"))   {  //Section(header: Text("Login Information"))
                VStack{ Text("This is the Database Login Not User Login")
                        .padding(5)
                        .bold(true)
                    Text("Change these only if")
                    Text("you really know what your doing.")
                }
                    .padding(10)
                    .bold(true)
                VStack{
                    SecureField("Database Username", text: $logIn.username)
                    SecureField("Database Password", text: $logIn.password)
                }.disabled(!canEdit)
                List{
                    Picker("Choose a server", selection: $selectedServer) {
                        // 4. Loop through the array to create options.
                        ForEach(defaultRec.pastHosts, id: \.self) { host in
                            Text(host)
                        }
                        Divider()
                        Text("Different Server").tag("other")
                        
                    }
                    if selectedServer == "other" {
                        TextField("Other Server", text: $otherServer)
                    }
                    
                    
                    // .keyboardType(.emailAddress) // Use appropriate keyboard type
                }
                Toggle("Can edit", isOn: $canEdit)
                
                //   Section {
                Button("Login") {
                    print("Saving data...")
                    var logInLocal = logIn
                    if selectedServer == "other" {
                        logInLocal.host = otherServer
                    }
                    else{
                        logInLocal.host = selectedServer
                    }
                  
                    
                    globalData.loggedInRec = logInLocal
                    hostStr = logInLocal.host
                    
                    Task {
                        do {
                            try await DatabaseManager.shared.connect(logInRec: logInLocal)
                            // Pre-load column metadata for all tables
                            await ColumnMetadataCache.shared.loadAll()
                            
                            logIn = logInLocal
                            globalData.loggedIn = true
                            defaultRec.hostString = logInLocal.host
                            
                            if selectedServer == "other" {
                                defaultRec.pastHosts.append(otherServer)
                            }
                            
                            saveUserDefaults(defaultRec)
                            saveNamePW()
                        } catch {
                            print("\(logInLocal.host) is not a valid Postgres server address: \(error)")
                            showAlert = true
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .alert("Important message", isPresented: $showAlert) {
                    // Actions (Buttons) can be added here.
                    Button("OK", role: .cancel) {
                        // Optional: add extra functionality here beyond dismissal.
                        print("Alert dismissed")
                    }
                } message: {
                    // 4. Add an optional message text.
                    Text("\(hostStr) is not a valid Postgres server address")
                }
                
                Spacer()
            }
            Spacer()
            //   }
        }.frame(width: 370, height: 325)
            .task {
                logIn.host = defaultRec.hostString
                selectedServer = defaultRec.hostString
                logIn.username = self.nmpw.username
                logIn.password = self.nmpw.password
            }
    }
    
    static func getUserDefaults() -> DefaultRec {
        if let data = UserDefaults.standard.data(forKey: UserDefaultKey) {
            let decoder = JSONDecoder()
            guard let decoded = try? decoder.decode(DefaultRec.self, from: data) else {
                fatalError("Failed to decode DefaultRec from saved data.")
            }
            return decoded
        } else {
            let defaultRec = DefaultRec()
            UserDefaults.standard.set(try? JSONEncoder().encode(defaultRec), forKey: UserDefaultKey)
            return defaultRec
        }
    }
    
    func saveUserDefaults(_ defaultRec: DefaultRec) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(defaultRec) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultKey)
        } else {
            fatalError("Failed to encode DefaultRec.")
        }
    }
    
    static func getNamePW()->logData{
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let simpleKeyChain = SimpleKeychain() // service: "com.pgAdmin.logIn")
        var result = logData()
        
        if let data = try? simpleKeyChain.data(forKey: pwKey) {
            let decoded = try? decoder.decode(logData.self, from: data)
            result = decoded!
        }
        else{
            if  let encoded = try? encoder.encode(result) {
                _ = try? simpleKeyChain.set(encoded, forKey: pwKey)
            }
        }
        
        return result
    }
    
    func saveNamePW(){
        let encoder = JSONEncoder()
        let simpleKeyChain = SimpleKeychain()
        if((logIn.username != nmpw.username) || (logIn.password != nmpw.password)){
            let data = logData(username: logIn.username, password: logIn.password)
            nmpw = data
            if let encoded = try? encoder.encode(data) {
                _ = try? simpleKeyChain.set(encoded, forKey: pwKey)
            }
        }
    }
}



#Preview {
    //  LogInIView()
}
