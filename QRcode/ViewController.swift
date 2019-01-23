//
//  ViewController.swift
//  QRcode
//
//  Created by 55it on 2019/1/23.
//  Copyright © 2019年 55it. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController ,UIImagePickerControllerDelegate,UINavigationControllerDelegate,AVCaptureMetadataOutputObjectsDelegate {

    var scanRectView:UIView!
    var device:AVCaptureDevice!
    var input:AVCaptureDeviceInput!
    var output:AVCaptureMetadataOutput!
    var session:AVCaptureSession!
    var preview:AVCaptureVideoPreviewLayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let names : Array = ["相册","相机"]
        
        for item in 0 ... names.count-1 {
            let buttton = UIButton.init(frame: CGRect(x: 80, y: item * 70, width: 60, height: 50))
            buttton.tag = 100 + item
            buttton .setTitle(names[item], for: .normal)
            buttton.backgroundColor = #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
            buttton.addTarget(self, action: #selector(doclick(btn:)), for: .touchUpInside)
            self.view .addSubview(buttton)
            
        }
    
        
        
    }
    @objc func doclick(btn : UIButton)  {
        
        switch btn.titleLabel?.text {
        case "相册":
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
        
            self.present(picker, animated: true, completion: nil)
            
            break
            
        default:
     
            do{
                self.device = AVCaptureDevice.default(for: AVMediaType.video)
                
                self.input = try AVCaptureDeviceInput(device: device)
                
                self.output = AVCaptureMetadataOutput()
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                self.session = AVCaptureSession()
                if UIScreen.main.bounds.size.height<500 {
                    self.session.sessionPreset = AVCaptureSession.Preset.vga640x480
                }else{
                    self.session.sessionPreset = AVCaptureSession.Preset.high
                }
                
                self.session.addInput(self.input)
                self.session.addOutput(self.output)
                
                self.output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                
                //计算中间可探测区域
                let windowSize = UIScreen.main.bounds.size
                let scanSize = CGSize(width:windowSize.width*3/4, height:windowSize.width*3/4)
                var scanRect = CGRect(x:(windowSize.width-scanSize.width)/2,
                                      y:(windowSize.height-scanSize.height)/2,
                                      width:scanSize.width, height:scanSize.height)
                //计算rectOfInterest 注意x,y交换位置
                scanRect = CGRect(x:scanRect.origin.y/windowSize.height,
                                  y:scanRect.origin.x/windowSize.width,
                                  width:scanRect.size.height/windowSize.height,
                                  height:scanRect.size.width/windowSize.width);
                //设置可探测区域
                self.output.rectOfInterest = scanRect
                
                self.preview = AVCaptureVideoPreviewLayer(session:self.session)
                self.preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
                self.preview.frame = UIScreen.main.bounds
                self.view.layer.insertSublayer(self.preview, at:0)
                
                //添加中间的探测区域绿框
                self.scanRectView = UIView();
                self.view.addSubview(self.scanRectView)
                self.scanRectView.frame = CGRect(x:0, y:0, width:scanSize.width,
                                                 height:scanSize.height);
                self.scanRectView.center = CGPoint( x:UIScreen.main.bounds.midX,
                                                    y:UIScreen.main.bounds.midY)
                self.scanRectView.layer.borderColor = UIColor.green.cgColor
                self.scanRectView.layer.borderWidth = 1;
                
                //开始捕获
                self.session.startRunning()
            }catch _ {
                //打印错误消息
                let alertController = UIAlertController(title: "提醒",
                                                        message: "请在iPhone的\"设置-隐私-相机\"选项中,允许本程序访问您的相机",
                                                        preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "确定", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
            break
            
        }
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
     
//        let codeImg = UIImage(named: "code")
        let ciImage : CIImage = CIImage(image: image)!
        
        let context = CIContext(options: nil)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        
        let features = detector?.features(in: ciImage)
        print("扫描二维码个数：\(features?.count ?? 0)")
        self.dismiss(animated: true) {
            for feature in features as![CIQRCodeFeature] {
                let alert = UIAlertController.init(title: "识别目标", message:feature.messageString, preferredStyle:.alert)
                let action = UIAlertAction.init(title: "确定", style: .default) { (UIAlertAction) in
                
                }
                alert.addAction(action)
                self .present(alert, animated: true, completion: nil)
                
            }
        }
       
        
//
    }
    //摄像头捕获
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        var stringValue:String?
        if metadataObjects.count > 0 {
            let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            stringValue = metadataObject.stringValue
            
            if stringValue != nil{
                self.session.stopRunning()
            }
        }
        self.session.stopRunning()
        //输出结果
        let alertController = UIAlertController(title: "二维码",
                                                message: stringValue,preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default, handler: {
            action in
            //继续扫描
            self.session.startRunning()
        })
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}


