//
//  QRScannerService.swift
//  EndlessCode
//
//  QR 코드 스캔 서비스
//

#if os(iOS)
import AVFoundation
import Foundation

// MARK: - QRScannerServiceProtocol

/// QR 스캔 서비스 프로토콜
protocol QRScannerServiceProtocol: Sendable {
    /// 스캔 시작
    /// - Returns: 스캔된 QR 코드 데이터 스트림
    func startScanning() async -> AsyncStream<QRCodeData>

    /// 스캔 중지
    func stopScanning() async

    /// 카메라 권한 요청
    /// - Returns: 권한 허용 여부
    func requestCameraPermission() async -> Bool

    /// 카메라 권한 상태 확인
    /// - Returns: 권한 허용 여부
    func checkCameraPermission() -> Bool
}

// MARK: - QRScannerService

/// QR 코드 스캔 서비스 구현
final class QRScannerService: NSObject, QRScannerServiceProtocol, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    // MARK: - Private Properties

    private var captureSession: AVCaptureSession?
    private var continuation: AsyncStream<QRCodeData>.Continuation?

    // MARK: - Public Methods

    /// 스캔 시작
    func startScanning() async -> AsyncStream<QRCodeData> {
        let (stream, continuation) = AsyncStream.makeStream(of: QRCodeData.self)
        self.continuation = continuation

        // 카메라 권한 확인
        guard await requestCameraPermission() else {
            continuation.finish()
            return stream
        }

        // 캡처 세션 설정
        do {
            try await setupCaptureSession()
        } catch {
            continuation.finish()
            return stream
        }

        // 세션 시작
        captureSession?.startRunning()

        return stream
    }

    /// 스캔 중지
    func stopScanning() async {
        captureSession?.stopRunning()
        captureSession = nil
        continuation?.finish()
        continuation = nil
    }

    /// 카메라 권한 요청
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// 카메라 권한 상태 확인
    func checkCameraPermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }

    // MARK: - Private Methods

    /// 캡처 세션 설정
    private func setupCaptureSession() async throws {
        let session = AVCaptureSession()

        // 카메라 디바이스 가져오기
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            throw QRScannerError.cameraNotAvailable
        }

        // 입력 추가
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            throw QRScannerError.inputFailed
        }

        guard session.canAddInput(videoInput) else {
            throw QRScannerError.inputFailed
        }
        session.addInput(videoInput)

        // 메타데이터 출력 추가
        let metadataOutput = AVCaptureMetadataOutput()

        guard session.canAddOutput(metadataOutput) else {
            throw QRScannerError.outputFailed
        }
        session.addOutput(metadataOutput)

        // QR 코드 타입 설정
        metadataOutput.metadataObjectTypes = [.qr]
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        self.captureSession = session
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        Task {
            await processQRCode(stringValue)
        }
    }

    /// QR 코드 처리
    private func processQRCode(_ string: String) {
        do {
            let qrData = try QRCodeData.fromJSON(string)
            continuation?.yield(qrData)

            // 스캔 성공 후 자동 중지
            Task {
                await stopScanning()
            }
        } catch {
            // 잘못된 QR 코드 형식은 무시
        }
    }

    // MARK: - Cleanup

    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - QRScannerError

/// QR 스캐너 에러
enum QRScannerError: Error, LocalizedError {
    case cameraNotAvailable
    case permissionDenied
    case inputFailed
    case outputFailed

    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available"
        case .permissionDenied:
            return "Camera permission denied"
        case .inputFailed:
            return "Failed to add camera input"
        case .outputFailed:
            return "Failed to add metadata output"
        }
    }
}
#endif
