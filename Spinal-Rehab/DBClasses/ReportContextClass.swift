//
//  ReportContextClass.swift
//  Spinal-Rehab
//
//  Assembles the [String: String] merge dictionary for the performance report
//  from a real TestDateData (patient demographics + patient_test results +
//  normal_data normative tables). Feed the result to ReportRenderer.fullHTML.
//
//  Which test groups appear is gated by the test-date booleans:
//    cervical -> "Cervical Flexion"
//    lumbar   -> "Lumbar Extension"
//    cardio   -> "Sit Stand" + "Kasch Step Test"
//  Tests are matched to patient_test rows by the keywords below.
//

import Foundation

enum ReportContext {

    /// A single test the report can render, matched to a patient_test row by keyword.
    private struct TestSlot {
        let keywords: [String]     // case-insensitive substring match against testname
        let tableTitle: String?    // nil => no data-driven normative table (step test)
    }

    private static let cervical = TestSlot(keywords: ["flex"],
        tableTitle: "Normative Performance Data: Cervical Flexor Endurance (seconds)")
    private static let lumbar = TestSlot(keywords: ["exten"],
        tableTitle: "Normative Performance Data: Lumbar Extension Endurance (seconds)")
    private static let sitStand = TestSlot(keywords: ["sit"],
        tableTitle: "Normative Performance Data: Sit-to-Stand (seconds)")
    private static let stepTest = TestSlot(keywords: ["step", "kasch"], tableTitle: nil)

    private struct Resolved {
        let seconds: String
        let rating: String
        let testName: String
        var belowSatisfactory: Bool { !["Excellent", "Good", "—"].contains(rating) }
    }

    /// Build the full merge dictionary for one test date.
    static func build(testDate: TestDateData) async -> [String: String] {
        var v: [String: String] = [:]

        // Demographics
        let name = await patientClass.fullName(forId: testDate.pt_id)
        let demo = await patientClass.getGenderAgeDOB(forId: testDate.pt_id)
        var age = demo.age
        if age == 0, let dob = demo.dob { age = calculateAge(birthDate: dob) }

        v["clinic_logo"] = ReportRenderer.logoImageTag(named: "ClinicLogo")
        v["patient_name"] = name.trimmingCharacters(in: .whitespaces).isEmpty ? "The patient" : name
        v["gender"] = demo.gender.isEmpty ? "—" : demo.gender
        v["age"] = String(age)
        v["report_date"] = formatDate(testDate.testdate)
        v["fri_score"] = String(Int(testDate.fri))
        v["pain"] = String(Int(testDate.fri_pain))
        v["goal_months"] = "2"
        v["reeval_days"] = "30 and 60"

        // Patient test results for this date
        let rows = await Patient_testClass().buildPtTestList(pttestid: testDate.id)

        var findings = ""
        var tables = ""
        var below: [String] = []

        // Cervical group
        if testDate.cervical, let r = await resolve(cervical, rows: rows, age: age, gender: demo.gender) {
            findings += "<p>Cervical physical performance tests were performed on the patient. These tests resulted in the following findings: flexor endurance was <strong>\(r.seconds)</strong> seconds (this is rated as <strong>\(r.rating)</strong> performance).</p>"
            if r.belowSatisfactory { below.append("cervical flexor endurance") }
            if let t = await table(for: r, title: cervical.tableTitle) { tables += t }
        }

        // Lumbar group
        if testDate.lumbar, let r = await resolve(lumbar, rows: rows, age: age, gender: demo.gender) {
            findings += "<p>Lumbar physical performance tests were performed on the patient. These tests resulted in the following findings: extensor endurance was <strong>\(r.seconds)</strong> seconds (this is rated as <strong>\(r.rating)</strong> performance).</p>"
            if r.belowSatisfactory { below.append("lumbar extensor endurance") }
            if let t = await table(for: r, title: lumbar.tableTitle) { tables += t }
        }

        // Cardio group: sit-to-stand + Kasch step test
        if testDate.cardio {
            var sentences: [String] = []
            if let r = await resolve(sitStand, rows: rows, age: age, gender: demo.gender) {
                sentences.append("repeated sit-to-stand was <strong>\(r.seconds)</strong> seconds (this is rated as <strong>\(r.rating)</strong> performance)")
                if r.belowSatisfactory { below.append("repeated sit-to-stand") }
                if let t = await table(for: r, title: sitStand.tableTitle) { tables += t }
            }
            if let r = await resolve(stepTest, rows: rows, age: age, gender: demo.gender) {
                sentences.append("the Kasch Step Test postexercise 1-minute heart rate was <strong>\(r.seconds)</strong> bpm (this is rated as <strong>\(r.rating)</strong> performance)")
                if r.belowSatisfactory { below.append("cardiovascular recovery") }
            }
            if !sentences.isEmpty {
                findings += "<p>Cardiovascular and functional performance tests were performed on the patient. These tests resulted in the following findings: " + sentences.joined(separator: "; ") + ".</p>"
                tables += ReportRenderer.kaschStepTable
            }
        }

        v["examination_findings"] = findings.isEmpty
            ? "<p>No performance tests were recorded for this visit.</p>"
            : findings

        // Therapy plan lists
        let joined = below.joined(separator: ", ")
        v["below_satisfactory_list"] = below.isEmpty ? "no tests" : "\(joined) tests"
        v["goal_list"] = below.isEmpty ? "performance" : joined

        v["normative_tables"] = tables
        return v
    }

    // MARK: - Helpers

    private static func resolve(_ slot: TestSlot, rows: [PatienttestData],
                                age: Int, gender: String) async -> Resolved? {
        guard let row = rows.first(where: { r in
            let name = r.testname.lowercased()
            return slot.keywords.contains { name.contains($0) }
        }) else { return nil }

        var rating = row.testscore.trimmingCharacters(in: .whitespaces)
        if rating.isEmpty {
            rating = await test_tableClass.getScoreForTest(
                testName: row.testname, age: age, Gender: gender, Value: row.testvalue)
        }
        return Resolved(seconds: numberString(row.testvalue),
                        rating: rating.isEmpty ? "—" : rating,
                        testName: row.testname)
    }

    /// Fetch the test's definition + normative rows and render its table.
    private static func table(for r: Resolved, title: String?) async -> String? {
        guard let title else { return nil }
        let ttc = test_tableClass()
        guard let def = await ttc.getTestTableItem(name: r.testName) else { return nil }
        let records = await normal_dataClass().buildNormalList(id: def.id)
        guard !records.isEmpty else { return nil }
        return ReportRenderer.normativeTable(title: title,
                                             records: records,
                                             lowerIsBetter: !def.greaterisbetter)
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
