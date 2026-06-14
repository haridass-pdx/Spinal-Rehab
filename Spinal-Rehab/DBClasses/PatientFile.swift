//
//  PatientFile.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/6/26.
//

import Foundation
import PostgresNIO



struct PatientData: Identifiable, Equatable, Hashable{
    var id: Int = 0
    var lastname: String = ""
    var firstname: String = ""
    var fullname: String {
        get {
            return "\(firstname) \(lastname)"
        }
    }
    var street: String = ""
    var city: String = ""
    var state: String = ""
    var zip: String = ""
    var phone: String = ""
    var dob: Date?
    var age: Int = 0
    var email: String = ""
    var gender: String = ""
    var dataDict: DictListType = [:]
  
    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "patients") {
            initDictionary(colNames: info.colNames, colTypes: info.colTypes)
        }
    }
    
    mutating func initDictionary(colNames: [String], colTypes: [colTypes]){
        var row: [String: DictValue] = [:]
        for (key, itemType) in Swift.zip(colNames, colTypes) {
            let dictItem = DictValue(strVal: "", type: itemType)
            row[key] = dictItem
        }
        dataDict = row
    }
    
    static func == (lhs: PatientData, rhs: PatientData) -> Bool {
        return
        lhs.id == rhs.id &&
        lhs.lastname == rhs.lastname &&
        lhs.firstname == rhs.firstname &&
        lhs.city == rhs.city &&
        lhs.state == rhs.state &&
        lhs.zip == rhs.zip &&
        lhs.phone == rhs.phone &&
        lhs.dob == rhs.dob &&
        lhs.age == rhs.age &&
        lhs.email == rhs.email &&
        lhs.gender == rhs.gender
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    mutating func saveRec() async {
        self.recToDict()
        let ptC = patientClass()
       id = await ptC.saveDictionary(dict: self.dataDict)
    }
    
    
    mutating func dictToRec(dict: DictListType)
    {
        dataDict = dict
        readDictValues()
    }
    
    mutating func readDictValues(){
        let empID = dataDict["id"]?.strVal ?? "0"
        
        self.id = Int(empID) ?? 0
        self.firstname = dataDict["firstname"]?.strVal ?? ""
        self.lastname = dataDict["lastname"]?.strVal ?? ""
        self.street = dataDict["street"]?.strVal ?? ""
        self.city = dataDict["city"]?.strVal ?? ""
        self.state = dataDict["state"]?.strVal ?? ""
        self.zip = dataDict["zip"]?.strVal ?? ""
        self.phone = dataDict["phone"]?.strVal ?? ""
        self.email = dataDict["email"]?.strVal ?? ""
        self.age = dictKeyToInt(key: "age", dict: dataDict)
        self.gender = dataDict["gender"]?.strVal ?? ""
        self.dob = dictDateStringToDate(key: "dob",
                                        dict: dataDict)
        
      
    }

    
    mutating func recToDict(){
        var localDict:DictListType = self.dataDict
        localDict["id"]?.strVal = String(id)
        localDict["firstname"]?.strVal =  self.firstname
        localDict["lastname"]?.strVal = self.lastname
        localDict["street"]?.strVal = self.street
        localDict["city"]?.strVal = self.city
        localDict["state"]?.strVal = self.state
        localDict["zip"]?.strVal = self.zip
        localDict["phone"]?.strVal = self.phone
        localDict["email"]?.strVal = self.email
        localDict["gender"]?.strVal = self.gender
        
        localDict["dob"]?.strVal = getDateOptString( from: dob,
                                                     formatStr: "yyyy-MM-dd")
   
        self.dataDict = localDict
        
    }
}

class patientClass: pgClientClass {
    
    init(doAlert: AlertManager? = nil){
        super.init(doAlert: doAlert,
                   tName: "patients",
                   pkField: "id")
    }

    func buildPatientist() async -> [PatientData]{
        var text: String = ""
        var result: [PatientData] = []
        text = "SELECT * FROM public.patients  ORDER BY id ASC ;"
        
        await executeQuery(text: text)
        var thePatient = PatientData() // = EmployeeData()
        
        for person in dictList{
            thePatient.dictToRec(dict: person)
            result.append(thePatient)
        }
        

     
        return result
    }

}
