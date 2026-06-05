//
//  Utilites.swift
//  KPRC-Payroll
//
//  Created by Hari Dass Khalsa on 12/18/25.
//

import Foundation
import SwiftUI


struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: some View {
        build()
    }
}


func strToBool(str: String) -> Bool {
    let validTrueValues: Set<String> = ["true", "yes", "1", "t"]
    let validFalseValues: Set<String> = ["false", "no", "0", "f"]
    
    guard !str.isEmpty else { return false }
    
    if validTrueValues.contains(str.lowercased()) {
        return true
    }
    if validFalseValues.contains(str.lowercased()) {
        return false
    }
    
    return (str.lowercased() == "t")
}

func boolToString(bool: Bool) -> String {
    
    return (bool ? "true" : "false")
}


func getHMString(time: String) -> String {
    var theStr = String(time.prefix(5))
    if(theStr.count == 0) {
        theStr = "00:00"
    }
    
    return theStr
}

func doubleToTimeString(time: Double) -> String {
    let hours = Int(time)
    let minutes = Int((time.truncatingRemainder(dividingBy: 1)) * 60)
    
    return String(format: "%02d:%02d", hours, minutes)
}

func timeStringToDouble(time: String) -> Double {
    // Expect formats like "HH:mm" or "H:mm". Fallbacks default to 0 on invalid input.
    let parts = time.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
    let hoursPart = parts.first.map(String.init) ?? "0"
    let minutesPart = parts.count > 1 ? String(parts[1]) : "0"
    let secondPart = parts.count > 2 ? String(parts[2]) : "0"

    let hours = Int(hoursPart) ?? 0
    var minutes = Int(minutesPart) ?? 0
    let seconds = Int(secondPart) ?? 0
    if(seconds > 30) {
        minutes += 1
    }

    // Clamp minutes to a valid range
    if minutes < 0 { minutes = 0 }
    if minutes > 59 { minutes = 59 }

    return Double(hours) + Double(minutes) / 60.0
}


func dictDateStringToDate(key: String,
                          dict: DictListType)->Date?{
    var retDate: Date? = nil
    let theDateStr = dict[key]?.strVal ?? ""
    if theDateStr != "" {
        retDate = StringToDate(dateString: theDateStr)
        
        
    }
    
   return retDate
}

func dictKeyToInt(key: String,
                          dict: DictListType)->Int
{
    var returnVal: Int = 0
    let  dictValStr = dict[key]?.strVal ?? "0.00"
    if dictValStr != "" {
        returnVal = Int(dictValStr) ?? 0
        
    }
    
   return returnVal
}

func dictKeyToDouble(key: String,
                          dict: DictListType)->Double
{
    var returnVal: Double = 0.0
    let  dictValStr = dict[key]?.strVal ?? "0.00"
    if dictValStr != "" {
        returnVal = Double(dictValStr) ?? 0.00
        
    }
    
   return returnVal
}

func dictKeyToBool(key: String,
                          dict: DictListType)->Bool
{
    var returnVal: Bool = false
    var  dictValStr = dict[key]?.strVal ?? "false"
    if dictValStr != "" {
        returnVal = strToBool(str: dictValStr)
        
    }
    
   return returnVal
}

 func getCurrentDateString(forSave: Bool = false) -> String {
    let dateFormatter = DateFormatter()
     if forSave {
         dateFormatter.dateFormat = "yyyy-MM-dd"
     }
     else {
         dateFormatter.dateFormat = "MM-dd-yyyy"
     }
    return dateFormatter.string(from: Date())
}
func currentYear() -> Int {
    return getYear(from: Date())
}

func getYear(from date: Date) -> Int {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)
    return year
}

func getSQLDate(from date: Date) -> String {
   
    return getDateString(from: date, formatStr: "yyyy-MM-dd")
}
func getDateString(from date: Date,
                   formatStr:   String = "MM-dd-yyyy") -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = formatStr
    return dateFormatter.string(from: date)
}

func getDateOptString(from date: Date?,
                   formatStr:   String = "MM-dd-yyyy") -> String {
    guard let date else { return "No Date Provided" }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = formatStr
    return dateFormatter.string(from: date)
}



func getCurrentTimeString()->String {
    let now = Date()
    let formatter = DateFormatter()
    // Set the desired format, e.g., "HH:mm:ss" for 24-hour format
    formatter.dateFormat = "HH:mm"
    let currentTimeString = formatter.string(from: now)

    print(currentTimeString) // Example output: "14:35:01"
    return currentTimeString
}

func getCurrentDateString()->String {
    let now = Date()
    let currentDateString = getDateString(from: now,
                                            formatStr: "yyyy-MM-dd")
    return currentDateString
}

func StringToDate(dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy"
    let targetCharacter: Character = "-"
    if let index = dateString.firstIndex(of: targetCharacter){
        let position = dateString.distance(from: dateString.startIndex, to: index)
        if position == 4 {
            dateFormatter.dateFormat = "yyyy-MM-dd"
        }
    }
        
    guard let date = dateFormatter.date(from: dateString) else {
        return nil
    }
    
     return date
}



