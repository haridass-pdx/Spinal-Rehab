//
//  RehabProgramFile.swift
//  Spinal-Rehab
//
//  Data access for the rehab_program and rehab_program_list tables:
//  reusable "standard" recommendation programs that get copied into a
//  patient_rehab_program (see PatientRehabFile).
//

import Foundation

struct RehabProgramData: Identifiable, Codable, Equatable, Hashable {
    var id: Int = 0
    var name: String = ""
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, name
    }

    init() {
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "rehab_program") {
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

    static func == (lhs: RehabProgramData, rhs: RehabProgramData) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let rpC = rehab_programClass()
        id = await rpC.saveDictionary(dict: dataDict)
    }

    /// Deletes the program and its rehab_program_list rows.
    func deleteRec() async {
        let rpC = rehab_programClass()
        await rpC.executeQueryND(text: "DELETE FROM rehab_program_list WHERE rehab_id = \(id);")
        await rpC.deleteRec(dict: dataDict)
    }

    mutating func dictToRec(dict: DictListType) {
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

class rehab_programClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "rehab_program",
                   pkField: "id")
    }

    func buildProgramList() async -> [RehabProgramData] {
        var result: [RehabProgramData] = []
        let text = "SELECT * FROM public.rehab_program ORDER BY name ASC ;"

        await executeQuery(text: text)
        var theProgram = RehabProgramData()

        for item in dictList {
            theProgram.dictToRec(dict: item)
            result.append(theProgram)
        }
        return result
    }
}

// MARK: - rehab_program_list

struct RehabProgramListData: Identifiable, Codable, Equatable, Hashable {
    var id: Int = 0
    var rehab_id: Int = 0
    var exercise_id: Int = 0
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, rehab_id, exercise_id
    }

    init() {
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "rehab_program_list") {
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

    static func == (lhs: RehabProgramListData, rhs: RehabProgramListData) -> Bool {
        lhs.id == rhs.id &&
        lhs.rehab_id == rhs.rehab_id &&
        lhs.exercise_id == rhs.exercise_id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let rlC = rehab_program_listClass()
        id = await rlC.saveDictionary(dict: dataDict)
    }

    func deleteRec() async {
        let rlC = rehab_program_listClass()
        await rlC.deleteRec(dict: dataDict)
    }

    mutating func dictToRec(dict: DictListType) {
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

class rehab_program_listClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "rehab_program_list",
                   pkField: "id")
    }

    func buildExerciseList(rehabId: Int) async -> [RehabProgramListData] {
        var result: [RehabProgramListData] = []
        let text = "SELECT * FROM public.rehab_program_list WHERE rehab_id = \(rehabId) ORDER BY id ASC ;"

        await executeQuery(text: text)
        var theItem = RehabProgramListData()

        for item in dictList {
            theItem.dictToRec(dict: item)
            result.append(theItem)
        }
        return result
    }
}
