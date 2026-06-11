//
//  DictCoding.swift
//  Spinal-Rehab
//

import Foundation

// MARK: - Public API

struct DictEncoder {
    func encode<T: Encodable>(_ value: T) throws -> [String: String] {
        let enc = _DictEncoder()
        try value.encode(to: enc)
        return enc.storage
    }
}

struct DictDecoder {
    func decode<T: Decodable>(_ type: T.Type, from dict: [String: String]) throws -> T {
        try T(from: _DictDecoder(storage: dict))
    }
}

// MARK: - Encoder

private final class _DictEncoder: Encoder {
    var storage: [String: String] = [:]
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(DictKeyedEncoding<Key>(encoder: self))
    }
    func unkeyedContainer() -> UnkeyedEncodingContainer { fatalError("unkeyed unsupported") }
    func singleValueContainer() -> SingleValueEncodingContainer { fatalError("singleValue unsupported") }
}

private struct DictKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: _DictEncoder
    var codingPath: [CodingKey] { encoder.codingPath }

    private func put(_ s: String, _ key: Key) { encoder.storage[key.stringValue] = s }

    mutating func encodeNil(forKey key: Key)            { put("", key) }
    mutating func encode(_ v: Bool,   forKey key: Key)  { put(boolToString(bool: v), key) }
    mutating func encode(_ v: String, forKey key: Key)  { put(v, key) }
    mutating func encode(_ v: Double, forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: Float,  forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: Int,    forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: Int8,   forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: Int16,  forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: Int32,  forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: Int64,  forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: UInt,   forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: UInt8,  forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: UInt16, forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: UInt32, forKey key: Key)  { put(String(v), key) }
    mutating func encode(_ v: UInt64, forKey key: Key)  { put(String(v), key) }

    mutating func encode<T: Encodable>(_ v: T, forKey key: Key) throws {
        if let d = v as? Date {
            put(getDateOptString(from: d, formatStr: DictCodingDate.dateFormat), key)
            return
        }
        // Flat-record assumption: any other Codable type round-trips via String.
        put(String(describing: v), key)
    }

    mutating func nestedContainer<K: CodingKey>(keyedBy _: K.Type, forKey _: Key) -> KeyedEncodingContainer<K> { fatalError("nested unsupported") }
    mutating func nestedUnkeyedContainer(forKey _: Key) -> UnkeyedEncodingContainer { fatalError("nested unsupported") }
    mutating func superEncoder() -> Encoder { encoder }
    mutating func superEncoder(forKey _: Key) -> Encoder { encoder }
}

// MARK: - Decoder

private final class _DictDecoder: Decoder {
    let storage: [String: String]
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    init(storage: [String: String]) { self.storage = storage }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(DictKeyedDecoding<Key>(decoder: self))
    }
    func unkeyedContainer() -> UnkeyedDecodingContainer { fatalError("unkeyed unsupported") }
    func singleValueContainer() -> SingleValueDecodingContainer { fatalError("singleValue unsupported") }
}

private struct DictKeyedDecoding<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: _DictDecoder
    var codingPath: [CodingKey] { decoder.codingPath }
    var allKeys: [Key] { decoder.storage.keys.compactMap { Key(stringValue: $0) } }

    func contains(_ key: Key) -> Bool { decoder.storage[key.stringValue] != nil }
    func decodeNil(forKey key: Key) -> Bool { (decoder.storage[key.stringValue] ?? "").isEmpty }

    private func raw(_ key: Key) -> String { decoder.storage[key.stringValue] ?? "" }

    func decode(_: Bool.Type,   forKey key: Key) -> Bool   { strToBool(str: raw(key)) }
    func decode(_: String.Type, forKey key: Key) -> String { raw(key) }
    func decode(_: Double.Type, forKey key: Key) -> Double { Double(raw(key)) ?? 0 }
    func decode(_: Float.Type,  forKey key: Key) -> Float  { Float(raw(key)) ?? 0 }
    func decode(_: Int.Type,    forKey key: Key) -> Int    { Int(raw(key)) ?? 0 }
    func decode(_: Int8.Type,   forKey key: Key) -> Int8   { Int8(raw(key)) ?? 0 }
    func decode(_: Int16.Type,  forKey key: Key) -> Int16  { Int16(raw(key)) ?? 0 }
    func decode(_: Int32.Type,  forKey key: Key) -> Int32  { Int32(raw(key)) ?? 0 }
    func decode(_: Int64.Type,  forKey key: Key) -> Int64  { Int64(raw(key)) ?? 0 }
    func decode(_: UInt.Type,   forKey key: Key) -> UInt   { UInt(raw(key)) ?? 0 }
    func decode(_: UInt8.Type,  forKey key: Key) -> UInt8  { UInt8(raw(key)) ?? 0 }
    func decode(_: UInt16.Type, forKey key: Key) -> UInt16 { UInt16(raw(key)) ?? 0 }
    func decode(_: UInt32.Type, forKey key: Key) -> UInt32 { UInt32(raw(key)) ?? 0 }
    func decode(_: UInt64.Type, forKey key: Key) -> UInt64 { UInt64(raw(key)) ?? 0 }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        if type == Date.self {
            let d = StringToDate(dateString: raw(key)) ?? Date(timeIntervalSince1970: 0)
            return d as! T
        }
        // Fallback: rebuild via a single-key decoder
        return try T(from: _DictDecoder(storage: decoder.storage))
    }

    func nestedContainer<K: CodingKey>(keyedBy _: K.Type, forKey _: Key) -> KeyedDecodingContainer<K> { fatalError("nested unsupported") }
    func nestedUnkeyedContainer(forKey _: Key) -> UnkeyedDecodingContainer { fatalError("nested unsupported") }
    func superDecoder() -> Decoder { decoder }
    func superDecoder(forKey _: Key) -> Decoder { decoder }
}

// MARK: - Date format

enum DictCodingDate {
    // Matches the wire format used by existing recToDict/readDictValues helpers.
    static let dateFormat = "yyyy-MM-dd"
}