func findTimeDifference(time1Str: String, time2Str: String) -> Double {
    var result: Double = 0.00
    
    let timeformatter = DateFormatter()
    // Set the format to match your input strings, e.g., "HH:mm" or "hh:mm a"
    if(time1Str.count == 5){
        timeformatter.dateFormat = "HH:mm"
    }else{
        timeformatter.dateFormat = "HH:mm:ss"

    }
    
    // Ensure both strings convert to Date objects
    guard let time1 = timeformatter.date(from: time1Str),
          let time2 = timeformatter.date(from: time2Str) else {
        return result
    }
    
    // Calculate the interval in seconds
    let interval = time2.timeIntervalSince(time1)
    
    // Convert seconds into hours and minutes
    let hours = Int(interval) / 3600
    let minutes = Int(interval.truncatingRemainder(dividingBy: 3600)) / 60
    
    // Format the output string
    // This example handles negative intervals for clearer display
    let sign = interval < 0 ? "-" : ""
    result = interval / 3600
    return result
}


func getTimeString(from: String)->String{
    var result: String = ""
    if(from.count == 5){
        result = from + ":00"
        
    }
    if(from.count == 0){
        result = "00:00:00"
    }
    
    return result
}

   
func formatTimeInterval(hours: Double) -> String {
    let sign = hours < 0 ? "-" : ""
    let totalSeconds = Int(abs(hours) * 3600)
    let h = totalSeconds / 3600
    let m = (totalSeconds % 3600) / 60
    let s = totalSeconds % 60
    return String(format: "%@%02d:%02d:%02d", sign, h, m, s)
}

func getFirstOfYear(year: Int)->Date{
    var calendar = Calendar.current
    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = 1
    dateComponents.day = 1
    return calendar.date(from: dateComponents)!
    
}


struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
                    .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                    .imageScale(.large)
            }
        }
        .buttonStyle(.plain)
    }
}


let mmddyyyyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy"
    return formatter
}()

let twoDecimalFormatter: NumberFormatter = {
   let formatter = NumberFormatter()
   formatter.numberStyle = .decimal
   formatter.minimumFractionDigits = 2 // Always show two decimal places
   formatter.maximumFractionDigits = 2 // Limit to two decimal places
   return formatter
}()

let integerFormatter: NumberFormatter = {
   let formatter = NumberFormatter()
   formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = false
   formatter.minimumFractionDigits = 0 // Always show two decimal places
   formatter.maximumFractionDigits = 0 // Limit to two decimal places
   return formatter
}()


func dataDictionaryIsEmpty(_ data: DictListType) -> Bool {
    var result: Bool = true
    for (_, value) in data {
        if !value.strVal.isEmpty {
            result = false
            break
        }
    }
    return result
    
}
  

extension Double {
    func rounded(digits: Int) -> Double {
        let multiplier = pow(10.0, Double(digits))
        return (self * multiplier).rounded() / multiplier
    }
}



let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // e.g., "12/18/2025"
        formatter.timeStyle = .none
        return formatter
    }()


// Source - https://stackoverflow.com/a/68475876
// Posted by Leo Dabus
// Retrieved 2026-02-07, License - CC BY-SA 4.0

extension NumberFormatter {
    static let spelled: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()
}

// Source - https://stackoverflow.com/a/68475876
// Posted by Leo Dabus
// Retrieved 2026-02-07, License - CC BY-SA 4.0

extension Numeric {
    var spelledOut: String? { NumberFormatter.spelled.string(for: self) }
}

func numberToWords(_ number: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    // Optional: set a specific locale if needed, e.g., "es_ES" for Spanish
    // formatter.locale = Locale(identifier: "es_ES")
    let wholePart: Int = Int(number)
    let decimalPart = number.truncatingRemainder(dividingBy: 1)
    let decimalInt = Int((decimalPart * 100).rounded(digits: 0))
    var decimalString: String = "\(decimalInt)/100"
    if decimalString.count == 5 {
        decimalString = "0" + decimalString
    }
    let wholeString: String = formatter.string(from: NSNumber(value: wholePart)) ?? "Not a valid number"
    
    
    return "\(wholeString) & \(decimalString)"
}



/// Filters a string to only allow digits and at most one decimal point.
 func filterNumeric(_ text: inout String) {
    var hasDecimal = false
    text = String(text.filter { ch in
        if ch.isNumber { return true }
        if ch == "." && !hasDecimal {
            hasDecimal = true
            return true
        }
        return false
    })
}

func formatInterval(val: String)->String{
    let negative = val.contains("-")
    let parts = val.split(separator: ":")
    let h = abs(Int(parts.count > 0 ? String(parts[0]) : "0") ?? 0)
    let m = abs(Int(parts.count > 1 ? String(parts[1]) : "0") ?? 0)
    let s = parts.count > 2 ? String(parts[2]) : "00"
    let formatted = String(format: "%@%02d:%02d",
                           negative ? "-" : "",
                           h, m)
    return "\(formatted)"

}

func deleteFile(at url: URL) {
    let fileManager = FileManager.default
    
    do {
        // Removes the file or directory at the specified URL
        try fileManager.removeItem(at: url)
        print("File deleted successfully.")
    } catch {
        // Handle the error (e.g., file not found, permission denied)
        print("Error deleting file: \(error.localizedDescription)")
    }
}


import CryptoKit
extension String{
    func encrypt()->String{
        //let field = "my_stable_field"
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        
        // Convert to a hex string for storage or comparison
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        print(hashString)
        
        return hashString
    }
}
