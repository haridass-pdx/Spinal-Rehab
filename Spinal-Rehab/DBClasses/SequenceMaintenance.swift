//
//  SequenceMaintenance.swift
//  Spinal-Rehab
//
//  Diagnoses and fixes id-sequence drift on SERIAL/IDENTITY columns: a
//  sequence only advances when nextval() is actually called, which bulk
//  imports and explicit-id inserts bypass, so the sequence can fall behind
//  a table's real max id and a later organic insert collides with a
//  duplicate-key error. See Utilities/fix-id-sequence-drift.sql for the
//  standalone SQL version of the same check/fix, runnable outside the app.
//

import Foundation

struct SequenceDriftInfo: Identifiable {
    var id: String { sequenceName }
    let table: String
    let column: String
    let sequenceName: String
    let maxId: Int
    let seqVal: Int
    var isDrifted: Bool { seqVal < maxId }
}

enum SequenceMaintenance {

    /// Every SERIAL/IDENTITY column in the public schema, with its current
    /// table max id and sequence value.
    static func checkAll() async -> [SequenceDriftInfo] {
        let pgc = pgClientClass()
        let flatColumns = await pgc.getResults(qry: """
            SELECT c.relname, a.attname
            FROM pg_attribute a
            JOIN pg_class c ON c.oid = a.attrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'r' AND n.nspname = 'public' AND a.attnum > 0 AND NOT a.attisdropped
              AND pg_get_serial_sequence('public.' || c.relname, a.attname) IS NOT NULL
            ORDER BY c.relname, a.attnum;
            """)

        var results: [SequenceDriftInfo] = []
        var idx = 0
        while idx + 1 < flatColumns.count {
            let table = flatColumns[idx]
            let column = flatColumns[idx + 1]
            idx += 2

            let seqName = await pgc.getResult(qry: "SELECT pg_get_serial_sequence('public.\(table)', '\(column)');")
            guard !seqName.isEmpty else { continue }

            let row = await pgc.getResults(qry: """
                SELECT COALESCE(MAX(\(column)), 0),
                       COALESCE((SELECT last_value FROM \(seqName)), 0)
                FROM public.\(table);
                """)
            guard row.count == 2, let maxId = Int(row[0]), let seqVal = Int(row[1]) else { continue }

            results.append(SequenceDriftInfo(table: table, column: column, sequenceName: seqName, maxId: maxId, seqVal: seqVal))
        }
        return results
    }

    /// Advances every drifted sequence (from a prior checkAll()) to match
    /// its table's max id. Returns the ones actually fixed.
    static func fixDrifted(_ infos: [SequenceDriftInfo]) async -> [SequenceDriftInfo] {
        let pgc = pgClientClass()
        var fixed: [SequenceDriftInfo] = []
        for info in infos where info.isDrifted {
            await pgc.executeQueryND(text: "SELECT setval('\(info.sequenceName)', \(info.maxId));")
            fixed.append(info)
        }
        return fixed
    }
}
