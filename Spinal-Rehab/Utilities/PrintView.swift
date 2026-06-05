//
//  PrintView.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 2/8/26.
//

import Foundation
import SwiftUI
//import UIKit
import Cocoa
import PDFKit


func printSwiftUIView(theView: some View) {
    let hostingView = NSHostingView(rootView: theView)
    hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 200)

    let printInfo = NSPrintInfo.shared
    printInfo.topMargin = 20
    printInfo.leftMargin = 20
    printInfo.rightMargin = 20
    printInfo.bottomMargin = 20

    let printOperation = NSPrintOperation(view: hostingView, printInfo: printInfo)
    printOperation.run()
}




func printPDF(document: PDFDocument) {
    // 1. Define the NSPrintInfo
    let printInfo = NSPrintInfo.shared
    printInfo.horizontalPagination = .fit
    printInfo.verticalPagination = .fit
    printInfo.orientation = .portrait
    // Add other settings as needed

    // 2. Get the print operation from the PDFDocument
    if let printOperation = document.printOperation(
        for: printInfo,
        scalingMode: .pageScaleNone,
        autoRotate: true
    ) {
        // 3. Optional: Customize the print panel
        // printOperation.printPanel = myCustomPrintPanel()

        // 4. Run the print operation
        printOperation.run()
    }
}



