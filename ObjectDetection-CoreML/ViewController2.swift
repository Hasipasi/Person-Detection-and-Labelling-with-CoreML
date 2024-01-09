//
//  ViewController2.swift
//  ObjectDetection-CoreML
//
//  Created by Bódis Balázs on 06/12/2023.
//  Copyright © 2023 tucan9389. All rights reserved.
//

import UIKit

class ViewController2: UIViewController, UIDocumentPickerDelegate {
    var label_values = [false, false, false, false]
    var globalImageCounter: Int {
        get {
            return UserDefaults.standard.integer(forKey: "globalImageCounter")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "globalImageCounter")
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var ImgInspector: UIImageView!
    @IBOutlet weak var prevOut: UIButton!
    @IBOutlet weak var nextOut: UIButton!
    
    @IBOutlet weak var SW1_out: UISwitch!
    @IBOutlet weak var SW2_out: UISwitch!
    @IBOutlet weak var SW3_out: UISwitch!
    @IBOutlet weak var SW4_out: UISwitch!
    
    @IBAction func Label1_switch(_ sender: UISwitch) {
        label_values[0] = sender.isOn
    }
    @IBAction func Label2_switch(_ sender: UISwitch) {
        label_values[1] = sender.isOn
    }
    @IBAction func Label3_switch(_ sender: UISwitch) {
        label_values[2] = sender.isOn
    }
    @IBAction func Label4_switch(_ sender: UISwitch) {
        label_values[3] = sender.isOn
    }
    
    
    var images: [UIImage] = []
    var currentImageIndex = 0
    
    func update_buttons(){
        SW1_out.isOn = false
        SW2_out.isOn = false
        SW3_out.isOn = false
        SW4_out.isOn = false
        label_values = [false, false, false, false]
        
        SW1_out.onTintColor = UIColor.blue
        SW1_out.tintColor = UIColor.red
        SW2_out.onTintColor = UIColor.blue
        SW2_out.tintColor = UIColor.red
        SW3_out.onTintColor = UIColor.blue
        SW3_out.tintColor = UIColor.red
        SW4_out.onTintColor = UIColor.blue
        SW4_out.tintColor = UIColor.red
        
        prevOut.isEnabled = currentImageIndex != 0
        nextOut.isEnabled = currentImageIndex != images.count - 1
    }
     
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black
        
        update_buttons()
        
        // Enable user interaction on the image view
        ImgInspector.isUserInteractionEnabled = true
        
        // Add pinch gesture recognizer for zooming
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        ImgInspector.addGestureRecognizer(pinchGesture)
        
        // Add pan gesture recognizer for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.minimumNumberOfTouches = 1
        ImgInspector.addGestureRecognizer(panGesture)
        
        // Display the first image when the view loads
        if !images.isEmpty {
            ImgInspector.image = images[currentImageIndex]
        }
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            let translation = gesture.translation(in: view.superview)
            view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            gesture.setTranslation(.zero, in: view.superview)
        }
    }
    
    @IBAction func prev(_ sender: Any) {
        if currentImageIndex > 0 {
            currentImageIndex -= 1
        }
        
        // Reset the image position and zoom level
        ImgInspector.transform = CGAffineTransform.identity
        ImgInspector.center = view.center
        
        // Display the next image
        ImgInspector.image = images[currentImageIndex]
        
        update_buttons()
    }

    @IBAction func next(_ sender: Any) {
        if currentImageIndex < images.count - 1 {
            currentImageIndex += 1
        }
        
        // Reset the image position and zoom level
        ImgInspector.transform = CGAffineTransform.identity
        ImgInspector.center = view.center
        
        // Display the next image
        ImgInspector.image = images[currentImageIndex]
        
        update_buttons()
    }
    
    func getFileName() -> String{
        globalImageCounter += 1
        var name = "image_\(globalImageCounter)_label_"
        for l in label_values{
            if l {
                name = name + "1"
            }
            else{
                name = name + "0"
            }
        }
        return name + ".png"
    }
    
    @IBAction func save(_ sender: Any) {
        // Check if there are images to save
        if !images.isEmpty {
            // Get the current image
            let image = images[currentImageIndex]
            
            // Convert the image to data
            if let data = image.pngData() {
                // Create the file name
                
                // Create a temporary file in the app's container directory
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(getFileName())
                
                // Save the image data to the temporary file
                try? data.write(to: tempFileURL)
                
                // Create a document picker for directories (folders)
                let documentPicker = UIDocumentPickerViewController(url: tempFileURL, in: .exportToService)
                documentPicker.delegate = self
                
                // Present the document picker
                present(documentPicker, animated: true, completion: nil)
            }
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // The user picked a document, so you can now perform the operations

        // Remove the current image from the array only if save is successful
        images.remove(at: currentImageIndex)
        
        // If there are still images left, display the new current image
        if !images.isEmpty {
            // If the current image index is now out of bounds, decrement it
            if currentImageIndex >= images.count {
                currentImageIndex = max(0, images.count - 1)
            }
            ImgInspector.image = images[currentImageIndex]
        } else {
            // If there are no images left, return to the previous view
            self.dismiss(animated: true, completion: nil)
        }
        
        // Update button states
        update_buttons()
    }
    
    @IBAction func deleteB(_ sender: Any) {
        // Remove the current image from the array
        images.remove(at: currentImageIndex)
        
        // If the current image index is now out of bounds, decrement it
        if currentImageIndex >= images.count {
            currentImageIndex = max(0, images.count - 1)
        }
        
        // If there are still images left, display the new current image
        if !images.isEmpty {
            ImgInspector.image = images[currentImageIndex]
        } else {
            // If there are no images left, return to the previous view
            self.dismiss(animated: true, completion: nil)
        }
        
        // Update button states
        update_buttons()
    }

}
