//
//  TestDateFile.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/7/26.
//

import Foundation

struct TestDateData: Identifiable, Codable, Equatable, Hashable{
    var id: Int = 0
    var testdate: Date?
    var cervical: Bool = false
    var lumbar: Bool = false
    var cardio: Bool = false
    var is_baseline: Bool = true
    var fri: Double = 0.0
    var fri_pain: Double = 0.0
    var bp_systolic: Int = 0
    var bp_diastolic: Int = 0
    var heart_rate: Int = 0
    var pt_id: Int = 0
    var physician_id: Int = 0
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, testdate, cervical, lumbar, cardio, is_baseline,
             fri, fri_pain, bp_systolic, bp_diastolic, heart_rate, pt_id, physician_id
    }

    init(){
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "testdate") {
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
    
    static func == (lhs: TestDateData, rhs: TestDateData) -> Bool {
        return
        lhs.id == rhs.id &&
        lhs.testdate == rhs.testdate &&
        lhs.cervical == rhs.cervical &&
        lhs.lumbar == rhs.lumbar &&
        lhs.cardio == rhs.cardio &&
        lhs.is_baseline == rhs.is_baseline &&
        lhs.fri == rhs.fri &&
        lhs.fri_pain == rhs.fri_pain &&
        lhs.bp_systolic == rhs.bp_systolic &&
        lhs.bp_diastolic == rhs.bp_diastolic &&
        lhs.heart_rate == rhs.heart_rate &&
        lhs.pt_id == rhs.pt_id  &&
        lhs.physician_id == rhs.physician_id
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    

    func deleteRec() async {
        let tdC = testDateClass()
         await tdC.deleteRec(dict: self.dataDict)
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
