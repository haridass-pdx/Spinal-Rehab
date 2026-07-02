//
//  PhysicanClass.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 7/1/26.
//

import Foundation

struct PhysicianRec: Identifiable, Equatable, Hashable {
    var id: Int = 0
    var lastname: String = ""
    var firstname: String = ""
    var fullname: String { "\(firstname) \(lastname), \(degree)" }
    var degree: String = ""

    var dataDict: DictListType = [:]

    init() {
        // Load column layout from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "physicians") {
            initDictionary(colNames: info.colNames, colTypes: info.colTypes)
        }
    }

    mutating func initDictionary(colNames: [String], colTypes: [colTypes]) {
        var row: [String: DictValue] = [:]
        for (key, itemType) in Swift.zip(colNames, colTypes) {
            row[key] = DictValue(strVal: "", type: itemType)
        }
        dataDict = row
    }

    static func == (lhs: PhysicianRec, rhs: PhysicianRec) -> Bool {
        lhs.id == rhs.id &&
        lhs.lastname == rhs.lastname &&
        lhs.firstname == rhs.firstname &&
        lhs.degree == rhs.degree
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let pc = physicianClass()
        id = await pc.saveDictionary(dict: dataDict)
    }

    mutating func deleteRec() async {
        recToDict()
        let pc = physicianClass()
        await pc.deleteRec(dict: dataDict)
    }

    mutating func dictToRec(dict: DictListType) {
        dataDict = dict
        readDictValues()
    }

    mutating func readDictValues() {
        id = dictKeyToInt(key: "id", dict: dataDict)
        lastname = dictKeyToStr(key: "lastname", dict: dataDict)
        firstname = dictKeyToStr(key: "firstname", dict: dataDict)
        degree = dictKeyToStr(key: "degree", dict: dataDict)
    }

    mutating func recToDict() {
        var localDict: DictListType = dataDict
        localDict["id"]?.strVal = String(id)
        localDict["lastname"]?.strVal = lastname
        localDict["firstname"]?.strVal = firstname
        localDict["degree"]?.strVal = degree
        dataDict = localDict
    }
}

class physicianClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "physicians",
                   pkField: "id")
    }

    func buildPhysicianList() async -> [PhysicianRec] {
        var result: [PhysicianRec] = []
        let text = "SELECT * FROM public.physicians ORDER BY lastname ASC ;"

        await executeQuery(text: text)
        var thePhysician = PhysicianRec()

        for item in dictList {
            thePhysician.dictToRec(dict: item)
            result.append(thePhysician)
        }
        return result
    }

    func getPhysician(id: Int) async -> PhysicianRec? {
        var result: PhysicianRec?
        let text = "SELECT * FROM public.physicians WHERE id = \(id);"

        await executeQuery(text: text)
        var thePhysician = PhysicianRec()

        for item in dictList {
            thePhysician.dictToRec(dict: item)
            result = thePhysician
        }
        return result
    }
}
