//
//  test_table.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/9/26.
//

import Foundation

/// Documentation template for your custom Swift document
struct test_tableData: Identifiable, Equatable, Hashable {
    // Add your boilerplate properties and functions here
    var id: Int = 0
    var name: String = ""
    var description: String = ""
    var testflag: Bool = false
    var agegroups: Bool = false
    var greaterisbetter: Bool = false
    var dataDict: DictListType = [:]
    
    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "test_table") {
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

    static func == (lhs: test_tableData, rhs: test_tableData) -> Bool {
        return
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.testflag == rhs.testflag &&
        lhs.agegroups == rhs.agegroups &&
        lhs.greaterisbetter == rhs.greaterisbetter
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        self.recToDict()
        let tdC = test_tableClass()
       id = await tdC.saveDictionary(dict: self.dataDict)
    }
    
    mutating func dictToRec(dict: DictListType)
    {
        dataDict = dict
        readDictValues()
    }
    
      mutating func readDictValues(){
        id = dictKeyToInt(key: "id", dict: dataDict)
        name = dictKeyToStr(key: "name", dict: dataDict)
        description = dictKeyToStr(key: "description", dict: dataDict)
        testflag = dictKeyToBool(key: "testflag", dict: dataDict)
        agegroups = dictKeyToBool(key: "agegroups", dict: dataDict)
        greaterisbetter = dictKeyToBool(key: "greaterisbetter", dict: dataDict)
    }
    
    mutating func recToDict(){
        var localDict:DictListType = self.dataDict
        localDict["id"]?.strVal = String(id)
        localDict["name"]?.strVal = name
        localDict["description"]?.strVal = description
        localDict["testflag"]?.strVal = boolToString(bool: testflag)
        localDict["agegroups"]?.strVal = boolToString(bool: agegroups)
        localDict["greaterisbetter"]?.strVal = boolToString(bool: greaterisbetter)
        
        self.dataDict = localDict
    }


}


class test_tableClass: pgClientClass {
    
    init(doAlert: AlertManager? = nil){
        super.init(doAlert: doAlert,
                   tName: "test_table",
                   pkField: "id")
    }
    
    
    func buildTesttist() async -> [test_tableData]{
        var text: String = ""
        var result: [test_tableData] = []
        
        text = "SELECT * FROM public.test_table  ORDER BY id ASC ;"
        
        await executeQuery(text: text)
        var thetest_table = test_tableData() // = EmployeeData()
        
        for item in dictList{
            thetest_table.dictToRec(dict: item)
            result.append(thetest_table)
        }

        return result
        
    }
    class func getTestNameList() async -> [String]{
        var result: [String] = []
        let ttc = test_tableClass()
        let sql = "SELECT name FROM public.test_table   ;"
        result = await ttc.getResults(qry: sql)
         
     return result
    }

    
    func getTestTableItem(name: String) async -> test_tableData?{
        var result: test_tableData?
        let ttc = test_tableClass()
        let qry = "SELECT * FROM public.test_table WHERE name = '\(name)\';"
        await executeQuery(text: qry)
        var thetest_table = test_tableData() // = EmployeeData()
        
        for item in dictList{
            thetest_table.dictToRec(dict: item)
            result = thetest_table
        }
      return result
    }
    
       
    class func getScoreForTest(testName: String, age: Int, Gender: String, Value: Double) async -> String{
        var score: String = ""
        let ttc = test_tableClass()
        if let result  = await ttc.getTestTableItem(name: testName){
            let ndc = normal_dataClass()
            if result.agegroups{
                if let ndr = await ndc.getNormaData(tableID: result.id, gender: Gender, age: age){
                    score = getScoreFromValue(ndr: ndr, Value: Value, greaterIsBetter: result.greaterisbetter)
                }
                
            }
            else {
                if let ndr = await ndc.getNormaData(tableID: result.id, gender: Gender){
                    score = getScoreFromValue(ndr: ndr, Value: Value, greaterIsBetter: result.greaterisbetter)
                }
            }
        }
        
        return score
    }
    
    class func getScoreFromValue(ndr: normalData, Value: Double, greaterIsBetter: Bool) -> String{
        var result : String = ""
        
        if(greaterIsBetter){
            switch Value {
            case let v where v > Double(ndr.excellent):
                result = "Excellent"
            case let v where v > Double(ndr.good):
                result = "Good"
            case let v where v > Double(ndr.fair):
                result = "Fair"
            case let v where v > Double(ndr.poor):
                result = "Poor"
            default: result = "Very Poor"
            }
            
        }
        else{
            switch Value {
            case let v where v < Double(ndr.excellent):
                result = "Excellent"
            case let v where v < Double(ndr.good):
                result = "Good"
            case let v where v < Double(ndr.fair):
                result = "Fair"
            case let v where v < Double(ndr.poor):
                result = "Poor"
            default: result = "Very Poor"
            }
            

        }
    
        return result
    }
    
}

