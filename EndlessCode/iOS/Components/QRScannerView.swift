//
//  QRScannerView.swift
//  EndlessCode
//
//  QR 코드 스캐너 뷰
//

#if os(iOS)
import SwiftUI
import AVFoundation

// MARK: - QRScannerView

/// QR 코드 스캐너 뷰
struct QRScannerView: View {
    // MARK: - Properties

    let onScanComplete: (QRCodeData) -> Void
    let onDismiss: () -> Void

    @State private var scannerService = QRScannerService()
    @State private var isScanning = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            // 카메라 프리뷰
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)

            // 오버레이
            VStack {
                // 상단 바
                topBar

                Spacer()

                // 안내 텍스트
                instructionText

                Spacer()

                // 하단 버튼
                bottomBar
            }
            .padding()

            // 에러 메시지
            if let error = errorMessage {
                VStack {
                    Spacer()
                    errorView(error)
                        .padding()
                }
            }
        }
        .accessibilityIdentifier("qrScannerView")
        .task {
            await startScanning()
        }
    }

    // MARK: - Private Views

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("Close scanner")
            .accessibilityIdentifier("closeScannerButton")

            Spacer()
        }
    }

    private var instructionText: some View {
        VStack(spacing: 12) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.white)
                .shadow(radius: 4)

            Text("Scan QR Code")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(radius: 4)

            Text("Position the QR code within the frame")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .shadow(radius: 4)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }

    private var bottomBar: some View {
        Button(action: onDismiss) {
            Text("Cancel")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red.opacity(0.8))
                .cornerRadius(12)
        }
        .frame(height: 50)
        .accessibilityIdentifier("cancelScanButton")
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red)
        .cornerRadius(12)
        .shadow(radius: 4)
        .accessibilityIdentifier("scanErrorMessage")
    }

    // MARK: - Private Methods

    private func startScanning() async {
        // 권한 확인
        let hasPermission = await scannerService.requestCameraPermission()
        guard hasPermission else {
            errorMessage = "Camera permission is required"
            return
        }

        isScanning = true
        errorMessage = nil

        // 스캔 시작
        for await qrData in await scannerService.startScanning() {
            onScanComplete(qrData)
            await scannerService.stopScanning()
            isScanning = false
            return
        }
    }
}

// MARK: - CameraPreviewView

/// 카메라 프리뷰를 위한 UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 카메라 프리뷰 레이어는 QRScannerService의 AVCaptureSession이 관리
        // 실제 구현에서는 AVCaptureVideoPreviewLayer를 여기에 추가해야 함
    }
}

// MARK: - Preview

#Preview {
    QRScannerView(
        onScanComplete: { _ in },
        onDismiss: {}
    )
}
#endif
