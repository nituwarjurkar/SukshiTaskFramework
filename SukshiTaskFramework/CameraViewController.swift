//
//  CameraViewController.swift
//  SukshiTaskFramework
//
//  Created by Nitu Warjurkar on 15/06/20.
//  Copyright © 2020 Nitu Warjurkar. All rights reserved.
//

import UIKit
import AVFoundation

public protocol GetFrameDelegate {
    func getTwoFrames(frame1: UIImage, frame2: UIImage)
}

open class CameraViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    
    open var delegate : GetFrameDelegate?
    
    var session: AVCaptureSession?
    private var generator:AVAssetImageGenerator!
    var frames:[UIImage]!
    var capturedFrame1 : UIImage?
    var capturedFrame2 : UIImage?
  
    override open func viewDidLoad() {
        super.viewDidLoad()
        createSession()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func didClickPhoto(_ sender: Any) {
        session?.stopRunning()
    }
    func createSession() {
        
        var input: AVCaptureDeviceInput?
        let  movieFileOutput = AVCaptureMovieFileOutput()
        
        var prevLayer: AVCaptureVideoPreviewLayer?
        prevLayer?.frame.size = previewView.frame.size
        session = AVCaptureSession()
        let error: NSError? = nil
        do { input = try AVCaptureDeviceInput(device: self.cameraWithPosition(position: .front)!) } catch {return}
        if error == nil {
            session?.addInput(input!)
        } else {
            print("camera input error: \(error)")
        }
        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        prevLayer?.frame.size = previewView.frame.size
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        prevLayer?.connection!.videoOrientation = .portrait
        previewView.layer.addSublayer(prevLayer!)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let filemainurl = NSURL(string: "\(documentsURL)temp.mov")
        
        //let  filemainurl = NSURL(string: ("\(documentsURL.URLByAppendingPathComponent("temp"))" + ".mov"))
        
        
        let maxDuration: CMTime = CMTimeMake(value: 600, timescale: 10)
        movieFileOutput.maxRecordedDuration = maxDuration
        movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024
        if self.session!.canAddOutput(movieFileOutput) {
            self.session!.addOutput(movieFileOutput)
        }
        session?.startRunning()
        movieFileOutput.startRecording(to: filemainurl! as URL, recordingDelegate: self)
        
        
    }
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            if device.position == position {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }
    open func UploadFramesToServer(parameters : [String:Any], urlString: String) {
        
        self.showHUD(message: "Uploading")
        let request = createRequest(param: parameters, strURL: urlString)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {
            (
            data, response, error) in
            guard let _:NSData = data as NSData?, let _:URLResponse = response, error == nil else {
                print("error")
                return
            }
        
            self.hideHUD()
            
        }
        task.resume()
    }
    
    func createBodyWithParameters(parameters: [String : Any],boundary: String) -> NSData {
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters {
                
                if(value is String || value is NSString) {
                    
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                    body.appendString("\(value)\r\n")
                }
                else if(value is UIImage){
                    var i = 0;
                    // for image in value as! [UIImage]{
                    let filename = "image\(i).jpg"
                    let data = (value as! UIImage).jpegData(compressionQuality: 1);
                    let mimetype = "png"
                    
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
                    body.appendString("Content-Type: \(mimetype)\r\n\r\n")
                    body.append(data!)
                    body.appendString("\r\n")
                    i = 1+1;
                    //}
                }
            }
        }
        body.appendString("--\(boundary)--\r\n")
        //        NSLog("data %@",NSString(data: body, encoding: NSUTF8StringEncoding)!);
        return body
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func createRequest (param : [String : Any] , strURL : String) -> NSURLRequest {
        
        let boundary = generateBoundaryString()
        
        let url = NSURL(string: strURL)
        let request = NSMutableURLRequest(url: url! as URL)
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = createBodyWithParameters(parameters: param , boundary: boundary) as Data
        
        return request
    }
    
}
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
       
        if error == nil {
            getAllFrames(videoUrl: outputFileURL)
        }
    }
    
    func getAllFrames(videoUrl : URL) {
        let asset:AVAsset = AVAsset(url:videoUrl)
        let duration:Float64 = CMTimeGetSeconds(asset.duration)
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        self.frames = []
        for index:Int in 0 ..< Int(duration) {
            self.getFrame(fromTime:Float64(index))
        }
        capturedFrame1 = self.frames.last
        if self.frames.count >= 2 {
             capturedFrame2 = self.frames[self.frames.count-2]
        } else {
            capturedFrame2 = self.frames.last
        }
       
        self.generator = nil
       
        self.delegate?.getTwoFrames(frame1: capturedFrame1!, frame2: capturedFrame2!)
        self.navigationController?.popViewController(animated: true)
    }
    private func getFrame(fromTime:Float64) {
        let time:CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale:600)
        let image:CGImage
        do {
            try image = self.generator.copyCGImage(at:time, actualTime:nil)
        } catch {
            return
        }
        self.frames.append(UIImage(cgImage:image))
    }
}

