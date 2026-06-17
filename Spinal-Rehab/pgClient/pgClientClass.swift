//
//  pgClientClass.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/13/25.
//
import Foundation
import PostgresNIO
import Logging
import NIOCore
import NIOPosix
import SwiftUI
public import Combine

// typealias DictValue = (strVal: String, type: UInt32)
struct DictValue: Sendable {
    var strVal: String
    var type: UInt32
}

typealias DictListType = [String: DictValue] // (strVal: String, type: UInt32)
typealias colTypes = UInt32

// MARK: - Database Error
enum DatabaseError: Error, LocalizedError {
    case notConnected
    case columnMismatch(table: String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to database"
        case .columnMismatch(let table): return "Column count mismatch in \(table)"
        }
    }
}

// MARK: - Database Manager (Singleton)
class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()
    
    private var client: PostgresClient?
    private var runTask: Task<Void, Never>?
    private let logger = Logger(label: "pgClient")
    
    var isConnected: Bool { client != nil }
    
    private init() {}
    
    func connect(logInRec: logInRec) async throws {
        // Disconnect any existing connection first
        disconnect()
        
        let config = PostgresClient.Configuration(
            host: logInRec.host,
            port: 5432,
            username: logInRec.username,
            password: logInRec.password,
            database: logInRec.database,
            tls: .disable
        )
        let newClient = PostgresClient(configuration: config)
        self.client = newClient
        
        // Start the client's run loop in a background task
        runTask = Task {
            await newClient.run()
        }
        
        // Test the connection with a simple query
        let testQuery = PostgresQuery(unsafeSQL: "SELECT 1")
        _ = try await newClient.query(testQuery, logger: logger)
    }
    
    func disconnect() {
        runTask?.cancel()
        runTask = nil
        client = nil
    }
    
    func query(_ sql: String) async throws -> PostgresRowSequence {
        guard let client = client else {
            throw DatabaseError.notConnected
        }
        let pgQuery = PostgresQuery(unsafeSQL: sql)
        return try await client.query(pgQuery, logger: logger)
    }
}

// MARK: - Column Metadata Cache
class ColumnMetadataCache {
    static let shared = ColumnMetadataCache()
    
    struct TableInfo {
        var colNames: [String]
        var colTypes: [UInt32]
    }
    
    private var cache: [String: TableInfo] = [:]
    
    private init() {}
    
    func loadAll() async {
        let tables = ["patients", "testdate", "test_table", "normal_data", "patient_test", "physicians", "reports"]
        for table in tables {
            await loadTable(name: table)
        }
    }
    
    func loadTable(name: String) async {
        let sql = """
            SELECT a.attname, a.atttypid::integer
            FROM pg_attribute a
            JOIN pg_class c ON a.attrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relname = '\(name)' AND n.nspname = 'public' AND a.attnum > 0 AND NOT a.attisdropped
            ORDER BY a.attnum
            """
        do {
            let rows = try await DatabaseManager.shared.query(sql)
            var names: [String] = []
            var types: [UInt32] = []
            for try await (colName, typeOid) in rows.decode((String, Int).self) {
                names.append(colName)
                types.append(UInt32(typeOid))
            }
            cache[name] = TableInfo(colNames: names, colTypes: types)
        } catch {
            print("Error loading metadata for \(name): \(error)")
        }
    }
    
    func getInfo(for table: String) -> TableInfo? {
        return cache[table]
    }
}

