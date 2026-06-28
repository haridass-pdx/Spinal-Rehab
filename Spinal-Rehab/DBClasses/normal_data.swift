//
//  normal_data.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/8/26.
//

import Foundation

/// Documentation template for your custom Swift document
struct normalData: Identifiable, Codable, Equatable, Hashable {
    // Add your boilerplate properties and functions here
    var id: Int = 0
    var mean: Int = 0
    var excellent: Int = 0
    var good: Int = 0
    var fair: Int = 0
    var poor: Int = 0
    var verypoor: Int = 0
    var gender: String = ""
    var agerange: String = ""
    var lowage: Int = 0
    var highage: Int = 0
    var normid: Int = 0
    var testtable_id: Int = 0

    var dataDict: DictListType = [:]

    // Only stored scalars participate in Codable; dataDict is the cached column-info sidecar.
    enum CodingKeys: String, CodingKey {
        case id, mean, excellent, good, fair, poor, verypoor, gender
        case agerange = "agerange"   // DB column is age_range; Swift property is agerange
        case lowage, highage, normid, testtable_id
    }

    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "normal_data") {
            initDictionary(colNames: info.colNames, colTypes: info.colTypes)
        }
    }
    
    func description() -> String {
        return " ID: \(self.id), mean:\(self.mean), excellent: \(self.excellent), good: \(self.good), fair: \(self.fair), poor: \(self.poor), verypoor: \(self.verypoor) , gender: \(self.gender), agerange: \(self.agerange), lowage: \(self.lowage), highage: \(self.highage), normid: \(self.normid), testtable_id: \(self.testtable_id) \n"
    }

    
    mutating func initDictionary(colNames: [String], colTypes: [colTypes]){
        var row: [String: DictValue] = [:]
        for (key, itemType) in Swift.zip(colNames, colTypes) {
            let dictItem: DictValue = DictValue(strVal: "", type: itemType)
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
        lhs.verypoor == rhs.verypoor &&
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
    
    mutating func readDictValues() {
        let strs = dataDict.mapValues { $0.strVal }
        guard let decoded = try? DictDecoder().decode(Self.self, from: strs) else { return }
        let savedDict = self.dataDict
        self = decoded
        self.dataDict = savedDict
    }

    mutating func recToDict() {
        guard let strs = try? DictEncoder().encode(self) else { return }
        for (k, v) in strs {
            dataDict[k]?.strVal = v
        }
    }


}


class normal_dataClass: pgClientClass {
    
    init(doAlert: AlertManager? = nil){
        super.init(doAlert: doAlert,
                   tName: "normal_data",
                   pkField: "id")
    }
    
    
    func buildNormalList() async -> [normalData]{
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
    
    func buildNormalList(id: Int) async -> [normalData]{
        var text: String = ""
        var result: [normalData] = []
        
        text = "SELECT * FROM public.normal_data where testtable_id = \(id) ORDER BY id ASC ;"
        
        await executeQuery(text: text)
        var thenormal_data = normalData()
        
        for item in dictList{
            thenormal_data.dictToRec(dict: item)
            result.append(thenormal_data)
        }

        return result
    }
    
    func getNormaData(tableID:  Int, gender: String) async-> normalData?{
        var result: normalData?
        let text: String = "SELECT * FROM public.normal_data WHERE testtable_id = \(tableID) and gender = '\(gender)';"
        
        _ = await executeQuery(text: text)
      
        var thenormal_data = normalData() // = EmployeeData()
      
        for item in dictList{
            thenormal_data.dictToRec(dict: item)
            result = thenormal_data
        }

        return result
    }
    
    func getNormaData(tableID:  Int, gender: String, age:  Int) async-> normalData?{
        var result: normalData?
        let text: String = "SELECT * FROM public.normal_data WHERE testtable_id = \(tableID) and gender = '\(gender)' and \(age) between lowage and highage;"
        
        _ = await executeQuery(text: text)
      
        var thenormal_data = normalData() // = EmployeeData()
      
        for item in dictList{
            thenormal_data.dictToRec(dict: item)
            result = thenormal_data
        }

        return result
    }
    
}

