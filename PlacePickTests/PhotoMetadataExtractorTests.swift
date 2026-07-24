import Testing
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import PlacePick

struct PhotoMetadataExtractorTests {
    /// Builds a minimal 1x1 JPEG with the given EXIF/GPS properties embedded, so
    /// extraction can be verified without relying on the Photos library or Simulator assets.
    private func makeJPEGData(exif: [CFString: Any] = [:], gps: [CFString: Any] = [:]) -> Data {
        let pixel: [UInt8] = [255, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = context.makeImage()!
        _ = pixel

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)!

        var properties: [CFString: Any] = [:]
        if !exif.isEmpty { properties[kCGImagePropertyExifDictionary] = exif }
        if !gps.isEmpty { properties[kCGImagePropertyGPSDictionary] = gps }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    @Test func extractsCaptureDateFromEXIF() {
        let jpegData = makeJPEGData(exif: [kCGImagePropertyExifDateTimeOriginal: "2026:07:18 09:12:00"])

        let metadata = PhotoMetadataExtractor.extractMetadata(from: jpegData)

        var expected = DateComponents()
        expected.year = 2026; expected.month = 7; expected.day = 18
        expected.hour = 9; expected.minute = 12; expected.second = 0
        let expectedDate = Calendar.current.date(from: expected)!

        #expect(metadata.capturedAt == expectedDate)
    }

    @Test func extractsGPSCoordinateWithCorrectSign() {
        let jpegData = makeJPEGData(gps: [
            kCGImagePropertyGPSLatitude: 37.7749,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 122.4194,
            kCGImagePropertyGPSLongitudeRef: "W"
        ])

        let metadata = PhotoMetadataExtractor.extractMetadata(from: jpegData)

        #expect(metadata.latitude == 37.7749)
        #expect(metadata.longitude == -122.4194)
    }

    @Test func returnsNilCaptureDateWhenNoEXIFPresent() {
        let jpegData = makeJPEGData()

        let metadata = PhotoMetadataExtractor.extractMetadata(from: jpegData)

        #expect(metadata.capturedAt == nil)
    }

    @Test func returnsNilCoordinateWhenNoGPSPresent() {
        let jpegData = makeJPEGData(exif: [kCGImagePropertyExifDateTimeOriginal: "2026:07:18 09:12:00"])

        let metadata = PhotoMetadataExtractor.extractMetadata(from: jpegData)

        #expect(metadata.latitude == nil)
        #expect(metadata.longitude == nil)
    }

    @Test func garbageDataProducesNilMetadataRatherThanCrashing() {
        let metadata = PhotoMetadataExtractor.extractMetadata(from: Data([0x00, 0x01, 0x02]))

        #expect(metadata.capturedAt == nil)
        #expect(metadata.latitude == nil)
    }
}