// MARK: - PostgresCell String Conversion Helper
func cellToString(_ cell: PostgresCell) -> String {
    guard cell.bytes != nil else { return "" }
    
    // Use the known data type to decode appropriately and convert to String
    let dt = cell.dataType
    
    // Text/string types
    if dt == .text || dt == .varchar || dt == .name || dt == .bpchar {
        return (try? cell.decode(String.self)) ?? ""
    }
    
    // Boolean
    if dt == .bool {
        return (try? cell.decode(Bool.self)) == true ? "t" : "f"
    }
    
    // Integer types — on typed-decode failure, fall through to text fallback below
    if dt == .int2 {
        if let v = try? cell.decode(Int16.self) { return String(v) }
    }
    if dt == .int4 {
        if let v = try? cell.decode(Int32.self) { return String(v) }
    }
    if dt == .int8 {
        if let v = try? cell.decode(Int64.self) { return String(v) }
    }

    // Float types — on typed-decode failure, fall through to text fallback below
    if dt == .float4 {
        if let v = try? cell.decode(Float.self) { return String(v) }
    }
    if dt == .float8 {
        if let v = try? cell.decode(Double.self) { return String(v) }
    }
    
    // Numeric (decimal) - binary format is base-10000 digit groups.
    // Text format won't parse here, so fall through if header read fails.
    if dt == .numeric {
        var buf = cell.bytes!
        guard let ndigits = buf.readInteger(as: Int16.self),
              let weight = buf.readInteger(as: Int16.self),
              let sign = buf.readInteger(as: Int16.self),
              let dscale = buf.readInteger(as: Int16.self) else {
            if let s = try? cell.decode(String.self) { return s }
            var b = cell.bytes!
            return b.readString(length: b.readableBytes) ?? "0"
        }
        
        // NaN check
        if sign == -16384 { return "NaN" } // 0xC000
        
        // Read base-10000 digit groups
        var digits: [Int16] = []
        for _ in 0..<ndigits {
            if let d = buf.readInteger(as: Int16.self) {
                digits.append(d)
            }
        }
        
        // Build the string from base-10000 groups
        if ndigits == 0 { return "0" }
        
        var result = ""
        if sign == 0x4000 { result = "-" } // negative
        
        // Integer part: groups from index 0 to weight (inclusive)
        let intGroupCount = Int(weight) + 1
        for i in 0..<intGroupCount {
            let d = i < digits.count ? Int(digits[i]) : 0
            if i == 0 {
                result += "\(d)" // no leading zeros on first group
            } else {
                result += String(format: "%04d", d)
            }
        }
        if intGroupCount <= 0 {
            result += "0"
        }
        
        // Fractional part
        if dscale > 0 {
            result += "."
            var fracStr = ""
            if intGroupCount < digits.count {
                for i in intGroupCount..<digits.count {
                    let d = i >= 0 && i < digits.count ? Int(digits[i]) : 0
                    fracStr += String(format: "%04d", d)
                }
            }
            // Pad if needed, then trim to exact dscale
            while fracStr.count < Int(dscale) { fracStr += "0" }
            result += String(fracStr.prefix(Int(dscale)))
        }
        
        return result
    }
    
    // Date type - binary is Int32 days since 2000-01-01
    if dt == .date {
        var buf = cell.bytes!
        if let days = buf.readInteger(as: Int32.self) {
            let refDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1))!
            let date = Calendar.current.date(byAdding: .day, value: Int(days), to: refDate)!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        return ""
    }
    
    // Time type - binary is Int64 microseconds since midnight
    if dt == .time || dt == .interval {
        var buf = cell.bytes!
        if let us = buf.readInteger(as: Int64.self) {
            let totalSec = Int(us / 1_000_000)
            let h = totalSec / 3600
            let m = (totalSec % 3600) / 60
            let s = totalSec % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return ""
    }
    
    // Timestamp
    if dt == .timestamp || dt == .timestamptz {
        var buf = cell.bytes!
        if let us = buf.readInteger(as: Int64.self) {
            let refDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1))!
            let date = refDate.addingTimeInterval(Double(us) / 1_000_000.0)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
        return ""
    }
    
    // UUID
    if dt == .uuid {
        return (try? cell.decode(UUID.self))?.uuidString ?? ""
    }
    
    // Fallback: try String decode, then raw bytes
    if let val = try? cell.decode(String.self) { return val }
    var buf = cell.bytes!
    return buf.readString(length: buf.readableBytes) ?? ""
}


