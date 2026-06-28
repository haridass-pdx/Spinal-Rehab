//
//  ReportDataClass.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//

import Foundation


class ReportDataClass: pgClientClass{
    
    class func getReportData(reportID: Int) async -> String {
        
        let rdc = ReportDataClass()
        let qry = "SELECT thetext FROM reports WHERE id = \(reportID);"
        let resStr = await rdc.getResults(qry: qry)
        
        return resStr[0]
        
    }
    
}
