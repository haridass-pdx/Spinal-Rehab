//
//  FollowUpChartRenderer.swift
//  Spinal-Rehab
//
//  Inline-SVG trend chart for the follow-up report: one point per visit that
//  actually recorded the test (baseline + Nth follow-up), plus the patient's
//  goal drawn as a constant horizontal line across the whole chart width (per
//  the sample report, the goal is a flat "ceiling" line, not a target-date
//  point). Pure string building — no JS, no external resources — so it drops
//  straight into the same loadHTMLString/print pipeline every other report
//  in this app uses.
//

import Foundation

enum FollowUpChartRenderer {

    /// `points` must have at least one entry (the baseline); each label is
    /// shown under its column ("baseline", "1st follow-up", "2nd follow-up", …).
    static func svg(points: [(label: String, value: Double)], goal: Double?) -> String {
        guard !points.isEmpty else { return "" }

        let leftMargin: Double = 46
        let rightMargin: Double = 24
        let topMargin: Double = 16
        let bottomMargin: Double = 34
        let colWidth: Double = 110
        let plotHeight: Double = 190

        let dataMax = points.map(\.value).max() ?? 0
        let ceilingCandidate = max(dataMax, goal ?? 0)
        var yMax = (ceilingCandidate / 10).rounded(.up) * 10
        if yMax <= ceilingCandidate { yMax += 10 }
        if yMax <= 0 { yMax = 10 }

        let innerWidth = colWidth * Double(max(points.count - 1, 0))
        let width = leftMargin + innerWidth + rightMargin
        let height = topMargin + plotHeight + bottomMargin

        func yPos(_ value: Double) -> Double {
            topMargin + plotHeight - (value / yMax) * plotHeight
        }
        func xPos(_ index: Int) -> Double {
            leftMargin + Double(index) * colWidth
        }

        var svg = ""
        svg += "<svg viewBox=\"0 0 \(width) \(height)\" width=\"\(width)\" height=\"\(height)\" xmlns=\"http://www.w3.org/2000/svg\">"

        // Plot background
        svg += "<rect x=\"\(leftMargin)\" y=\"\(topMargin)\" width=\"\(innerWidth)\" height=\"\(plotHeight)\" fill=\"#e0e0e0\"/>"

        // Gridlines + y-axis labels, every 10 units.
        var gridValue = 0.0
        while gridValue <= yMax {
            let y = yPos(gridValue)
            svg += "<line x1=\"\(leftMargin)\" y1=\"\(y)\" x2=\"\(leftMargin + innerWidth)\" y2=\"\(y)\" stroke=\"#333\" stroke-width=\"0.75\"/>"
            svg += "<text x=\"\(leftMargin - 6)\" y=\"\(y + 3)\" font-size=\"10\" text-anchor=\"end\" fill=\"#111\">\(Int(gridValue))</text>"
            gridValue += 10
        }

        // Goal line: constant horizontal "ceiling" across the full width, with a
        // marker at every x position (matches the sample's row of triangles).
        if let goal {
            let gy = yPos(goal)
            svg += "<line x1=\"\(leftMargin)\" y1=\"\(gy)\" x2=\"\(leftMargin + innerWidth)\" y2=\"\(gy)\" stroke=\"#c9a400\" stroke-width=\"1.5\"/>"
            for i in points.indices {
                let x = xPos(i)
                svg += trianglePath(cx: x, cy: gy, fill: "#f2d200")
            }
        }

        // Actual-value polyline + square markers.
        let linePoints = points.indices.map { "\(xPos($0)),\(yPos(points[$0].value))" }.joined(separator: " ")
        svg += "<polyline points=\"\(linePoints)\" fill=\"none\" stroke=\"#c2185b\" stroke-width=\"2\"/>"
        for i in points.indices {
            let x = xPos(i)
            let y = yPos(points[i].value)
            svg += "<rect x=\"\(x - 4)\" y=\"\(y - 4)\" width=\"8\" height=\"8\" fill=\"#c2185b\"/>"
        }

        // X-axis category labels.
        for i in points.indices {
            let x = xPos(i)
            svg += "<text x=\"\(x)\" y=\"\(topMargin + plotHeight + 18)\" font-size=\"10\" text-anchor=\"middle\" fill=\"#111\">\(htmlEscape(points[i].label))</text>"
        }

        svg += "</svg>"
        return svg
    }

    private static func trianglePath(cx: Double, cy: Double, fill: String) -> String {
        let half = 5.0
        let top = cy - half
        let bottom = cy + half
        let left = cx - half
        let right = cx + half
        return "<polygon points=\"\(cx),\(top) \(right),\(bottom) \(left),\(bottom)\" fill=\"\(fill)\" stroke=\"#8a7600\" stroke-width=\"0.5\"/>"
    }

    private static func htmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
