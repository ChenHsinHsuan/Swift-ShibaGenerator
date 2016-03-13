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

class ResultViewController: UIViewController{

    @IBOutlet weak var resultImageView: UIImageView!
    
    var exportImage:UIImage!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
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

        
        let status = PHPhotoLibrary.authorizationStatus()
        
        let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
        
        if status == PHAuthorizationStatus.Authorized{
            //Save it to the camera roll
            UIImageWriteToSavedPhotosAlbum(resultImageView.image!, nil, nil, nil)
            
            let alertView = UIAlertController(title: "匯出成功", message:  "柴犬圖已經存至您的相機膠卷中囉!", preferredStyle: UIAlertControllerStyle.Alert)
            alertView.addAction(okAciton)
            self.presentViewController(alertView, animated: true, completion: nil)
        }else{
            let alertView = UIAlertController(title: "匯出失敗", message:  "請至設定>隱私權>照片>將柴犬產生器的權限打開唷!!", preferredStyle: UIAlertControllerStyle.Alert)
            alertView.addAction(okAciton)
            self.presentViewController(alertView, animated: true, completion: nil)
        }
        

    }
}
