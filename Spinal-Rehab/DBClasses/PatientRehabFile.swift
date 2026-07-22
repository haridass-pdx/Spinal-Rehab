//
//  PatientRehabFile.swift
//  Spinal-Rehab
//
//  Data access for the patient_rehab_program and patient_rehab_list tables:
//  the recommendations assigned to a specific patient after testing.
//

import Foundation

struct PatientRehabProgramData: Identifiable, Codable, Equatable, Hashable {
    var id: Int = 0
    var patient_id: Int = 0
    var prdate: Date?
    var name: String = ""
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, patient_id, prdate, name
    }

    init() {
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "patient_rehab_program") {
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

    static func == (lhs: PatientRehabProgramData, rhs: PatientRehabProgramData) -> Bool {
        lhs.id == rhs.id &&
        lhs.patient_id == rhs.patient_id &&
        lhs.prdate == rhs.prdate &&
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let prC = patient_rehab_programClass()
        id = await prC.saveDictionary(dict: dataDict)
    }

    /// Deletes the program and its patient_rehab_list rows.
    func deleteRec() async {
        let prC = patient_rehab_programClass()
        await prC.executeQueryND(text: "DELETE FROM patient_rehab_list WHERE patient_rehab_id = \(id);")
        await prC.deleteRec(dict: dataDict)
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

class patient_rehab_programClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "patient_rehab_program",
                   pkField: "id")
    }

    func buildProgramList(patientId: Int) async -> [PatientRehabProgramData] {
        var result: [PatientRehabProgramData] = []
        let text = "SELECT * FROM public.patient_rehab_program WHERE patient_id = \(patientId) ORDER BY prdate ASC ;"

        await executeQuery(text: text)
        var theProgram = PatientRehabProgramData()

        for item in dictList {
            theProgram.dictToRec(dict: item)
            result.append(theProgram)
        }
        return result
    }

    /// Copy a standard rehab_program into a new program for a patient, seeding
    /// each exercise's reps/sets from the exercise defaults. Returns the saved
    /// program (nil if the standard program doesn't exist).
    class func addProgram(rehabId: Int, patientId: Int, date: Date = Date()) async -> PatientRehabProgramData? {
        let standardList = await rehab_programClass().buildProgramList()
        guard let standard = standardList.first(where: { $0.id == rehabId }) else { return nil }

        var program = PatientRehabProgramData()
        program.patient_id = patientId
        program.prdate = date
        program.name = standard.name
        await program.saveRec()

        let exC = exerciseClass()
        let items = await rehab_program_listClass().buildExerciseList(rehabId: rehabId)
        for item in items {
            var listRec = PatientRehabListData()
            listRec.patient_rehab_id = program.id
            listRec.exercise_id = item.exercise_id
            if let exercise = await exC.getExercise(id: item.exercise_id) {
                listRec.reps = exercise.def_reps
                listRec.sets = exercise.def_sets
            }
            await listRec.saveRec()
        }
        return program
    }
}

// MARK: - patient_rehab_list

struct PatientRehabListData: Identifiable, Codable, Equatable, Hashable {
    var id: Int = 0
    var patient_rehab_id: Int = 0
    var exercise_id: Int = 0
    var reps: Int = 0
    var sets: Int = 0
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, patient_rehab_id, exercise_id, reps, sets
    }

    init() {
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "patient_rehab_list") {
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

    static func == (lhs: PatientRehabListData, rhs: PatientRehabListData) -> Bool {
        lhs.id == rhs.id &&
        lhs.patient_rehab_id == rhs.patient_rehab_id &&
        lhs.exercise_id == rhs.exercise_id &&
        lhs.reps == rhs.reps &&
        lhs.sets == rhs.sets
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let plC = patient_rehab_listClass()
        id = await plC.saveDictionary(dict: dataDict)
    }

    func deleteRec() async {
        let plC = patient_rehab_listClass()
        await plC.deleteRec(dict: dataDict)
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

class patient_rehab_listClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "patient_rehab_list",
                   pkField: "id")
    }

    func buildExerciseList(programId: Int) async -> [PatientRehabListData] {
        var result: [PatientRehabListData] = []
        let text = "SELECT * FROM public.patient_rehab_list WHERE patient_rehab_id = \(programId) ORDER BY id ASC ;"

        await executeQuery(text: text)
        var theItem = PatientRehabListData()

        for item in dictList {
            theItem.dictToRec(dict: item)
            result.append(theItem)
        }
        return result
    }
}
