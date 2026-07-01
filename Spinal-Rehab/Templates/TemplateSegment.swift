//
//  TemplateSegment.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/28/26.
//

import Foundation

enum TemplateSegment: Equatable {
    case literal(String)
    case token(String)
}

struct ParsedTemplate {
    let segments: [TemplateSegment]
    
    // Parse the database string into optimized segments ONCE when fetched
    init(rawText: String) {
        var result: [TemplateSegment] = []
        let scanner = Scanner(string: rawText)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            // 1. Scan up to the opening brace
            if let text = scanner.scanUpToString("{"), !text.isEmpty {
                result.append(.literal(text))
            }
            
            // 2. Check if we hit a token
            if scanner.scanString("{") != nil {
                if let token = scanner.scanUpToString("}"), !token.isEmpty {
                    result.append(.token(token))
                    _ = scanner.scanString("}") // Consume closing brace
                } else {
                    // Malformed tag, treat brace as literal
                    result.append(.literal("{"))
                }
            }
        }
        self.segments = result
    }
    
    // Lightning-fast rendering function called by your SwiftUI views
    func render(with values: [String: String]) -> String {
        return segments.map { segment in
            switch segment {
            case .literal(let text):
                return text
            case .token(let key):
                return values[key] ?? "{Missing: \(key)}" // Safe fallback
            }
        }.joined()
    }
}
