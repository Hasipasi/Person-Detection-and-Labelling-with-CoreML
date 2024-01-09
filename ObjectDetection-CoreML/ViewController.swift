//
//  ViewController.swift
//  SSDMobileNet-CoreML
//
//  Created by GwakDoyoung on 01/02/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import UIKit
import Vision
import CoreMedia
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var currentPixelBuffer: CVPixelBuffer?
    var croppedImages: [UIImage] = []
    var imagePicker = UIImagePickerController()
    var front_bool = false
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var boxesView: DrawingBoundingBoxView!
    
    @IBOutlet weak var Toggle_Flash_outlet: UIButton!

    
    

    @IBAction func Toggle_flash(_ sender: Any) {
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("Flashlight is not available")
            return
        }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.isTorchActive {
                    device.torchMode = .off
                    Toggle_Flash_outlet.backgroundColor = .clear // Set background color to clear when not active
                } else {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                    Toggle_Flash_outlet.backgroundColor = .yellow // Set background color to yellow when active
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Failed to toggle flashlight: \(error.localizedDescription)")
            }
        } else {
            print("Flashlight is not available")
        }
    }

    
    
    
    @IBAction func Capture2(_ sender: UIButton) {
        guard let pixelBuffer = self.currentPixelBuffer else {
            print("Pixel buffer not available")
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        let originalImage = UIImage(cgImage: cgImage)
        ProcessImg(originalImage: originalImage)
        
    }
    
    @IBAction func LoadImage2(_ sender: UIButton) {
        print("I am a button")
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage else {
                fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
            }
            let correctedImage = self.correctImageOrientation(image)
            let pixelBuffer = self.toPixelBuffer(image: correctedImage)
            self.predictUsingVision(pixelBuffer: pixelBuffer!)
            self.ProcessImg(originalImage: correctedImage)
        }
    }

    func correctImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    func toPixelBuffer(image: UIImage) -> CVPixelBuffer? {
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, imageWidth, imageHeight, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        
        if status != kCVReturnSuccess {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: imageWidth, height: imageHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: CGFloat(imageHeight))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    public func ProcessImg(originalImage: UIImage){
        print(type(of: originalImage))
        croppedImages = []
        // for each detected object
        for observation in self.predictions {
            print("Detected", observation.label)
            // check if the label is "person"
            if observation.label == "person" {
                // get the bounding box
                let boundingBox = observation.boundingBox

                // convert the bounding box to pixel coordinates
                let x = boundingBox.origin.x * originalImage.size.width
                let y = (1 - boundingBox.origin.y - boundingBox.height) * originalImage.size.height
                let width = boundingBox.width * originalImage.size.width
                let height = boundingBox.height * originalImage.size.height
                let rect = CGRect(x: x, y: y, width: width, height: height)

                // crop the image and save it
                if let croppedImage = cropImage(originalImage, toRect: rect) {
                    
                    //UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
                    croppedImages.append(croppedImage) //add to array
                }
            }
        }
        if !croppedImages.isEmpty {
            print("Segue!!!!!!!")
            guard let device = AVCaptureDevice.default(for: .video) else {
                    print("Flashlight is not available")
                    return
                }
                
                if device.hasTorch {
                    do {
                        try device.lockForConfiguration()
                        
                        if device.isTorchActive {
                            device.torchMode = .off
                            Toggle_Flash_outlet.backgroundColor = .clear // Set background color to clear when not active
                        } 
                        device.unlockForConfiguration()
                    } catch {
                        print("Failed to toggle flashlight: \(error.localizedDescription)")
                    }
                } else {
                    print("Flashlight is not available")
                }
            performSegue(withIdentifier: "showView2", sender: self)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showView2" {
            return !croppedImages.isEmpty
        }
        return true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showView2",
        let viewController2 = segue.destination as? ViewController2 {
            viewController2.images = croppedImages

        }
    }
    
    func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK - Core ML model
    // YOLOv3(iOS12+), YOLOv3FP16(iOS12+), YOLOv3Int8LUT(iOS12+)
    // YOLOv3Tiny(iOS12+), YOLOv3TinyFP16(iOS12+), YOLOv3TinyInt8LUT(iOS12+)
    // MobileNetV2_SSDLite(iOS12+), ObjectDetector(iOS12+)
    // yolov5n(iOS13+), yolov5s(iOS13+), yolov5m(iOS13+), yolov5l(iOS13+), yolov5x(iOS13+)
    // yolov5n6(iOS13+), yolov5s6(iOS13+), yolov5m6(iOS13+), yolov5l6(iOS13+), yolov5x6(iOS13+)
    // yolov8n(iOS14+), yolov8s(iOS14+), yolov8m(iOS14+), yolov8l(iOS14+), yolov8x(iOS14+)
    lazy var objectDectectionModel = { return try? yolov5s() }()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var isInferencing = false
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!
    let semaphore = DispatchSemaphore(value: 1)
    var lastExecution = Date()
    
    // MARK: - TableView Data
    var predictions: [VNRecognizedObjectObservation] = []
    
    // MARK - Performance Measurement Property
    private let measure = Measure()
    
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black
        
        // setup the model
        setUpModel()
        
        // setup camera
        setUpCamera(postion: .back)
        
        // setup delegate for performance measurement
        measure.delegate = self
    }
    
    @IBAction func Flip(_ sender: Any) {
        self.videoCapture.stop()
        self.videoCapture.switchToFrontCamera()
        if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()}
        self.videoCapture.start()
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        guard let objectDectectionModel = objectDectectionModel else { fatalError("fail to load the model") }
        if let visionModel = try? VNCoreMLModel(for: objectDectectionModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("fail to create vision model")
        }
    }

    // MARK: - SetUp Video
    func setUpCamera(postion: AVCaptureDevice.Position) {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480, position: postion) { success in
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // start video preview when setup is done
                self.videoCapture.start()
            }
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