// MARK: - pgClientClass
public class pgClientClass: ObservableObject {
    var tableName: String = ""
    var primaryKey: String = ""
    var colNames: [String] = []
    var colTypes: [UInt32] = []
    var globalAlert: AlertManager?
    var alertSent: Bool = false
    var dataDict: DictListType = [:]
    @Published var dictList: [[String: DictValue]] = []
    
    init(doAlert: AlertManager? = nil,
         tName: String = "",
         pkField: String = "") {
        tableName = tName
        primaryKey = pkField
        globalAlert = doAlert
        
        // Load from cache if available
        if !tName.isEmpty, let info = ColumnMetadataCache.shared.getInfo(for: tName) {
            colNames = info.colNames
            colTypes = info.colTypes
        }
    }
    
    // Async column info loading (fallback if cache not loaded yet)
    func loadColumnInfo() async {
        guard colNames.isEmpty, !tableName.isEmpty else { return }
        await ColumnMetadataCache.shared.loadTable(name: tableName)
        if let info = ColumnMetadataCache.shared.getInfo(for: tableName) {
            colNames = info.colNames
            colTypes = info.colTypes
        }
    }
    
    
    func getColumnInfo() async {
        await loadColumnInfo()
    }
    
    func initDictionary() {
        var row: [String: DictValue] = [:]
        for (key, itemType) in zip(colNames, colTypes) {
            row[key] = DictValue(strVal: "", type: itemType)
        }
        if !row.isEmpty {
            dictList.append(row)
        }
    }
    
    func buildDictionary(row: PostgresRandomAccessRow) -> [String: DictValue] {
        var result: [String: DictValue] = [:]
        let numCols = row.count
        let hdrCols = colNames.count
        if numCols == hdrCols {
            for idx in 0..<numCols {
                let name = colNames[idx]
                let cell = row[idx]
                let str = cellToString(cell)
                result[name] = DictValue(strVal: str, type: colTypes[idx])
            }
        } else {
            if !alertSent {
                globalAlert?.alertTitle = "Incorrect Column Count"
                globalAlert?.alertMessage = "The number of columns in \(tableName) from the database does not match the number of headers."
                globalAlert?.isAlertPresented = true
            }
        }
        return result
    }
    
    
    func checkTypes(dict: inout DictListType) {
        let val = dict[primaryKey]!.type
        
        if val == 0 {
            let max = colNames.count
            var idx: Int = 0
            while idx < max {
                let colName = colNames[idx]
                let valType: UInt32 = colTypes[idx]
                dict[colName]!.type = valType
                idx += 1
            }
        }
    }
    
    func executeQuery(text: String) async {
        do {
            if colNames.isEmpty { await loadColumnInfo() }
            let rows = try await DatabaseManager.shared.query(text)
            dictList.removeAll()
            for try await row in rows {
                let randomAccess = row.makeRandomAccess()
                let dict = buildDictionary(row: randomAccess)
                if !dict.isEmpty {
                    dictList.append(dict)
                }
            }
        } catch {
            print("Error in executeQuery: \(String(reflecting: error))")
        }
    }
    
    func executeQueryND(text: String) async {
        do {
            let rows = try await DatabaseManager.shared.query(text)
            // Consume the sequence to ensure the query completes
            for try await _ in rows { }
        } catch {
            print("Error in executeQueryND: \(error)")
        }
    }
    
    func getResults(qry: String) async -> [String] {
        var resultStr:[String] = []
        do {
            let rows = try await DatabaseManager.shared.query(qry)
            for try await row in rows {
                let randomAccess = row.makeRandomAccess()
                if randomAccess.count > 0 {
                    randomAccess.forEach{ raItem in
                        let resStr = cellToString(raItem)
                        if !resStr.isEmpty {
                            resultStr.append(resStr)
                        }
                    }
                    
                }
            }
        } catch {
            print("Error in getResult: \(error)")
        }
        return resultStr
    }

    
    func getResult(qry: String) async -> String {
        var resultStr = ""
        do {
            let rows = try await DatabaseManager.shared.query(qry)
            for try await row in rows {
                let randomAccess = row.makeRandomAccess()
                if randomAccess.count > 0 {
                    resultStr = cellToString(randomAccess[0])
                }
            }
        } catch {
            print("Error in getResult: \(error)")
        }
        return resultStr
    }
    
