//
//  normal_data.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/8/26.
//

import Foundation

/// Documentation template for your custom Swift document
struct normalData: Identifiable, Equatable, Hashable {
    // Add your boilerplate properties and functions here
    var id: Int = 0
    var mean: Int = 0
    var excellent: Int = 0
    var good: Int = 0
    var fair: Int = 0
    var poor: Int = 0
    var veryPoor: Int = 0
    var gender: String = ""
    var agerange: String = ""
    var lowage: Int = 0
    var highage: Int = 0
    var normid: Int = 0
    var testtable_id: Int = 0
    
    var dataDict: DictListType = [:]
    
    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "normal_data") {
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
    
    static func == (lhs: normalData, rhs: normalData) -> Bool {
        return
        lhs.id == rhs.id &&
        lhs.mean == rhs.mean &&
        lhs.excellent == rhs.excellent &&
        lhs.good == rhs.good &&
        lhs.fair == rhs.fair &&
        lhs.poor == rhs.poor &&
        lhs.veryPoor == rhs.veryPoor &&
        lhs.gender == rhs.gender &&
        lhs.agerange == rhs.agerange &&
        lhs.lowage == rhs.lowage &&
        lhs.highage == rhs.highage &&
        lhs.normid == rhs.normid &&
        lhs.testtable_id == rhs.testtable_id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        self.recToDict()
        let tdC = normal_dataClass()
       id = await tdC.saveDictionary(dict: self.dataDict)
    }
    
    mutating func dictToRec(dict: DictListType)
    {
        dataDict = dict
        readDictValues()
    }
    
    /* var id: Int = 0
     var mean: Int = 0
     var excellent: Int = 0
     var good: Int = 0
     var fair: Int = 0
     var poor: Int = 0
     var veryPoor: Int = 0
     var gender: String = ""
     var agerange: String = ""
     var lowage: Int = 0
     var highage: Int = 0
     var normid: Int = 0
     var testtable_id: Int = 0
     */
    mutating func readDictValues(){
        id = dictKeyToInt(key: "id", dict: dataDict)
        mean = dictKeyToInt(key: "mean", dict: dataDict)
        excellent = dictKeyToInt(key: "excellent", dict: dataDict)
        good = dictKeyToInt(key: "good", dict: dataDict)
        fair = dictKeyToInt(key: "fair", dict: dataDict)
        poor = dictKeyToInt(key: "poor", dict: dataDict)
        veryPoor = dictKeyToInt(key: "veryPoor", dict: dataDict)
        gender = dictKeyToStr(key: "gender", dict: dataDict)
        agerange = dictKeyToStr(key: "agerange", dict: dataDict)
        lowage = dictKeyToInt(key: "lowage", dict: dataDict)
        highage = dictKeyToInt(key: "highage", dict: dataDict)
        normid = dictKeyToInt(key: "normid", dict: dataDict)
        
        testtable_id = dictKeyToInt(key: "testtable_id", dict: dataDict)
        

    }
    
    mutating func recToDict(){
        var localDict:DictListType = self.dataDict
        localDict["id"]?.strVal = String(id)
        localDict["mean"]?.strVal = String(mean)
        localDict["excellent"]?.strVal = String(excellent)
        localDict["good"]?.strVal = String(good)
        localDict["fair"]?.strVal = String(fair)
        localDict["poor"]?.strVal = String(poor)
        localDict["veryPoor"]?.strVal = String(veryPoor)
        localDict["gender"]?.strVal = gender
        localDict["agerange"]?.strVal = agerange
        localDict["lowage"]?.strVal = String(lowage)
        localDict["highage"]?.strVal = String(highage)
        localDict["normid"]?.strVal = String(normid)
        localDict["testtable_id"]?.strVal = String(testtable_id)
      
        self.dataDict = localDict
    }


}


class normal_dataClass: pgClientClass {
    
    init(doAlert: AlertManager? = nil){
        super.init(doAlert: doAlert,
                   tName: "normal_data",
                   pkField: "id")
    }
    
    
    func buildPatientist() async -> [normalData]{
        var text: String = ""
        var result: [normalData] = []
        
        text = "SELECT * FROM public.normal_data  ORDER BY id ASC ;"
        
        await executeQuery(text: text)
        var thenormal_data = normalData() // = EmployeeData()
        
        for item in dictList{
            thenormal_data.dictToRec(dict: item)
            result.append(thenormal_data)
        }

        return result
        
    }
}

