//
//  RehabProgramReportRenderer.swift
//  Spinal-Rehab
//
//  Builds the printable HTML handout for a rehab_program: one grid row per
//  linked exercise (name, description, default sets/reps) followed by a
//  gallery of every image attached to that exercise. Reuses
//  PDFReportEngine.wrap/HTMLPreviewView/PDFReportEngine the same way
//  ReportRenderer does for the performance report.
//

import Foundation

enum RehabProgramReportRenderer {

    static func buildHTML(program: RehabProgramData) async -> String {
        let items = await rehab_program_listClass().buildExerciseList(rehabId: program.id)
        let exC = exerciseClass()

        var rows = ""
        for item in items {
            guard let exercise = await exC.getExercise(id: item.exercise_id) else { continue }
            rows += await exerciseRow(exercise: exercise, sets: exercise.def_sets, reps: exercise.def_reps)
        }

        let body = """
        <h1>Rehabilitation Plan - \(htmlEscape(program.name))</h1>
        \(table(rows: rows))
        """
        return PDFReportEngine.wrap(body: body, css: css)
    }

    /// Same handout, but for a patient's assigned program: uses the reps/sets
    /// stored per-patient in patient_rehab_list, and prints the patient's name
    /// and the assignment date under the title.
    static func buildHTML(patientProgram: PatientRehabProgramData, patientName: String) async -> String {
        let items = await patient_rehab_listClass().buildExerciseList(programId: patientProgram.id)
        let exC = exerciseClass()

        var rows = ""
        for item in items {
            guard let exercise = await exC.getExercise(id: item.exercise_id) else { continue }
            rows += await exerciseRow(exercise: exercise, sets: item.sets, reps: item.reps)
        }

        let dateStr = getDateOptString(from: patientProgram.prdate, formatStr: "MM/dd/yyyy")
        let body = """
        <h1>Rehabilitation Plan - \(htmlEscape(patientProgram.name))</h1>
        <p class="patientline"><strong>\(htmlEscape(patientName))</strong> &nbsp;&nbsp; \(htmlEscape(dateStr))</p>
        \(table(rows: rows))
        """
        return PDFReportEngine.wrap(body: body, css: css)
    }

    // WKWebView's AppKit print pagination does not reliably honor
    // page-break-inside: avoid on <tr>/<tbody> — rows (and even single cells)
    // can split mid-content across a page boundary. A block-level <div> does
    // not have this problem, so each exercise is one grid-row div rather than
    // a <table> row.
    private static func exerciseRow(exercise: ExerciseData, sets: Int, reps: Int) async -> String {
        let images = await exercise_imagesClass().buildImageList(exerciseId: exercise.id)
        let gallery = images
            .map { "<img src=\"data:image/jpeg;base64,\($0.image.base64EncodedString())\">" }
            .joined()

        return """
        <div class="item">
          <div class="row">
            <div class="c name">\(htmlEscape(exercise.name))</div>
            <div class="c desc">\(htmlEscape(exercise.description))</div>
            <div class="c num">\(sets)</div>
            <div class="c num">\(reps)</div>
          </div>
          <div class="gallery">\(gallery)</div>
        </div>
        """
    }

    private static func table(rows: String) -> String {
        """
        <div class="rehab">
          <div class="row hrow">
            <div class="c">Name</div>
            <div class="c">Description</div>
            <div class="c num">Sets</div>
            <div class="c num">Reps</div>
          </div>
          \(rows)
        </div>
        """
    }

    private static func htmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static let css = """
    @page { size: letter; margin: 0.5in; }
    body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 11pt; color: #111;
           -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    h1 { font-size: 15pt; margin: 0 0 10pt 0; }
    .patientline { font-size: 11pt; margin: 0 0 10pt 0; }
    .rehab { width: 100%; border: 1px solid #999; }
    .row { display: grid; grid-template-columns: 18% 1fr 60px 60px; }
    .row.hrow { background: #d9d9d9; font-weight: bold; }
    .c { padding: 6px 8px; text-align: left; }
    .c:nth-child(n+2) { border-left: 1px solid #999; }
    .c.num { text-align: center; }
    .rehab > *:not(:first-child) { border-top: 1px solid #999; }
    .gallery { display: flex; flex-wrap: wrap; gap: 8px; padding: 0 8px 8px 8px; }
    .gallery:empty { padding: 0; }
    .gallery img { height: 1in; width: auto; object-fit: contain; border: 1px solid #ccc; }
    .item { page-break-inside: avoid; }
    """
}