    func saveDictionary(dict: DictListType) async -> Int {
        var result: Int = 0
        let pk_string: String = dict[primaryKey]?.strVal ?? "0  "
        let pk_Value: Int = Int(pk_string) ?? 0
        var text: String = ""
        
        if pk_Value == 0 {
            text = saveNewRec(dict: dict)
        } else {
            text = updateRec(dict: dict)
            let pkStr: String = " WHERE \(primaryKey) = \(pk_Value) "
            text = text + pkStr
           // print(text)
        }
        
        do {
            let rows = try await DatabaseManager.shared.query(text)
            if pk_Value == 0 {
                for try await row in rows {
                    let randomAccess = row.makeRandomAccess()
                    if randomAccess.count > 0 {
                        if let idValue = try? randomAccess[0].decode(Int.self) {
                            result = idValue
                        }
                    }
                }
            } else {
                result = pk_Value
                // Consume the sequence
                for try await _ in rows { }
            }
        } catch {
            print("Error in saveDictionary: \(error)")
           print( String(reflecting: error))
        }
        return result
    }
    
    
    func saveNewRec(dict: DictListType) -> String {
        var text: String = "INSERT INTO \(tableName) ("
        var values: String = "VALUES ("
        var idx: Int = 0
        let keys = Array(dict.keys)
        while idx < dict.count {
            let key = keys[idx]
            if !(key == primaryKey) {
                if (idx > 0) && (idx != dict.count) {
                    text.append(",")
                    values.append(",")
                }
                // skip primary key value it's 0 and will be assigned by postgres
                if !key.isEmpty {
                    text.append(key)
                }
                
                let val = dict[key]!.strVal
                let type: pgTypes = pgTypes(rawValue: dict[key]!.type) ?? .void
                if true // !val.isEmpty
                {
                    let tempVal = formatFieldByType(val: val, type: type)
                    values.append("\(tempVal)")
                } else {
                    values.append("NULL")
                }
            }
            idx += 1
        }
        text.append(") ")
        values.append(")")
        text.append(values)
        text.append(" RETURNING \(primaryKey) ")
        
        return text
    }
    
    
    func updateRec(dict: DictListType) -> String {
        var text: String = "UPDATE \(tableName) SET "
        var idx: Int = 0
        var pkFirst: Bool = false
        let keys: [String] = Array(dict.keys)
        while idx < dict.count {
            let key = keys[idx]
            pkFirst = ((key == primaryKey) && (idx == 0))
            if !(key == primaryKey) {
                if (idx > 0) && (!pkFirst) {
                    text.append(", ")
                }
                
                let val = dict[key]!.strVal
                let type: pgTypes = pgTypes(rawValue: dict[key]!.type) ?? .void
                let tempVal = formatFieldByType(val: val, type: type)
                text.append("\(key) = \(tempVal)")
            }
            idx += 1
        }
        text.append(" ")
        
        return text
    }
    
    func deleteRec(dict: DictListType) async  {
        
        let sqlQry = "DELETE FROM \(tableName) WHERE \(primaryKey) = \(dict[primaryKey]!.strVal)"
        _ = await self.executeQuery(text: sqlQry)
    }
        
    func dictIsEmpty() -> Bool {
        var result: Bool = true
        for item in self.dataDict {
            if item.value.strVal.count > 0 {
                result = false
                break
            }
        }
        return result
    }
    
