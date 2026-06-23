//
//  Patient_test.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/7/26.
//

import Foundation

/// Documentation template for your custom Swift document
struct PatienttestData: Identifiable, Equatable, Hashable {
    // Add your boilerplate properties and functions here
    var id: Int = 0
    var testname: String = ""
    var testvalue: Double = 0.0
    var testscore: String = ""
    var testdate_id: Int = 0
    var pt_id: Int = 0
          
    var dataDict: DictListType = [:]
    
    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "patient_test") {
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
    
    static func == (lhs: PatienttestData, rhs: PatienttestData) -> Bool {
        return
        lhs.id == rhs.id  &&
        lhs.testname == rhs.testname &&
        lhs.testvalue == rhs.testvalue &&
        lhs.testscore == rhs.testscore &&
        lhs.testdate_id == rhs.testdate_id &&
        lhs.pt_id == rhs.pt_id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        self.recToDict()
        let tdC = Patient_testClass()
       id = await tdC.saveDictionary(dict: self.dataDict)
    }
    
    mutating func dictToRec(dict: DictListType)
    {
        dataDict = dict
        readDictValues()
    }
    
    /*
     lhs.id == rhs.id  &&
     lhs.testname == rhs.testname &&
     lhs.testvalue == rhs.testvalue &&
     lhs.testscores == rhs.testscores &&
     lhs.testdate_id == rhs.testdate_id &&
     lhs.pt_id == rhs.pt_id     */
    
    mutating func readDictValues(){
         id = dictKeyToInt(key: "id", dict: dataDict)
        testname = dictKeyToStr(key: "testname", dict: dataDict)
        testvalue = dictKeyToDouble(key: "testvalue", dict: dataDict)

        testscore = dictKeyToStr(key: "testscore", dict: dataDict)
        testdate_id = dictKeyToInt(key: "testdate_id", dict: dataDict)
        pt_id = dictKeyToInt(key: "pt_id", dict: dataDict)
  
    }
    
    mutating func recToDict(){
        var localDict:DictListType = self.dataDict
        localDict["id"]?.strVal = String(id)
        localDict["testname"]?.strVal = testname
        localDict["testvalue"]?.strVal = String(testvalue)
        localDict["testscore"]?.strVal = testscore
        localDict["testdate_id"]?.strVal = String(testdate_id)
        localDict["pt_id"]?.strVal = String(pt_id)
        self.dataDict = localDict
    }
}


class Patient_testClass: pgClientClass {
    
    init(doAlert: AlertManager? = nil){
        super.init(doAlert: doAlert,
                   tName: "patient_test",
                   pkField: "id")
    }
    
    
    func buildPtTestList(pttestid: Int) async -> [PatienttestData]{
        var text: String = ""
        var result: [PatienttestData] = []
        
        text = "SELECT * FROM public.patient_test Where testdate_id = \(pttestid) ORDER BY id ASC ;"
        
        await executeQuery(text: text)
        var thePtTest  = PatienttestData() // = EmployeeData()
        
        for item in dictList{
            thePtTest.dictToRec(dict: item)
            result.append(thePtTest)
        }

        return result
        
    }
}

