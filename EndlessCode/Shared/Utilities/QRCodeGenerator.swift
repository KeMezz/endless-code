//
//  QRCodeGenerator.swift
//  EndlessCode
//
//  QR 코드 생성 유틸리티
//

#if canImport(AppKit)
import CoreImage
import AppKit

// MARK: - QRCodeGenerator

/// QR 코드 생성 유틸리티
enum QRCodeGenerator {
    /// 문자열로부터 QR 코드 이미지 생성
    /// - Parameters:
    ///   - string: QR 코드로 인코딩할 문자열
    ///   - size: 생성할 이미지의 크기 (기본: 200)
    /// - Returns: 생성된 NSImage, 실패 시 nil
    static func generate(from string: String, size: CGFloat = 200) -> NSImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        let context = CIContext()

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 높은 에러 정정 레벨

        guard let ciImage = filter.outputImage else {
            return nil
        }

        // QR 코드는 기본적으로 작은 크기로 생성되므로 스케일링 필요
        let transform = CGAffineTransform(scaleX: size / ciImage.extent.width,
                                         y: size / ciImage.extent.height)
        let scaledImage = ciImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
}
#endif
