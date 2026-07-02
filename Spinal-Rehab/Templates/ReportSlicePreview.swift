//
//  ReportSlicePreview.swift
//  Spinal-Rehab
//
//  Isolated preview of the clinical performance report with HARDCODED sample data
//  (numbers reproduce the example PDF). Shares all layout with the real report via
//  `ReportRenderer`, so this is a fast way to eyeball styling without a DB / patient.
//
//  For the real, data-driven version see ReportContext + PtReportView.
//

import SwiftUI

struct SpinalReportSlice: View {
    @State private var engine = PDFReportEngine()

    private var fullHTML: String { ReportRenderer.fullHTML(values: Self.sampleValues) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Report Preview (sample data)").font(.headline)
                Spacer()
                Button("Export PDF…") { engine.exportPDF(fullHTML, suggestedName: "Performance Report") }
                Button("Print…") { engine.printHTML(fullHTML) }
                    .keyboardShortcut("p")
            }
            .padding(10)
            Divider()
            HTMLPreviewView(htmlContent: fullHTML)
        }
        .frame(minWidth: 700, minHeight: 800)
    }
}

// MARK: - Sample merge values (mirrors the example PDF)

extension SpinalReportSlice {

    static let sampleValues: [String: String] = {
        var v: [String: String] = [
            "clinic_logo": ReportRenderer.logoImageTag(named: "ClinicLogo"),
            "report_date": "Feb 14, 2023",
            "patient_name": "Ms. J. Smith",
            "age": "51",
            "gender": "Female",
            "fri_score": "22",
            "pain": "1",
            "examination_findings": sampleFindings,
            "below_satisfactory_list": "cervical flexor endurance, lumbar extensor endurance tests",
            "goal_list": "cervical flexor endurance, lumbar extensor endurance",
            "goal_months": "2",
            "reeval_days": "30 and 60",
        ]
        v["normative_tables"] = sampleNormativeTables()
        return v
    }()

    /// Static Examination prose for the sample (the real report builds this per test group).
    static let sampleFindings = """
    <p>Cervical physical performance tests were performed on the patient. These tests resulted in the following findings: flexion endurance was <strong>46</strong> seconds (this is rated as <strong>Fair</strong> performance).</p>
    <p>Lumbar physical performance tests were performed on the patient. These tests resulted in the following findings: extension endurance was <strong>69</strong> seconds (this is rated as <strong>Fair</strong> performance).</p>
    <p>Cardiovascular and functional performance tests were performed on the patient. These tests resulted in the following findings: repeated sit-to-stand was <strong>6</strong> seconds (this is rated as <strong>Excellent</strong> performance); the Kasch Step Test postexercise 1-minute heart rate was <strong>86</strong> bpm (this is rated as <strong>Excellent</strong> performance).</p>
    """

    /// Build a `normalData` row with just the fields the report needs.
    private static func nd(_ gender: String, mean: Int, excellent: Int,
                           good: Int, fair: Int, poor: Int, verypoor: Int) -> normalData {
        var d = normalData()
        d.gender = gender
        d.mean = mean; d.excellent = excellent; d.good = good
        d.fair = fair; d.poor = poor; d.verypoor = verypoor
        return d
    }

    /// The three data-driven tables (sample numbers) + the static Kasch chart,
    /// rendered through the same `ReportRenderer` helpers the real report uses.
    static func sampleNormativeTables() -> String {
        let cervical = ReportRenderer.normativeTable(
            title: "Normative Performance Data: Cervical Flexor Endurance (seconds)",
            records: [
                nd("Male",   mean: 153, excellent: 199, good: 176, fair: 131, poor: 108, verypoor: 107),
                nd("Female", mean: 37,  excellent: 48,  good: 43,  fair: 33,  poor: 27,  verypoor: 26),
            ],
            lowerIsBetter: false)

        let lumbar = ReportRenderer.normativeTable(
            title: "Normative Performance Data: Lumbar Extension Endurance (seconds)",
            records: [
                nd("Male",   mean: 73, excellent: 123, good: 107, fair: 40, poor: 34, verypoor: 33),
                nd("Female", mean: 69, excellent: 117, good: 102, fair: 36, poor: 31, verypoor: 30),
            ],
            lowerIsBetter: false)

        let sitToStand = ReportRenderer.normativeTable(
            title: "Normative Performance Data: Sit-to-Stand (seconds)",
            records: [
                nd("Male",   mean: 7, excellent: 5, good: 6, fair: 7, poor: 8, verypoor: 9),
                nd("Female", mean: 8, excellent: 6, good: 7, fair: 8, poor: 9, verypoor: 10),
            ],
            lowerIsBetter: true)

        return cervical + lumbar + sitToStand + ReportRenderer.kaschStepTable
    }
}

#Preview {
    SpinalReportSlice()
}
