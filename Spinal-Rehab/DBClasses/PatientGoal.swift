//
//  PatientGoal.swift
//  Spinal-Rehab
//
//  Data access for the patient_goals table: goal-setting sessions
//  recorded for a patient over time (target values and dates for
//  cervical flexion, lumbar extension, and sit-to-stand).
//

import Foundation

struct PatientDataGoal: Identifiable, Codable, Equatable, Hashable {
    var id: Int = 0
    var patient_id: Int = 0
    var goal_date: Date?
    var cerv_flex_goal: Double = 0.0
    var cerv_flex_td: Date?
    var lumbar_ext_goal: Double = 0.0
    var lumbar_ext_td: Date?
    var sit_stand_goal: Double = 0.0
    var sit_stand_td: Date?
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, patient_id, goal_date, cerv_flex_goal, cerv_flex_td,
             lumbar_ext_goal, lumbar_ext_td, sit_stand_goal, sit_stand_td
    }

    init() {
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "patient_goals") {
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

    static func == (lhs: PatientDataGoal, rhs: PatientDataGoal) -> Bool {
        lhs.id == rhs.id &&
        lhs.patient_id == rhs.patient_id &&
        lhs.goal_date == rhs.goal_date &&
        lhs.cerv_flex_goal == rhs.cerv_flex_goal &&
        lhs.cerv_flex_td == rhs.cerv_flex_td &&
        lhs.lumbar_ext_goal == rhs.lumbar_ext_goal &&
        lhs.lumbar_ext_td == rhs.lumbar_ext_td &&
        lhs.sit_stand_goal == rhs.sit_stand_goal &&
        lhs.sit_stand_td == rhs.sit_stand_td
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let gC = patient_goalsClass()
        id = await gC.saveDictionary(dict: dataDict)
        // saveDictionary returns the new row's id on insert, but dataDict
        // still holds the pre-save "0" — without this, an immediate
        // deleteRec()/saveRec() on this same instance would target id=0.
        dataDict["id"]?.strVal = String(id)
    }

    func deleteRec() async {
        let gC = patient_goalsClass()
        await gC.deleteRec(dict: dataDict)
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

class patient_goalsClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "patient_goals",
                   pkField: "id")
    }

    func buildGoalList(patientId: Int) async -> [PatientDataGoal] {
        var result: [PatientDataGoal] = []
        let text = "SELECT * FROM public.patient_goals WHERE patient_id = \(patientId) ORDER BY goal_date ASC ;"

        await executeQuery(text: text)
        var theGoal = PatientDataGoal()

        for item in dictList {
            theGoal.dictToRec(dict: item)
            result.append(theGoal)
        }
        return result
    }
}
