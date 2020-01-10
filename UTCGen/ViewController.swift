//
//  AppDelegate.swift
//  QACodeDemo
//
//  Created by apple on 29/08/19.
//  Copyright © 2019 appinventiv. All rights reserved.
//

import UIKit
import EventKit
import CoreImage

import MapKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var qrFld: UITextField!
    @IBOutlet var txtFld: UITextView!
    @IBOutlet var stopBtn: UIButton!
    @IBOutlet var generateBtn: UIButton!
    
    
    var qrStr:String=""
    var timer = Timer()
    var lat:String!=""
    var lon:String!=""
    var latLon:String!=""
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        stopBtn.isHidden=true
        stopBtn.layer.cornerRadius = 10
        stopBtn.clipsToBounds = true
        generateBtn.layer.cornerRadius = 10
        generateBtn.clipsToBounds = true
        
        getUTC()
        drawQR()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
     // print("locations = \(locValue.latitude) \(locValue.longitude)")
       lat=String(locValue.latitude)
       lon=String(locValue.longitude)
        latLon=lat+"/"+lon
        
   }
    
    @IBAction func generatePressed(_ sender: Any) {
        generateBtn.isHidden=true
        stopBtn.isHidden=false
         calc()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(calc), userInfo: nil, repeats: true)
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        generateBtn.isHidden=false
        stopBtn.isHidden=true
        
        timer.invalidate()
    }
    
    @objc func calc(){
          getUTC()
          drawQR()
      }
    
     func getUTC(){
        let secondsFormatter = DateFormatter()
        // initially set the format based on your datepicker date / server String
        secondsFormatter.dateFormat = "SS"
        secondsFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let currTimestamp = Date()
        let hundredths = Int(secondsFormatter.string(from: currTimestamp))
        
        if (hundredths! % 10 == 0) {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            }
            
            let formatter = DateFormatter()
            // initially set the format based on your datepicker date / server String
            formatter.dateFormat = "yyyy-MM-dd/HH:mm:ss.SS"
            formatter.timeZone = TimeZone(identifier: "UTC")
            
            let timeFormatter = DateFormatter()
            // initially set the format based on your datepicker date / server String
            timeFormatter.dateFormat = "HH:mm:ss.SS"
            timeFormatter.timeZone = TimeZone(identifier: "UTC")

            let formattedTimestamp = formatter.string(from: currTimestamp)
            let formattedTime = timeFormatter.string(from: currTimestamp)
            print(formattedTime+" Z")
            
            qrStr = formattedTimestamp+"/"+latLon
            txtFld.text=formattedTime+" Z"
        }
    }
    
    func drawQR(){
                       
        guard let qrURLImage = URL(string: qrStr)?.qrImage(using: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), logo: #imageLiteral(resourceName: "logo")) else { return }
       
       imageView.image = qrURLImage
    }
    
    
}

extension URL {
    
    /// Creates a QR code for the current URL in the given color.
    func qrImage(using color: UIColor, logo: UIImage? = nil) -> UIImage? {
        
        guard let tintedQRImage = qrImage?.tinted(using: color) else {
            return nil
        }
        
       /* guard let logo = logo?.cgImage else {
            return UIImage(ciImage: tintedQRImage)
        }
        
        guard let final = tintedQRImage.combined(with: CIImage(cgImage: logo)) else {
            return UIImage(ciImage: tintedQRImage)
        }
        */
        return UIImage(ciImage: tintedQRImage)
    }
    
    /// Returns a black and white QR code for this URL.
    var qrImage: CIImage? {
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let qrData = absoluteString.data(using: String.Encoding.ascii)
        qrFilter.setValue(qrData, forKey: "inputMessage")
        
        let qrTransform = CGAffineTransform(scaleX: 12, y: 12)
        return qrFilter.outputImage?.transformed(by: qrTransform)
    }
}

extension CIImage {
    /// Inverts the colors and creates a transparent image by converting the mask to alpha.
    /// Input image should be black and white.
    var transparent: CIImage? {
        return inverted?.blackTransparent
    }
    
    /// Inverts the colors.
    var inverted: CIImage? {
        guard let invertedColorFilter = CIFilter(name: "CIColorInvert") else { return nil }
        
        invertedColorFilter.setValue(self, forKey: "inputImage")
        return invertedColorFilter.outputImage
    }
    
    /// Converts all black to transparent.
    var blackTransparent: CIImage? {
        guard let blackTransparentFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
        blackTransparentFilter.setValue(self, forKey: "inputImage")
        return blackTransparentFilter.outputImage
    }
    
    /// Applies the given color as a tint color.
    func tinted(using color: UIColor) -> CIImage? {
        guard
            let transparentQRImage = transparent,
            let filter = CIFilter(name: "CIMultiplyCompositing"),
            let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return nil }
        
        let ciColor = CIColor(color: color)
        colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
        let colorImage = colorFilter.outputImage
        
        filter.setValue(colorImage, forKey: kCIInputImageKey)
        filter.setValue(transparentQRImage, forKey: kCIInputBackgroundImageKey)
        
        return filter.outputImage!
    }
}

extension CIImage {
    
    /// Combines the current image with the given image centered.
    func combined(with image: CIImage) -> CIImage? {
        guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        let centerTransform = CGAffineTransform(translationX: extent.midX - (image.extent.size.width / 2), y: extent.midY - (image.extent.size.height / 2))
        combinedFilter.setValue(image.transformed(by: centerTransform), forKey: "inputImage")
        combinedFilter.setValue(self, forKey: "inputBackgroundImage")
        return combinedFilter.outputImage!
    }
}
