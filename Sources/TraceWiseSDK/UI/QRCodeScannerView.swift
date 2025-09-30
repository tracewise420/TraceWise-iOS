import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

@available(iOS 14.0, *)
public struct QRCodeScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    
    public init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
    }
    
    public func makeUIViewController(context: Context) -> QRScannerViewController {
        return QRScannerViewController(onScan: onScan)
    }
    
    public func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

@available(iOS 14.0, *)
public class QRScannerViewController: UIViewController {
    private let onScan: (String) -> Void
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    public init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
}

@available(iOS 14.0, *)
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            captureSession.stopRunning()
            onScan(stringValue)
        }
    }
}

#else

// macOS placeholder - QR scanning not available
public struct QRCodeScannerView: View {
    let onScan: (String) -> Void
    
    public init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
    }
    
    public var body: some View {
        Text("QR Scanner not available on macOS")
            .foregroundColor(.secondary)
    }
}

#endif