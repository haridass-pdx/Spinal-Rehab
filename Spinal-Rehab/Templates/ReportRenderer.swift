//
//  ReportRenderer.swift
//  Spinal-Rehab
//
//  Shared HTML assembly for the clinical performance report. Used by both the
//  sample preview (ReportSlicePreview) and the real, data-driven report
//  (ReportContext + PtReportView) so there is a single source of layout truth.
//
//  The body template (with {tokens}) is what would live in reports.thetext; the
//  CSS wrapper is supplied here so CSS braces never reach the {token} parser.
//

import Foundation
import AppKit

enum ReportRenderer {

    /// Resolve `{tokens}` in the body template and wrap in the print-ready document.
    static func fullHTML(values: [String: String]) -> String {
        let body = ParsedTemplate(rawText: bodyTemplate).render(with: values)
        return PDFReportEngine.wrap(body: body, css: reportCSS)
    }

    /// An `<img>` tag with the named asset-catalog image embedded as a base64 data
    /// URL (works with `loadHTMLString`, no file access). Returns "" if not found,
    /// so the cover page still renders text-only when the logo is missing.
    static func logoImageTag(named name: String) -> String {
        guard let img = NSImage(named: name),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return "" }
        return "<img class=\"tp-logo\" src=\"data:image/png;base64,\(png.base64EncodedString())\">"
    }

    // MARK: - Normative tables (data-driven from normalData)

    /// One rating row's six display cells, derived from the stored thresholds.
    /// `lowerIsBetter` = !test_table.greaterisbetter (sit-to-stand style vs endurance style).
    static func cells(_ d: normalData, lowerIsBetter: Bool) -> [String] {
        if lowerIsBetter {
            return ["\(d.mean)", "<\(d.excellent)", "\(d.good)", "\(d.fair)", "\(d.poor)", ">\(d.verypoor)"]
        } else {
            return ["\(d.mean)", ">\(d.excellent)",
                    "\(d.excellent - 1)-\(d.good)",
                    "\(d.good - 1)-\(d.fair)",
                    "\(d.fair - 1)-\(d.poor)",
                    "<\(d.verypoor)"]
        }
    }

    /// A Male/Female normative table built from `normal_data` records for one test.
    static func normativeTable(title: String, records: [normalData], lowerIsBetter: Bool) -> String {
        let male = records.first { $0.gender.lowercased().hasPrefix("m") }
        let female = records.first { $0.gender.lowercased().hasPrefix("f") }
        func row(_ label: String, _ d: normalData?) -> String {
            guard let d else { return "" }
            let c = cells(d, lowerIsBetter: lowerIsBetter)
            return "<tr><td class=\"rowhdr\">\(label)</td>" + c.map { "<td>\($0)</td>" }.joined() + "</tr>"
        }
        return """
        <p class="tabletitle">\(title)</p>
        <table class="norm">
          <tr><th></th><th>Mean</th><th>Excellent</th><th>Good</th><th>Fair</th><th>Poor</th><th>Very Poor</th></tr>
          \(row("Male", male))
          \(row("Female", female))
        </table>
        """
    }

    /// Fixed reference chart (age-bracketed) — not part of normal_data, so kept static.
    static let kaschStepTable: String = {
        let ages = ["18-25", "26-35", "36-45", "46-55", "56-65", ">65"]
        let male: [(String, [String])] = [
            ("Excellent",     ["50-75", "49-76", "49-75", "56-82", "60-77", "59-81"]),
            ("Good",          ["76-84", "77-85", "77-88", "83-93", "78-94", "82-92"]),
            ("Above Average", ["85-93", "86-94", "89-98", "94-101", "95-100", "93-102"]),
            ("Average",       ["94-100", "95-102", "99-105", "102-111", "101-109", "103-110"]),
            ("Below Average", ["101-107", "103-110", "106-113", "112-119", "110-117", "111-118"]),
            ("Poor",          ["108-119", "111-121", "114-124", "120-126", "118-128", "119-126"]),
            ("Very Poor",     ["120-157", "122-151", "125-163", "127-171", "129-154", "127-151"]),
        ]
        let female: [(String, [String])] = [
            ("Excellent",     ["52-81", "58-80", "51-84", "63-91", "60-92", "70-92"]),
            ("Good",          ["82-92", "81-92", "85-96", "92-101", "93-103", "93-101"]),
            ("Above Average", ["93-102", "93-101", "97-104", "102-110", "104-111", "102-111"]),
            ("Average",       ["103-110", "102-110", "105-112", "111-118", "112-118", "112-121"]),
            ("Below Average", ["111-120", "111-119", "113-120", "119-124", "119-127", "122-126"]),
            ("Poor",          ["121-131", "120-129", "121-132", "125-132", "128-135", "127-133"]),
        ]
        func section(_ label: String, _ rows: [(String, [String])]) -> String {
            let header = "<tr><td class=\"rowhdr\" colspan=\"7\">\(label)</td></tr>"
            let body = rows.map { r in
                "<tr><td class=\"rowhdr\">\(r.0)</td>" + r.1.map { "<td>\($0)</td>" }.joined() + "</tr>"
            }.joined()
            return header + body
        }
        return """
        <p class="tabletitle">3-Minute Kasch Step Test: Post-exercise 1-Minute Heart Rate</p>
        <table class="norm">
          <tr><th></th>\(ages.map { "<th>\($0)</th>" }.joined())</tr>
          \(section("Male", male))
          \(section("Female", female))
        </table>
        """
    }()

    // MARK: - Body template (this is what would live in reports.thetext)

    static let bodyTemplate = """
    <div class="titlepage">
        {clinic_logo}
        <p class="tp-heading">Fitness Evaluation and Rehabilitation Plan</p>
        <p class="tp-phase">Phase 1</p>
        <p class="tp-patient">{patient_name}</p>
    </div>
    <div class="blankpage">&nbsp;</div>

    <h1>Cervical, Lumbar &amp; Cardiovascular Physical Performance Test Report</h1>
    <p class="subtitle">{report_date}</p>

    <h2>Background</h2>
    <p>Performance-based spinal assessments provide information about distinct domains of interest that are missing in a physical examination and self-report measure. Adding performance testing provides an assessment that increases the probability of improved patient outcomes. Physical disuse and neuromusculoskeletal weaknesses have been presented as major factors that can perpetuate chronic pain. Moreover, it has been found that exercises are effective preventive interventions for neck and back problems.</p>
    <p>In the cervical spine, muscle endurance has been identified as an important variable in the prognosis of neck pain and headache disorders. Researchers have found reliability and validity in a battery of cervical physical performance measures: cervical flexor endurance and extensor endurance. Additionally, normative values have been established with gender subgroups.</p>
    <p>In the lumbar spine, muscle endurance has been identified as an important variable in the prognosis of low back pain disorders. Several research teams have found reliability and validity in a battery of physical performance measures: lumbar extensor endurance, repeated sit-to-stand and fifty-foot fast walk. Additionally, normative values have been established with gender subgroups. During patient testing, each task was repeated twice (and averaged) within the test session, with the exception of the lumbar extensor endurance test (prone double straight-leg raise), which was performed once.</p>
    <p>Cardiovascular fitness can be evaluated with a submaximal step test. Researchers have found reliability and validity in the Kasch Step Test. Additionally, normative values have been established with gender and aging subgroups.</p>

    <h2>Examination</h2>
    <p><strong>{patient_name}</strong> is a <strong>{age}</strong>-year-old <strong>{gender}</strong>. Pre-test blood pressure and heart rate were within normal ranges. Functional Rating Index score was <strong>{fri_score}</strong> (0-20 = minimal disability; 21-40 = moderate disability; 41-60 = severe disability; &gt;61 = very severe disability). Pain intensity was <strong>{pain}</strong> (0 = no pain, 4 = worst possible pain).</p>
    {examination_findings}

    <h2>Therapy Plan &amp; Goal</h2>
    <p>{patient_name}'s performance was <strong>below satisfactory on {below_satisfactory_list}</strong>. We recommend supervised graded exercise rehabilitation for {patient_name}. The exercises will focus upon improving the endurance of the cervical and lumbar spine. Researchers recommend that exercise goals should aim above the mean to the "good to excellent" range because of the dose response of exercise therapy. Our goal is to improve the {goal_list} to the good range in the next {goal_months} months with re-evaluations at {reeval_days} days.</p>

    <p class="signoff">Sincerely,</p>

    {normative_tables}
    """

    static let reportCSS = """
    @page { size: letter; margin: 0.75in; }
    body { font-family: "Times New Roman", Georgia, serif; font-size: 12pt; line-height: 1.4; color: #111;
           -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .titlepage { text-align: center; page-break-after: always; padding-top: 48pt; }
    .tp-logo { max-width: 62%; height: auto; margin-bottom: 56pt; }
    .tp-heading { font-size: 16pt; font-weight: bold; margin: 0; }
    .tp-phase { font-size: 14pt; margin: 4pt 0 56pt 0; }
    .tp-patient { font-size: 14pt; font-weight: bold; margin: 0; }
    .blankpage { page-break-after: always; }
    h1 { font-size: 15pt; text-align: center; margin: 0 0 2pt 0; }
    .subtitle { text-align: center; font-weight: bold; margin: 0 0 14pt 0; }
    h2 { font-size: 12pt; margin: 14pt 0 2pt 0; }
    p { margin: 0 0 8pt 0; }
    .signoff { text-align: center; margin: 18pt 0; }
    .tabletitle { text-align: center; font-weight: bold; font-size: 10.5pt; margin: 16pt 0 4pt 0; }
    table.norm { border-collapse: collapse; width: 100%; font-size: 9.5pt; page-break-inside: avoid; }
    table.norm th, table.norm td { border: 1px solid #999; padding: 3px 6px; text-align: center; }
    table.norm th { background: #d9d9d9; font-weight: bold; }
    table.norm td.rowhdr { background: #efefef; font-weight: bold; text-align: left; }
    """
}
