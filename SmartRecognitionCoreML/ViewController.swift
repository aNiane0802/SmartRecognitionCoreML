//
//  ViewController.swift
//  SmartRecognitionCoreML
//
//  Created by Aboubakrine Niane on 26/06/2018.
//  Copyright © 2018 Aboubakrine Niane. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {

    // First step : Create a captureSession
    let captureSession = AVCaptureSession.init()
    
    let objectLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.text = "Bests Guess"
        label.textAlignment = .center
        label.textColor = UIColor.black
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVideo()
        configureBestGuess()
    }
    
    func configureVideo(){
        // Second Step : Add an input to your AVCAptureSession typically camera front or back , audio etc...
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard let captureInput = try? AVCaptureDeviceInput.init(device: captureDevice) else { return }
        captureSession.addInput(captureInput)
        captureSession.startRunning()
        
        //Third Step : Add a preview layer that will act as the output of what your camera sees
        let previewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        // Fourth step : Get the image captured by the camera so you can analyze it with CoreML Model
        let dataOutput = AVCaptureVideoDataOutput.init()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.init(label: "video"))
        captureSession.addOutput(dataOutput)
    }
    
    func configureBestGuess(){
        
        view.addSubview(objectLabel)
        NSLayoutConstraint.activate([
            objectLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            objectLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            objectLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            objectLabel.heightAnchor.constraint(equalToConstant: 44)
            ])
    }
    
}


extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    //    An instance of AVCaptureVideoDataOutput produces video frames you can process using other media APIs. You can access the frames with the captureOutput(_:didOutput:from:) delegate method.
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        guard let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let modelCoreML = try? VNCoreMLModel.init(for: SqueezeNet().model) else { return }
        let request = VNCoreMLRequest.init(model: modelCoreML) { (request, error) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            
            guard let observations = request.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = observations.first else { return }
            
            DispatchQueue.main.async {
                self.objectLabel.text = "\(firstObservation.identifier)  \(Int(firstObservation.confidence*100))%"
            }
            
        }
        
        do{
            try VNImageRequestHandler.init(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }catch let error {
            print(error.localizedDescription)
            return
        }
        
        
    }
    
}