    func     formatFieldByType(val: String, type: pgTypes) -> String {
        switch type.saveType {
        case "bool":
            return val.isEmpty ? "'false'" : "'\(val)'"
        case "text":
            return "'\(val)'"
        case "num":
            return val.isEmpty ? "0" : "\(val)"
        case "time":
            var temp = val
            if temp.count == 0 {
                temp = "00:00:00"
            }
            if temp.count == 5 {
                temp = temp + ":00"
            }
            return "'\(temp)'"
        case "interval":
            let negative = val.contains("-")
            let parts = val.split(separator: ":")
            let h = abs(Int(parts.count > 0 ? String(parts[0]) : "0") ?? 0)
            let m = abs(Int(parts.count > 1 ? String(parts[1]) : "0") ?? 0)
            let s = parts.count > 2 ? String(parts[2]) : "00"
            let formatted = String(format: "%@%02d:%02d:%@",
                                   negative ? "-" : "",
                                   h, m, s)
            return "'\(formatted)'"

        case "date":
            var td = val
            switch td.count {
            case 0:
                td = getCurrentDateString(forSave: true)
            default:
                let theDate: Date = StringToDate(dateString: td) ?? Date()
                td = getDateString(from: theDate,
                                   formatStr: "yyyy-MM-dd")
            }
            return "'\(td)'"
            
        default:
            return val.isEmpty ? "0" : "\(val)"
        }
    }
    
    
    func getDictList() -> [[String: DictValue]] {
        return dictList
    }
    
    func doClose() {
        // No-op: DatabaseManager handles connection lifecycle
    }
}

func getRate(key: String) async -> Double {
    var result: Double = 0.00
    let qry = "SELECT itemname, itemrate from rate where itemname = '\(key)'"
    do {
        let rows = try await DatabaseManager.shared.query(qry)
        for try await row in rows {
            let randomAccess = row.makeRandomAccess()
            if randomAccess.count >= 2 {
                let rateStr = cellToString(randomAccess[1])
                result = (Double(rateStr) ?? 0.00).rounded(digits: (rateStr.count - 2))
            }
        }
    } catch {
        print("Error in getRate: \(error)")
    }
    return result
}


enum pgTypes: UInt32 {
    case bool = 16
    case bytea
    case char
    case name
    case int8
    case int2
    case int2vector = 22
    case int4 = 23
    case text = 25
    case oid
    case float4 = 700
    case float8 = 701
    case bpchar = 1042
    case varchar = 1043
    case date = 1082
    case time = 1083
    case timestamp = 1114
    case interval = 1186
    case numeric = 1700
    case cstring = 2275
    case any = 2276
    case anyarray = 2277
    case void = 2278
    case uuid = 2950
    
    public var swiftType: Any.Type {
        switch self {
        case .bool: return Bool.self
        case .bytea: return Data.self
        case .char: return String.self
        case .name: return String.self
        case .int8: return Int64.self
        case .int2: return Int16.self
        case .int2vector: return [Int16].self
        case .int4: return Int32.self
        case .text: return String.self
        case .float4: return Float.self
        case .bpchar: return String.self
        case .varchar: return String.self
        case .date: return Date.self
        case .time: return Date.self
        case .timestamp: return Date.self
        case .interval: return Date.self
        case .numeric: return Double.self
        case .cstring: return String.self
        case .any: return String.self
        case .anyarray: return [String].self
        case .oid: return Int32.self
        case .void: return Void.self
        case .uuid: return UUID.self
        case .float8: return Double.self
        }
    }
    
    public var saveType: String {
        switch self {
        case .bool: return "bool"
        case .bytea: return "bytea"
        case .char: return "text"
        case .name: return "name"
        case .int8: return "num"
        case .int2: return "num"
        case .int2vector: return "int2vector"
        case .int4: return "num"
        case .text: return "text"
        case .float4: return "num"
        case .float8: return "num"
        case .bpchar: return "text"
        case .varchar: return "text"
        case .date: return "date"
        case .time: return "time"
        case .timestamp: return "timestamp"
        case .interval: return "interval"
        case .oid: return "num"
        case .numeric: return "num"
        case .cstring: return "text"
        case .uuid: return "num"
        case .any: return "any"
        case .anyarray: return "anyarray"
        case .void: return "void"
        }
    }
}
