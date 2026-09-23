//
//  FollowUpReportContext.swift
//  Spinal-Rehab
//
//  Assembles the per-test page dictionaries for the multi-visit Patient
//  Follow-up Report. Anchors on a specific test date (selected in
//  TestDateListView), walks backward to the nearest prior visit flagged
//  is_baseline, then reports on every later visit — see
//  FollowUpReportRenderer.fullHTML for how these pages become one document.
//

import Foundation

enum FollowUpReportContext {

    /// One test's page. `nil` when the test doesn't qualify (no baseline
    /// value, or no follow-up visit recorded a value for it).
    static func build(patient: PatientData, anchorTestDate: TestDateData) async -> [[String: String]] {
        // buildPatientist orders by id, not testdate — a back-dated or edited
        // visit would break chronological assumptions below, so re-sort here.
        let visits = await testDateClass().buildPatientist(ptid: patient.id)
            .sorted { ($0.testdate ?? .distantPast) < ($1.testdate ?? .distantPast) }

        guard let anchorIdx = visits.firstIndex(where: { $0.id == anchorTestDate.id }) else { return [] }

        var baselineIdx = anchorIdx
        while baselineIdx > 0 && !visits[baselineIdx].is_baseline {
            baselineIdx -= 1
        }
        // No visit at/before the anchor is flagged is_baseline (e.g. it was
        // never toggled) — fall back to the earliest visit overall rather
        // than blocking the report.
        if !visits[baselineIdx].is_baseline {
            baselineIdx = 0
        }

        let baselineVisit = visits[baselineIdx]
        let laterVisits = baselineIdx + 1 < visits.count ? Array(visits[(baselineIdx + 1)...]) : []
        let latestVisit = laterVisits.last ?? baselineVisit

        let physician = await physicianClass().getPhysician(id: latestVisit.physician_id)
        let reportDate = formatDate(latestVisit.testdate)
        let title = titlePrefix(for: patient.gender)
        let pronoun = pronounSubject(for: patient.gender)

        var pages: [[String: String]] = []

        for goalTest in FollowUpReportRenderer.goalTests {
            guard let page = await buildPage(
                goalTest: goalTest,
                patient: patient,
                baselineVisit: baselineVisit,
                laterVisits: laterVisits,
                reportDate: reportDate,
                patientTitle: title,
                pronounSubject: pronoun,
                physicianName: physician?.fullname ?? ""
            ) else { continue }
            pages.append(page)
        }

        return pages
    }

    // MARK: - Per-test page

    private static func buildPage(goalTest: FollowUpReportRenderer.GoalTest,
                                   patient: PatientData,
                                   baselineVisit: TestDateData,
                                   laterVisits: [TestDateData],
                                   reportDate: String,
                                   patientTitle: String,
                                   pronounSubject: String,
                                   physicianName: String) async -> [String: String]? {
        let baselineRows = await Patient_testClass().buildPtTestList(pttestid: baselineVisit.id)
        guard let baselineRow = matchRow(goalTest, in: baselineRows) else { return nil }

        var followupPairs: [(visit: TestDateData, row: PatienttestData)] = []
        for visit in laterVisits {
            let rows = await Patient_testClass().buildPtTestList(pttestid: visit.id)
            if let row = matchRow(goalTest, in: rows) {
                followupPairs.append((visit, row))
            }
        }
        guard !followupPairs.isEmpty else { return nil }

        guard let def = await test_tableClass().getTestTableItem(name: baselineRow.testname) else { return nil }
        let greaterIsBetter = def.greaterisbetter

        func percentImprovement(_ followValue: Double) -> Double {
            guard baselineRow.testvalue != 0 else { return 0 }
            return greaterIsBetter
                ? (followValue - baselineRow.testvalue) / baselineRow.testvalue * 100
                : (baselineRow.testvalue - followValue) / baselineRow.testvalue * 100
        }

        var followupRowsHTML = ""
        var chartPoints: [(label: String, value: Double)] = [("baseline", baselineRow.testvalue)]
        for (index, pair) in followupPairs.enumerated() {
            let ordinal = ordinalWord(index + 1)
            let pct = percentImprovement(pair.row.testvalue)
            followupRowsHTML += """
            <p><strong>\(ordinal) Follow-up Test Date:</strong> \(formatDate(pair.visit.testdate))<br>
            <strong>\(ordinal) Follow-up Score:</strong> \(numberString(pair.row.testvalue)) \(goalTest.unit)<br>
            <strong>Percent Improvement:</strong> \(String(format: "%.1f", pct))%</p>
            """
            chartPoints.append((label: "\(ordinal) follow-up", value: pair.row.testvalue))
        }

        let goals = await patient_goalsClass().buildGoalList(patientId: patient.id)
        let goalRec = goals.last { goalTest.goalValue($0) != 0 }
        let goalOperator = greaterIsBetter ? ">" : "<"
        let goalValueStr = goalRec.map { "\(goalOperator) \(numberString(goalTest.goalValue($0))) \(goalTest.unit)" } ?? ""
        let goalTargetDateStr = goalRec.flatMap { goalTest.goalTargetDate($0) }.map { formatDate($0) } ?? ""

        let records = await normal_dataClass().buildNormalList(id: def.id)
        let normativeTable = records.isEmpty ? "" : ReportRenderer.normativeTable(
            title: goalTest.normativeTitle, records: records, lowerIsBetter: !greaterIsBetter)

        let chart = FollowUpChartRenderer.svg(
            points: chartPoints,
            goal: goalRec != nil ? goalTest.goalValue(goalRec!) : nil)

        return [
            "patient_name": patient.fullname,
            "report_date": reportDate,
            "test_title": goalTest.title,
            "baseline_date": formatDate(baselineVisit.testdate),
            "baseline_score": "\(numberString(baselineRow.testvalue)) \(goalTest.unit)",
            "followup_rows": followupRowsHTML,
            "goal_value": goalValueStr,
            "goal_target_date": goalTargetDateStr,
            "chart": chart,
            "normative_table": normativeTable,
            "patient_title": patientTitle,
            "pronoun_subject": pronounSubject,
            "physician_name": physicianName,
        ]
    }

    // MARK: - Helpers

    private static func matchRow(_ goalTest: FollowUpReportRenderer.GoalTest,
                                  in rows: [PatienttestData]) -> PatienttestData? {
        rows.first { row in
            row.testvalue != 0 &&
            goalTest.keywords.contains { row.testname.lowercased().contains($0) }
        }
    }

    private static func titlePrefix(for gender: String) -> String {
        switch gender.lowercased().first {
        case "m": return "Mr."
        case "f": return "Ms."
        default: return ""
        }
    }

    private static func pronounSubject(for gender: String) -> String {
        switch gender.lowercased().first {
        case "m": return "He"
        case "f": return "She"
        default: return "They"
        }
    }

    private static func ordinalWord(_ n: Int) -> String {
        let suffix: String
        switch (n % 100, n % 10) {
        case (11, _), (12, _), (13, _): suffix = "th"
        case (_, 1): suffix = "st"
        case (_, 2): suffix = "nd"
        case (_, 3): suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix)"
    }

    private static func numberString(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }

    private static func formatDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
