//
//  FollowUpReportRenderer.swift
//  Spinal-Rehab
//
//  HTML assembly for the multi-visit Patient Follow-up Report. One test = one
//  page: `bodyTemplate` describes a single page (with {tokens}), and
//  `fullHTML` renders it once per page dict (one dict per qualifying test,
//  built by FollowUpReportContext) and joins the results with a page break.
//  Mirrors ReportRenderer's split between a Postgres-editable {token} body
//  and a CSS wrapper kept out of the token parser.
//

import Foundation

enum FollowUpReportRenderer {

    /// One of the tests this report knows how to chart against a goal.
    /// `goalValue`/`goalTargetDate` pull the matching pair of columns off
    /// PatientDataGoal — that struct only has these 3 tests today, so this
    /// list can't (yet) be extended to arbitrary test_table rows.
    struct GoalTest {
        let title: String
        let unit: String
        let normativeTitle: String
        let keywords: [String]
        let goalValue: (PatientDataGoal) -> Double
        let goalTargetDate: (PatientDataGoal) -> Date?
    }

    static let goalTests: [GoalTest] = [
        GoalTest(title: "Cervical Flexor Muscle Endurance", unit: "seconds",
                 normativeTitle: "Normative Performance Data: Cervical Flexor Endurance (seconds)",
                 keywords: ["flex"],
                 goalValue: { $0.cerv_flex_goal }, goalTargetDate: { $0.cerv_flex_td }),
        GoalTest(title: "Lumbar Extensor Muscle Endurance", unit: "seconds",
                 normativeTitle: "Normative Performance Data: Lumbar Extension Endurance (seconds)",
                 keywords: ["exten"],
                 goalValue: { $0.lumbar_ext_goal }, goalTargetDate: { $0.lumbar_ext_td }),
        GoalTest(title: "Repeated Sit-to-Stand", unit: "seconds",
                 normativeTitle: "Normative Performance Data: Sit-to-Stand (seconds)",
                 keywords: ["sit"],
                 goalValue: { $0.sit_stand_goal }, goalTargetDate: { $0.sit_stand_td }),
    ]

    /// Render one page per dict in `pages` and join with a page break.
    static func fullHTML(template: String = bodyTemplate, pages: [[String: String]]) -> String {
        guard !pages.isEmpty else { return PDFReportEngine.wrap(body: "", css: reportCSS) }
        let parsed = ParsedTemplate(rawText: template)
        let body = pages.map { parsed.render(with: $0) }
            .joined(separator: "<div class=\"pagebreak\"></div>")
        return PDFReportEngine.wrap(body: body, css: reportCSS)
    }

    // MARK: - Body template (default/fallback; the live copy is reports.thetext id = followUpReportID)

    static let bodyTemplate = """
    <h1>Patient Follow-up Report</h1>
    <p class="headerline"><strong>Patient Name:</strong> {patient_name} &nbsp;&nbsp;&nbsp; <strong>Report Date:</strong> {report_date}</p>

    <h2>Test: {test_title}</h2>
    <p><strong>Baseline Test Date:</strong> {baseline_date}<br>
    <strong>Baseline Score:</strong> {baseline_score}</p>

    {followup_rows}

    <p><strong>Goal:</strong> {goal_value}<br>
    <strong>Target Date:</strong> {goal_target_date}</p>

    <p class="charttitle">{test_title}</p>
    {chart}

    {normative_table}

    <h2>Plan &amp; Goal</h2>
    <p>{patient_title} {patient_name} has made progress in this phase of the supervised therapeutic rehabilitation program. {pronoun_subject} will continue with the program, and we will re-test at the next scheduled visit.</p>

    <p class="signoff">Sincerely,<br><br>{physician_name}</p>
    """

    static let reportCSS = """
    @page { size: letter; margin: 0.75in; }
    body { font-family: "Times New Roman", Georgia, serif; font-size: 12pt; line-height: 1.4; color: #111;
           -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    h1 { font-size: 16pt; text-align: center; margin: 0 0 10pt 0; }
    h2 { font-size: 12pt; margin: 12pt 0 2pt 0; }
    p { margin: 0 0 8pt 0; }
    .headerline { margin: 0 0 10pt 0; }
    .signoff { text-align: center; margin: 18pt 0; }
    .charttitle { text-align: center; font-style: italic; margin: 12pt 0 4pt 0; }
    .pagebreak { page-break-after: always; }
    .tabletitle { text-align: center; font-weight: bold; font-size: 10.5pt; margin: 16pt 0 4pt 0; }
    table.norm { border-collapse: collapse; width: 100%; font-size: 9.5pt; page-break-inside: avoid; }
    table.norm th, table.norm td { border: 1px solid #999; padding: 3px 6px; text-align: center; }
    table.norm th { background: #d9d9d9; font-weight: bold; }
    table.norm td.rowhdr { background: #efefef; font-weight: bold; text-align: left; }
    """

    // MARK: - Sample values (mirrors 315.pdf; feeds the template editor's preview + unknown-token check)

    static let sampleValues: [[String: String]] = {
        let followupRows = """
        <p><strong>1st Follow-up Test Date:</strong> August 1, 2019<br>
        <strong>1st Follow-up Score:</strong> 64 seconds<br>
        <strong>Percent Improvement:</strong> 30.6%</p>
        """
        var d = normalData(); d.gender = "Male"; d.mean = 64; d.excellent = 81; d.good = 70; d.fair = 59; d.poor = 48; d.verypoor = 47
        var f = normalData(); f.gender = "Female"; f.mean = 46; f.excellent = 60; f.good = 51; f.fair = 42; f.poor = 33; f.verypoor = 32
        let table = ReportRenderer.normativeTable(
            title: "Normative Performance Data: Cervical Flexor Endurance (seconds)",
            records: [d, f], lowerIsBetter: false)
        let chart = FollowUpChartRenderer.svg(
            points: [("baseline", 49), ("1st follow-up", 64)], goal: 70)

        return [[
            "patient_name": "Jim Doe",
            "report_date": "August 1, 2019",
            "test_title": "Cervical Flexor Muscle Endurance",
            "baseline_date": "July 1, 2019",
            "baseline_score": "49 seconds",
            "followup_rows": followupRows,
            "goal_value": "> 70 seconds",
            "goal_target_date": "September 1, 2019",
            "chart": chart,
            "normative_table": table,
            "patient_title": "Mr.",
            "pronoun_subject": "He",
            "physician_name": "Ron Feise, DC",
        ]]
    }()
}