// MARK: - VideoCaptureDelegate
extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if !self.isInferencing, let pixelBuffer = pixelBuffer {
            self.currentPixelBuffer = pixelBuffer
            self.isInferencing = true
            
            // start of measure
            self.measure.start_measure()
            
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

extension ViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        // vision framework configures the input size of image following our model's input configuration automatically
        self.semaphore.wait()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
        

    // MARK: - Post-processing

    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.measure.label_measure(with: "endInference")
        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            // filter predictions to only include "person"
            let personPredictions = predictions.filter { prediction in
                prediction.labels.contains { $0.identifier == "person" }
            }

            self.predictions = personPredictions
            DispatchQueue.main.async {
                self.boxesView.predictedObjects = personPredictions

                // end of measure
                self.measure.stop_measure()
                
                self.isInferencing = false
            }
        } else {
            // end of measure
            self.measure.stop_measure()
            
            self.isInferencing = false
        }
        self.semaphore.signal()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell") else {
            return UITableViewCell()
        }

        let rectString = predictions[indexPath.row].boundingBox.toString(digit: 2)
        let confidence = predictions[indexPath.row].labels.first?.confidence ?? -1
        let confidenceString = String(format: "%.3f", confidence/*Math.sigmoid(confidence)*/)
        
        cell.textLabel?.text = predictions[indexPath.row].label ?? "N/A"
        cell.detailTextLabel?.text = "\(rectString), \(confidenceString)"
        return cell
    }
}

// MARK: - Measure(Performance Measurement) Delegate
extension ViewController: MeasureDelegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        //print(executionTime, fps)
        DispatchQueue.main.async {
            self.maf1.append(element: Int(inferenceTime*1000.0))
            self.maf2.append(element: Int(executionTime*1000.0))
            self.maf3.append(element: fps)

        }
    }
}



class MovingAverageFilter {
    private var arr: [Int] = []
    private let maxCount = 10
    
    public func append(element: Int) {
        arr.append(element)
        if arr.count > maxCount {
            arr.removeFirst()
        }
    }
    
    public var averageValue: Int {
        guard !arr.isEmpty else { return 0 }
        let sum = arr.reduce(0) { $0 + $1 }
        return Int(Double(sum) / Double(arr.count))
    }
}


