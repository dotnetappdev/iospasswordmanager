import SwiftUI
import AVFoundation
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    let onScanResult: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onScanResult = onScanResult
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // No updates needed
    }
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onScanResult: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Add overlay with instructions
        setupOverlay()
        
        captureSession.startRunning()
    }
    
    private func setupOverlay() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.clear
        
        // Add a semi-transparent overlay with a clear rectangle in the center
        let overlayLayer = CALayer()
        overlayLayer.frame = overlayView.bounds
        overlayLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        
        let clearRect = CGRect(
            x: view.bounds.midX - 150,
            y: view.bounds.midY - 150,
            width: 300,
            height: 300
        )
        
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: overlayView.bounds)
        path.append(UIBezierPath(rect: clearRect).reversing())
        maskLayer.path = path.cgPath
        overlayLayer.mask = maskLayer
        
        overlayView.layer.addSublayer(overlayLayer)
        
        // Add border around the clear rectangle
        let borderLayer = CAShapeLayer()
        borderLayer.frame = overlayView.bounds
        borderLayer.path = UIBezierPath(rect: clearRect).cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 2
        overlayView.layer.addSublayer(borderLayer)
        
        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Scan QR Code from Desktop App"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        overlayView.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        // Add cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cancelButton.layer.cornerRadius = 10
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        overlayView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        view.addSubview(overlayView)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    func failed() {
        let alertController = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            onScanResult?(stringValue)
            dismiss(animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}