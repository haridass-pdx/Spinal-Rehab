//
//  ImageEncoding.swift
//  Spinal-Rehab
//
//  Normalizes imported images to 8-bit sRGB SDR JPEG before they are stored in
//  Postgres. iPhone photos arrive as wide-gamut (Display P3) with HDR gain maps,
//  which render inconsistently (washed-out / blown-out) in PDF reports and plain
//  image views. Flattening to sRGB + downscaling also keeps bytea rows small.
//

import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

enum ImageEncoding {

    /// Decode arbitrary image data, honoring EXIF orientation, downscale so the
    /// longest edge is at most `maxDimension`, flatten to 8-bit sRGB (dropping
    /// any HDR/wide-gamut content), and re-encode as JPEG.
    /// Returns nil if the data isn't a decodable image.
    static func normalizedJPEG(from data: Data,
                               maxDimension: CGFloat = 1200,
                               quality: CGFloat = 0.8) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        // Downscale + apply orientation up front (cheaper, and strips HDR headroom).
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary)
            ?? CGImageSourceCreateImageAtIndex(source, 0, nil)
        guard let cgImage = cg else { return nil }

        // Redraw into an 8-bit sRGB context to force SDR / standard gamut.
        let width = cgImage.width
        let height = cgImage.height
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let flattened = ctx.makeImage() else { return nil }

        // Encode as JPEG.
        let outData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(outData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, flattened, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return outData as Data
    }

    /// Convenience: normalized JPEG bytes from a file URL (used by the image picker).
    static func normalizedJPEG(fromFileAt url: URL,
                               maxDimension: CGFloat = 1200,
                               quality: CGFloat = 0.8) -> Data? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return normalizedJPEG(from: data, maxDimension: maxDimension, quality: quality)
    }
}
