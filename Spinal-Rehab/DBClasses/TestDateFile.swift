//
//  TestDateFile.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/7/26.
//

import Foundation

struct TestDateData: Identifiable, Equatable, Hashable{
    var id: Int = 0
    var testdate: Date?
    var cervical: Bool = false
    var lumbar: Bool = false
    var aerobic: Bool = false
    var is_baseline: Bool = true
    var fri: Double = 0.0
    var fri_pain: Double = 0.0
    var bp_systolic: Int = 0
    var bp_diastolic: Int = 0
    var heart_rate: Int = 0
    var pt_id: Int = 0
    var dataDict: DictListType = [:]
    
    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "testdate") {
            initDictionary(colNames: info.colNames, colTypes: info.colTypes)
        }
    }
    
    mutating func initDictionary(colNames: [String], colTypes: [colTypes]){
        var row: [String: DictValue] = [:]
        for (key, itemType) in Swift.zip(colNames, colTypes) {
            let dictItem: DictValue = (strVal: "", type: itemType)
            row[key] = dictItem
        }
        dataDict = row
    }
    
    static func == (lhs: TestDateData, rhs: TestDateData) -> Bool {
        return
        lhs.id == rhs.id &&
        lhs.testdate == rhs.testdate &&
        lhs.cervical == rhs.cervical &&
        lhs.lumbar == rhs.lumbar &&
        lhs.aerobic == rhs.aerobic &&
        lhs.is_baseline == rhs.is_baseline &&
        lhs.fri == rhs.fri &&
        lhs.fri_pain == rhs.fri_pain &&
        lhs.bp_systolic == rhs.bp_systolic &&
        lhs.bp_diastolic == rhs.bp_diastolic &&
        lhs.heart_rate == rhs.heart_rate &&
        lhs.pt_id == rhs.pt_id
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    

    
    mutating func saveRec() async {
        self.recToDict()
        let tdC = testDateClass()
       id = await tdC.saveDictionary(dict: self.dataDict)
    }
    
    
    mutating func dictToRec(dict: DictListType)
    {
        dataDict = dict
        readDictValues()
    }
    
    mutating func readDictValues(){
        let theID = dataDict["id"]?.strVal ?? "0"
        
        self.id = Int(theID) ?? 0
        
        self.cervical = dictKeyToBool(key: "cervical",
                                      dict: dataDict)
        self.lumbar = dictKeyToBool(key: "lumbar",
                                      dict: dataDict)
        self.aerobic = dictKeyToBool(key: "aerobic",
                                      dict: dataDict)
        self.is_baseline = dictKeyToBool(key: "is_baseline",
                                      dict: dataDict)
        
        
        
        self.testdate = dictDateStringToDate(key: "testdate",
                                        dict: dataDict)
        self.fri =  dictKeyToDouble(key: "fri",
                                        dict: dataDict)
        
        self.fri_pain =  dictKeyToDouble(key: "fri_pain",
                                        dict: dataDict)
     
        self.bp_systolic = dictKeyToInt(key: "bp_systolic", dict: dataDict)
        self.bp_diastolic = dictKeyToInt(key: "bp_diastolic", dict: dataDict)
        self.heart_rate = dictKeyToInt(key: "heart_rate", dict: dataDict)
        self.pt_id = dictKeyToInt(key: "pt_id", dict: dataDict)
      }

    
    mutating func recToDict(){
        var localDict:DictListType = self.dataDict
        localDict["id"]?.strVal = String(id)
        localDict["pt_id"]?.strVal = String(pt_id)
        localDict["cervial"]?.strVal = boolToString(bool: cervical)
        localDict["lumbar"]?.strVal = boolToString(bool: lumbar)
        localDict["aerobic"]?.strVal = boolToString(bool: aerobic)
        localDict["is_baseline"]?.strVal = boolToString(bool: is_baseline)
        localDict["fri"]?.strVal = fri.description
        localDict["fri_pain"]?.strVal = fri_pain.description
        localDict["bp_systolic"]?.strVal = String(bp_systolic)
        localDict["bp_diastolic"]?.strVal = String(bp_diastolic)
        localDict["heart_rate"]?.strVal = String(heart_rate)
         localDict["testdate"]?.strVal = getDateOptString( from: testdate,
                                                     formatStr: "yyyy-MM-dd")
   
        self.dataDict = localDict
        
    }

}

class testDateClass: pgClientClass {
    
    init(doAlert: AlertManager? = nil){
        super.init(doAlert: doAlert,
                   tName: "testdate",
                   pkField: "id")
    }
    
    func buildPatientist(ptid: Int) async -> [TestDateData]{
        var text: String = ""
        var result: [TestDateData] = []
        text = "SELECT * FROM public.testdate where pt_id = \(ptid) ORDER BY id ASC ;"
        
        await executeQuery(text: text)
        var theTestDate = TestDateData() // = EmployeeData()
        
        for thedate in dictList{
            theTestDate.dictToRec(dict: thedate)
            result.append(theTestDate)
        }
        
        
        
        return result
    }
    
}
