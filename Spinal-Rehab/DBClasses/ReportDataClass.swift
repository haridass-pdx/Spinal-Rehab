//
//  ReportDataClass.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//

import Foundation


class ReportDataClass: pgClientClass{

    /// reports.id row that holds the performance-report body template
    static let performanceReportID = 1

    class func getReportData(reportID: Int) async -> String? {

        let rdc = ReportDataClass()
        let qry = "SELECT thetext FROM reports WHERE id = \(reportID);"
        let resStr = await rdc.getResults(qry: qry)

        return resStr.first

    }

    /// Insert or update reports.thetext for the given row. Only touches id and
    /// thetext so it works regardless of other columns on the table. Returns
    /// true when a read-back confirms the write landed (executeQueryND only
    /// logs errors, so this is the caller's success signal).
    class func saveReportData(reportID: Int, text: String) async -> Bool {
        let rdc = ReportDataClass()
        let escaped = text.replacingOccurrences(of: "'", with: "''")
        let qry: String
        if await getReportData(reportID: reportID) == nil {
            qry = "INSERT INTO reports (id, thetext) VALUES (\(reportID), '\(escaped)');"
        } else {
            qry = "UPDATE reports SET thetext = '\(escaped)' WHERE id = \(reportID);"
        }
        await rdc.executeQueryND(text: qry)
        return await getReportData(reportID: reportID) == text
    }

    /// Body template for the performance report: the reports.thetext row when
    /// present, otherwise the built-in default in ReportRenderer.
    class func loadBodyTemplate() async -> String {
        if let text = await getReportData(reportID: performanceReportID),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return ReportRenderer.bodyTemplate
    }

}
