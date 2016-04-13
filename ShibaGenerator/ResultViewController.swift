//
//  ResultViewController.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/3/13.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit
import Photos
import GoogleMobileAds
import ImgurAnonymousAPIClient
import Social
import SVProgressHUD
import SystemConfiguration


class ResultViewController: UIViewController{

    @IBOutlet weak var resultImageView: UIImageView!
    
    
    var exportImage:UIImage!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var imgurClient:ImgurAnonymousAPIClient? = nil
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resultImageView.image = self.exportImage
        
    }
    
    override func viewDidAppear(animated: Bool) {
        appDelegate.myInterstitial?.presentFromRootViewController(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func saveButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController(title: "請選擇您想匯出的方式", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        let sponseAction = UIAlertAction(title: "再看一次廣告贊助作者", style: UIAlertActionStyle.Destructive) { _ in
            if (self.appDelegate.myInterstitial!.isReady){
                self.showAdmob()
            }else{
                let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
                let alertView = UIAlertController(title: "APP偵測到你的網路異常", message: "謝謝你這麼有心～等網路正常再幫我點吧～謝謝", preferredStyle: UIAlertControllerStyle.Alert)
                alertView.addAction(okAciton)
                self.presentViewController(alertView, animated: true, completion: nil)
            }
            
        }
        
//        let shareToOtherAction = UIAlertAction(title: "不儲存分享到其他APP", style: UIAlertActionStyle.Default) { _ in
//  
//            
//        }
        
        
        let shareToLineAction = UIAlertAction(title: "分享到LINE", style: UIAlertActionStyle.Default) { _ in

            
            var pasteBoard = UIPasteboard(name: "jp.naver.linecamera.pasteboard", create: true)!
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                pasteBoard = UIPasteboard.generalPasteboard()
            }
            
            pasteBoard.setData(UIImageJPEGRepresentation(self.exportImage, 1.0)!, forPasteboardType: "public.jpeg")
            
            let lineAppURL:NSURL = NSURL(string: "line://msg/image/\(pasteBoard.name)")!
            
            if( UIApplication.sharedApplication().canOpenURL(lineAppURL)){
                UIApplication.sharedApplication().openURL(lineAppURL)
            }
            
        }
        
        
        let shareToFBAction = UIAlertAction(title: "分享到Facebook", style: UIAlertActionStyle.Default) { _ in
            
            let fbSheet = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            fbSheet.addImage(self.exportImage!)
            self.presentViewController(fbSheet, animated: true, completion: nil)
        }
        
        
        
        let exportPictureAction = UIAlertAction(title: "儲存到相片膠卷", style: UIAlertActionStyle.Default) { _ in
        
            let status = PHPhotoLibrary.authorizationStatus()
            
            let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
            
            if status == PHAuthorizationStatus.Authorized{
                //Save it to the camera roll
                UIImageWriteToSavedPhotosAlbum(self.exportImage!, nil, nil, nil)
                
                let alertView = UIAlertController(title: "匯出成功", message:  "圖已經存至您的相機膠卷中囉!", preferredStyle: UIAlertControllerStyle.Alert)
                alertView.addAction(okAciton)
                self.presentViewController(alertView, animated: true, completion: nil)
            }else{
                let alertView = UIAlertController(title: "匯出失敗", message:  "請至設定>隱私權>照片>將柴犬產生器的權限打開唷!!", preferredStyle: UIAlertControllerStyle.Alert)
                alertView.addAction(okAciton)
                self.presentViewController(alertView, animated: true, completion: nil)
            }
        }
        
        
        let imgurAction = UIAlertAction(title: "上傳imgur拿短網址", style: UIAlertActionStyle.Default) { _ in
            

            SVProgressHUD.showWithStatus("上傳中,請稍候...")
            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
            
            self.imgurClient = ImgurAnonymousAPIClient(clientID: "1720b099a01eafe")

            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0),{
                self.imgurClient?.uploadImage(self.exportImage, withFilename: "\(self.printTimestamp()).jpg", completionHandler: { (url, erorr) in
                    
                    if(url == nil){
                        let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
                        let alertView = UIAlertController(title: "APP偵測到你的網路異常，所以沒辦法幫你上傳", message: "請確認連線狀況!", preferredStyle: UIAlertControllerStyle.Alert)
                        alertView.addAction(okAciton)
                        self.presentViewController(alertView, animated: true, completion: nil)
                    }else{
                        let alertView = UIAlertController(title: "上傳完畢，網址如下", message: "\(url)", preferredStyle: UIAlertControllerStyle.ActionSheet)
                        let copyAction = UIAlertAction(title: "幫我複製URL讓我直接可以貼上", style: UIAlertActionStyle.Default, handler: { _ in
                            UIPasteboard.generalPasteboard().string = "\(url)"
                        })
                        alertView.addAction(copyAction)
                        self.presentViewController(alertView, animated: true, completion: nil)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {

                        SVProgressHUD.dismiss()
                    })
                })
            })
            
        
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel) { _ in
            
        }
        
        alertController.addAction(sponseAction)
//        alertController.addAction(shareToOtherAction)
        alertController.addAction(shareToLineAction)
        alertController.addAction(shareToFBAction);
        alertController.addAction(imgurAction)
        alertController.addAction(exportPictureAction)
        alertController.addAction(cancelAction)

        
        
        
        presentViewController(alertController, animated: true, completion:nil)
        

    }
    
    
    func printTimestamp() -> String {
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        print(timestamp)
        return timestamp
    }
    
    
    // MARK: show AD
    
    func showAdmob(){
        self.appDelegate.myInterstitial!.presentFromRootViewController(self)
    }
    


}
