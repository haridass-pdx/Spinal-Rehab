//
//  ExerciseFile.swift
//  Spinal-Rehab
//
//  Data access for the exercises and exercise_images tables.
//

import Foundation

struct ExerciseData: Identifiable, Codable, Equatable, Hashable {
    var id: Int = 0
    var name: String = ""
    var description: String = ""
    var def_reps: Int = 0
    var def_sets: Int = 0
    var dataDict: DictListType = [:]

    enum CodingKeys: String, CodingKey {
        case id, name, description, def_reps, def_sets
    }

    init() {
        // Load from cache if available
        if let info = ColumnMetadataCache.shared.getInfo(for: "exercises") {
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

    static func == (lhs: ExerciseData, rhs: ExerciseData) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.def_reps == rhs.def_reps &&
        lhs.def_sets == rhs.def_sets
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    mutating func saveRec() async {
        recToDict()
        let exC = exerciseClass()
        id = await exC.saveDictionary(dict: dataDict)
    }

    func deleteRec() async {
        let exC = exerciseClass()
        await exC.deleteRec(dict: dataDict)
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

class exerciseClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "exercises",
                   pkField: "id")
    }

    func buildExerciseList() async -> [ExerciseData] {
        var result: [ExerciseData] = []
        let text = "SELECT * FROM public.exercises ORDER BY name ASC ;"

        await executeQuery(text: text)
        var theExercise = ExerciseData()

        for item in dictList {
            theExercise.dictToRec(dict: item)
            result.append(theExercise)
        }
        return result
    }

    func getExercise(id: Int) async -> ExerciseData? {
        var result: ExerciseData?
        let text = "SELECT * FROM public.exercises WHERE id = \(id);"

        await executeQuery(text: text)
        var theExercise = ExerciseData()

        for item in dictList {
            theExercise.dictToRec(dict: item)
            result = theExercise
        }
        return result
    }
}

// MARK: - Exercise images (bytea)

/// One image row. `image` is raw bytes suitable for NSImage(data:).
struct ExerciseImageData: Identifiable, Equatable, Hashable {
    var id: Int = 0
    var exercise_link: Int = 0
    var image: Data = Data()

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// bytea can't travel through the string-based dict machinery, so images are
/// moved as hex: encode(image,'hex') on read, decode('...','hex') on write.
class exercise_imagesClass: pgClientClass {

    init(doAlert: AlertManager? = nil) {
        super.init(doAlert: doAlert,
                   tName: "exercise_images",
                   pkField: "id")
    }

    func buildImageList(exerciseId: Int) async -> [ExerciseImageData] {
        var result: [ExerciseImageData] = []
        let idStrs = await getResults(qry:
            "SELECT id FROM exercise_images WHERE exercise_link = \(exerciseId) ORDER BY id ASC;")

        for idStr in idStrs {
            guard let imgId = Int(idStr) else { continue }
            let hex = await getResult(qry:
                "SELECT encode(image, 'hex') FROM exercise_images WHERE id = \(imgId);")
            result.append(ExerciseImageData(id: imgId,
                                            exercise_link: exerciseId,
                                            image: Data(hexString: hex) ?? Data()))
        }
        return result
    }

    /// Insert a new image for an exercise. Returns the new row id (0 on failure).
    func saveImage(exerciseId: Int, image: Data) async -> Int {
        let qry = "INSERT INTO exercise_images (exercise_link, image) VALUES (\(exerciseId), decode('\(image.hexString)', 'hex')) RETURNING id;"
        let idStr = await getResult(qry: qry)
        return Int(idStr) ?? 0
    }

    func deleteImage(id: Int) async {
        await executeQueryND(text: "DELETE FROM exercise_images WHERE id = \(id);")
    }

    func deleteImages(exerciseId: Int) async {
        await executeQueryND(text: "DELETE FROM exercise_images WHERE exercise_link = \(exerciseId);")
    }
}

// MARK: - Data <-> hex helpers for bytea

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init?(hexString: String) {
        let chars = Array(hexString)
        guard chars.count % 2 == 0 else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(chars.count / 2)
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let byte = UInt8(String(chars[i...i+1]), radix: 16) else { return nil }
            bytes.append(byte)
        }
        self.init(bytes)
    }
}
