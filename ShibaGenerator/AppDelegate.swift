                                                                                                                                                                                  //
//  AppDelegate.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/3/13.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Fabric
import Crashlytics
import SwiftyDropbox


let DROPBOX_APPKEY = "3g6nerdg76nwxjr"
let DROPBOX_APPSECRET = "iqbd4czinylo773"
let DROPBOX_TOKEN = "CWJze7MYa9AAAAAAAAABrYxZBslgi7DkyChT9Oyv1ZAemjcAxySRo0it6zs-im1G"


//let DROPBOX_APPKEY = "dxzz5hggavsa7qp"
//let DROPBOX_APPSECRET = "pist4gysdf7nrl6"
//let DROPBOX_TOKEN = "CWJze7MYa9AAAAAAAAAA6D431R694nTLGQD0oMBXNb_K8yA1k-akMOgHdoRqPS2f"
let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
var localPhotoFilesPath:NSURL!
var localNewsFilePath:NSURL!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GADInterstitialDelegate {

    var window: UIWindow?

    var myInterstitial : GADInterstitial?

    var delegate:ViewController?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        application.statusBarHidden = true
        
        myInterstitial = createAndLoadInterstitial()
        
        
        Fabric.with([Crashlytics.self])

        
        
        DropboxAuthManager.sharedAuthManager = DropboxAuthManager(appKey: DROPBOX_APPKEY)
        Dropbox.authorizedClient = DropboxClient(accessToken: DropboxAccessToken(accessToken: DROPBOX_TOKEN, uid: "aircon.chen.apple@gmail.com"))
        DropboxClient.sharedClient = Dropbox.authorizedClient
        
        
        
        
        localPhotoFilesPath = directoryURL.URLByAppendingPathComponent("files")
        localNewsFilePath = directoryURL.URLByAppendingPathComponent("news")
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(localPhotoFilesPath.path!, withIntermediateDirectories: true, attributes: nil)
            try NSFileManager.defaultManager().createDirectoryAtPath(localNewsFilePath.path!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        myInterstitial = createAndLoadInterstitial()
        delegate?.showExportOption()
    }
    
    func createAndLoadInterstitial()->GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-5200673733349176/4904876445")
        interstitial.delegate = self
        interstitial.loadRequest(GADRequest())
        return interstitial
    }

    func printTimestamp() -> String {
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        print(timestamp)
        return timestamp
    }

    
    func showNews(){
        let filePath = localNewsFilePath.URLByAppendingPathComponent("news.txt").path!
        let isFileExist = NSFileManager.defaultManager().fileExistsAtPath(filePath)
        
        if isFileExist {
            do {
                let newsContent = try NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
                let newsAlertView = UIAlertView(title: "最新消息", message: "\(newsContent)", delegate: nil, cancelButtonTitle: "我知道了")
                
                newsAlertView.show()
            }
            catch {
                print("read news files error: \(error)...")
            }
        }else{
            //檔案不存在
            print("news file is not exist....")
        }
    }
    
    
    //MARK: - sync job
    
    // MARK: - Dropbox
    func syncNews(client:DropboxClient){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            do{
                
                let filePath = localNewsFilePath.URLByAppendingPathComponent("news.txt").path!
                let isFileExist = NSFileManager.defaultManager().fileExistsAtPath(filePath)
                
                if isFileExist {
                    
                    let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
                    let fileSize = fileAttributes[NSFileSize]
                    
                    //檢查跟線上一樣的檔案 大小是否一樣
                    client.files.getMetadata(path: "/news.txt").response{response, error in
                        if let metadata = response {
                            if metadata.description.rangeOfString("\(fileSize!)") != nil {
                                print("have the same news file...do nothing")
                                
                            }else{
                                print("news file is different...")
                                //delete local file
                                do {
                                    print("delete file:\(filePath)...")
                                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                                }
                                catch let error as NSError {
                                    print("delete local file wrong: \(error)...")
                                }
                                //download from dropbox
                                self.downloadNewsFromDropbox(client)
                            }
                        }else{
                            print("check metadata from dropbox error:\(error)")
                        }
                    }
                    
                }else{
                    
                    //檔案不存在
                    self.downloadNewsFromDropbox(client)
                }
                
            }
            catch let error as NSError {
                print("search local files error: \(error)...")
            }
            
        }
    }
    
    
    func syncPhoto(client:DropboxClient){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            // do some task
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate!.changePhotoButton.hidden = true
            }
            //從遠端檢查本機
            client.files.listFolder(path: "/pics").response { response, error in
                if let result = response {
                    if (result.entries.count > 0) {
                        
                        for entry in result.entries {
                            
                            let filePath = localPhotoFilesPath.URLByAppendingPathComponent(entry.name).path!
                            let isFileExist = NSFileManager.defaultManager().fileExistsAtPath(filePath)
                            
                            do {
                                //1.判斷本機有沒有這個檔案
                                if isFileExist {
                                    
                                    let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
                                    let fileSize = fileAttributes[NSFileSize]
                                    
                                    print("file name:\(self.getFileName(entry.name)) ext:\(self.getFileExt(entry.name))  size:\(fileSize!)")
                                    
                                    //檢查跟線上一樣的檔案 大小是否一樣
                                    client.files.getMetadata(path: "/pics/\(entry.name)").response{response, error in
                                        
                                        if let metadata = response {
                                            if metadata.description.rangeOfString("\(fileSize!)") != nil {
                                                print("have the same file...do nothing")
                                                
                                                
                                            }else{
                                                print("file is different...")
                                                //delete local file
                                                do {
                                                    print("delete file:\(filePath)...")
                                                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                                                }
                                                catch let error as NSError {
                                                    print("delete local file wrong: \(error)...")
                                                }
                                                //download from dropbox
                                                self.downloadPhotoFromDropbox(client, entry: entry)
                                            }
                                        }else{
                                            print("check metadata from dropbox error:\(error)")
                                        }
                                    }
                                    
                                }else{
                                    //2.沒有就下載
                                    self.downloadPhotoFromDropbox(client, entry: entry)
                                }
                            }
                            catch let error as NSError {
                                print("error:\(error.description)")
                            }
                        }
                    }
                } else {
                    print("listFolder error:\(error!)")
                }
                
                self.checkLocalPhoto(client)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate!.changePhotoButton.hidden = false
                }
            }
            
        }
    }
    
    
    func checkLocalPhoto(client:DropboxClient){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            
            //從本機檢查遠端
            do{
                let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath((localPhotoFilesPath as NSURL).path!)
                
                
                for theFileName in files {
                    print("check file:\(theFileName)")
                    
                    client.files.getMetadata(path: "/pics/\(theFileName)").response{response, error in
                        
                        if let metadata = response {
                            print("online have the file:\(metadata.name)...")
                        }else{
                            print("online remove the file:\(theFileName)...")
                            
                            do {
                                print("delete file:\(theFileName)...")
                                try NSFileManager.defaultManager().removeItemAtPath(localPhotoFilesPath.URLByAppendingPathComponent(theFileName).path!)
                            }
                            catch let error as NSError {
                                print("delete local file wrong: \(error)...")
                            }
                            
                        }
                    }
                }
            }
            catch let error as NSError {
                print("search local files error: \(error)...")
                
            }
        }
        
    }
    
    
    
    func downloadPhotoFromDropbox(client:DropboxClient, entry:Files.Metadata){
        
        let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
            return localPhotoFilesPath.URLByAppendingPathComponent(entry.name)
        }
        
        client.files.download(path: "/pics/\(entry.name)", destination: destination).response { response, error in
            if let (metadata, _) = response {
                print("Downloaded photo file name: \(metadata.name)")
                
            } else {
                print(error!)
            }
        }
        
    }
    
    
    func downloadNewsFromDropbox(client:DropboxClient){
        
        let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
            return localNewsFilePath.URLByAppendingPathComponent("news.txt")
        }
        client.files.download(path: "/news.txt", destination: destination).response { response, error in
            
            if let (_, _) = response {
                self.showNews()
            } else {
                print("download news fail:\(error!)")
            }
        }
        
    }
    
    
    
    //MARK - FileName 處理
    func getFileName(fullFileName:String) -> String {
        return fullFileName.substringToIndex(fullFileName.rangeOfString(".", options: .BackwardsSearch)!.startIndex)
    }
    
    func getFileExt(fullFileName:String) -> String {
        return fullFileName.substringFromIndex(fullFileName.rangeOfString(".", options: .BackwardsSearch)!.startIndex.successor())
    }
    
    
}

