//
//  ViewController.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/3/13.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit
import Photos
import SwiftyDropbox
import MBProgressHUD

class ViewController: UIViewController, UITextFieldDelegate, UIActionSheetDelegate, DBRestClientDelegate {

    @IBOutlet weak var demoLabel: UILabel!
    
    @IBOutlet weak var inputTextField: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var fontsizeSlider: UISlider!
    
    @IBOutlet weak var shibaImageView: UIImageView!

    @IBOutlet weak var demoTextWidthLayoutConstraint: NSLayoutConstraint!

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var exportImage:UIImage?
    
    var localPhotoFiles:[String] = []

    let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    
    var localPhotoFilesPath:NSURL!
    var localNewsFilePath:NSURL!
    
    
    var photoIndex = 1
    var newPhotoCounter = 0
    var updatePhotoCounter = 0
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.keyboardWasShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.keyboardWillBeHidden), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.textFieldTextDidChangeOneCI(_:)), name: UITextFieldTextDidChangeNotification, object: inputTextField)
        
        
        //MARK: guesture
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
        
        
        // ask photo permission
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in

        })
        
        
        
        prepareVariabal()
        scanLocalPhotoFiles()
        
        
        
        
        if let client = Dropbox.authorizedClient {
            syncPhoto(client)
            syncNews(client)
        }else{
            print("網路連線異常!!!")
            self.title = "網路連線異常..."
        }
  
    }

    
    func prepareVariabal(){
        self.localPhotoFilesPath = self.directoryURL.URLByAppendingPathComponent("files")
        self.localNewsFilePath = self.directoryURL.URLByAppendingPathComponent("news")
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(self.localPhotoFilesPath.path!, withIntermediateDirectories: true, attributes: nil)
            try NSFileManager.defaultManager().createDirectoryAtPath(self.localNewsFilePath.path!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func dismissKeyboard(){
        self.inputTextField.resignFirstResponder()
    }
    
    
    //MARK: Keyboard
    func keyboardWasShown(aNotification:NSNotification) {
        let info = aNotification.userInfo
        
        let kbSize = info![UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size
        
        let contentInsets:UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize!.height, 0.0)
        
        scrollView.contentInset = contentInsets
        
        scrollView.scrollIndicatorInsets = contentInsets
        
        
        var aRect = self.view.frame
        aRect.size.height -= kbSize!.height
        
        if (!CGRectContainsPoint(aRect, inputTextField.frame.origin)){
            scrollView.scrollRectToVisible(inputTextField.frame, animated: true)
        }
        
        
        
    }
    
    func keyboardWillBeHidden() {
        let contentInsects:UIEdgeInsets = UIEdgeInsetsZero
        scrollView.contentInset = contentInsects
        scrollView.scrollIndicatorInsets = contentInsects
    }


    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func textFieldTextDidChangeOneCI(notification:NSNotification){
        let textField = notification.object! as! UITextField
        self.demoLabel.numberOfLines = 0;
        self.demoLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping
        self.demoLabel.text = textField.text
    }
    
    
    @IBAction func fontSizeChange(sender: UISlider) {
        self.demoLabel.font = UIFont(name: self.demoLabel.font!.fontName, size: CGFloat(sender.value))
        
        self.demoTextWidthLayoutConstraint.constant = CGFloat(sender.value)
        
        self.demoLabel.layoutIfNeeded()
        
    }
    

    @IBAction func convertPhoto(sender: AnyObject) {
        

        let actionController = UIAlertController(title: "請選擇", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let exportAction = UIAlertAction(title: "輸出圖檔", style: UIAlertActionStyle.Destructive) { _ in
            
            if(self.inputTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count == 0){
                let alertView = UIAlertController(title: "我不知道你要說什麼", message:  "請於下方輸入格輸入文字!!", preferredStyle: UIAlertControllerStyle.Alert)
                let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
                alertView.addAction(okAciton)
                self.presentViewController(alertView, animated: true, completion: nil)
                
                self.demoLabel.text = "在下面輸入文字"
                self.inputTextField.text = self.inputTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                return
            }

        }
        
        let syncAction = UIAlertAction(title: "手動與伺服器同步圖檔", style: UIAlertActionStyle.Default) { _ in
            if let client = Dropbox.authorizedClient {
                self.syncPhoto(client)
            }else{
                print("網路連線異常!!!")
                self.title = "網路連線異常..."
            }
        }
        
        
        let newsAction = UIAlertAction(title: "最新消息", style: UIAlertActionStyle.Default) { _ in
            
                
            let filePath = self.localNewsFilePath.URLByAppendingPathComponent("news.txt").path!
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
        
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Default, handler: nil)
        
        actionController.addAction(newsAction)
        actionController.addAction(syncAction)
        actionController.addAction(exportAction)
        actionController.addAction(cancelAction)
   
        presentViewController(actionController, animated: true, completion:nil)
    }
    
    
    @IBAction func changeImage(sender: AnyObject) {
        scanLocalPhotoFiles()
        if localPhotoFiles.count > 0 {
            
            if photoIndex == localPhotoFiles.count {
                photoIndex = 0
            }
            

            let readPath = self.localPhotoFilesPath.URLByAppendingPathComponent(localPhotoFiles[photoIndex])
            let image    = UIImage(contentsOfFile: readPath.path!)
            self.shibaImageView.image = image
            photoIndex += 1
        
        }else{
            print("just only have a photo....")
        }
        
    }
    
    
    

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if(segue.identifier == "ExportSegue"){
            let resultVC = segue.destinationViewController as! ResultViewController
            resultVC.exportImage = self.exportImage!
        }
    }
    
    
    // MARK: 產生圖片
    func genImage() {
        let image = self.shibaImageView
        UIGraphicsBeginImageContextWithOptions(image.frame.size, true, 0.0)
        image.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        CGContextTranslateCTM(UIGraphicsGetCurrentContext()!, 40, 0)
        self.demoLabel.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        self.exportImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    func syncNews(client:DropboxClient){
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            do{
                
                let filePath = self.localNewsFilePath.URLByAppendingPathComponent("news.txt").path!
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
   
        
        newPhotoCounter = 0
        updatePhotoCounter = 0
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
        
            //從遠端檢查本機
            client.files.listFolder(path: "/pics").response { response, error in
                if let result = response {
                    if (result.entries.count > 0) {
                        
                        for entry in result.entries {
                            
                            let filePath = self.localPhotoFilesPath.URLByAppendingPathComponent(entry.name).path!
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
                                                self.updatePhotoCounter += 1
                                            }
                                        }else{
                                            print("check metadata from dropbox error:\(error)")
                                        }
                                    }

                                }else{
                                    //2.沒有就下載
                                    self.downloadPhotoFromDropbox(client, entry: entry)
                                    self.newPhotoCounter += 1
                                }
                            
                               self.scanLocalPhotoFiles()
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
            }

            
            dispatch_async(dispatch_get_main_queue()) {
                self.title = "背景同步圖檔中..."
            }
        }
    }
    
    
    func checkLocalPhoto(client:DropboxClient){
         dispatch_async(dispatch_get_global_queue(priority, 0)) {
            //從本機檢查遠端
            do{
                let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath((self.localPhotoFilesPath as NSURL).path!)
                
                
                for theFileName in files {
                    print("check file:\(theFileName)")
                    
                    client.files.getMetadata(path: "/pics/\(theFileName)").response{response, error in
                        
                        if let metadata = response {
                            print("online have the file:\(metadata.name)...")
                        }else{
                            print("online remove the file:\(theFileName)...")
                            
                            do {
                                print("delete file:\(theFileName)...")
                                try NSFileManager.defaultManager().removeItemAtPath(self.directoryURL.URLByAppendingPathComponent(theFileName).path!)
                            }
                            catch let error as NSError {
                                print("delete local file wrong: \(error)...")
                            }

                        }
                    }
                }
                
                self.scanLocalPhotoFiles()
                
            }
            catch let error as NSError {
                print("search local files error: \(error)...")
                
            }
            
            
            if self.newPhotoCounter > 0 && self.updatePhotoCounter  > 0 {
                self.title = "新增:\(self.newPhotoCounter),更新:\(self.updatePhotoCounter)"
            }else if self.newPhotoCounter > 0 {
                self.title = "新增\(self.newPhotoCounter)張圖"
            }else if self.updatePhotoCounter  > 0 {
                self.title = "更新\(self.updatePhotoCounter)張圖"
            }else{
                self.title = "圖檔掃描完畢..."
            }

        }
    
    }
    
    //#MARK - FileName 處理
    func getFileName(fullFileName:String) -> String {
        return fullFileName.substringToIndex(fullFileName.rangeOfString(".", options: .BackwardsSearch)!.startIndex)
    }
    
    func getFileExt(fullFileName:String) -> String {
        return fullFileName.substringFromIndex(fullFileName.rangeOfString(".", options: .BackwardsSearch)!.startIndex.successor())
    }
    

    
    func downloadPhotoFromDropbox(client:DropboxClient, entry:Files.Metadata){
        
        let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
            return self.localPhotoFilesPath.URLByAppendingPathComponent(entry.name)
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
            return self.localNewsFilePath.URLByAppendingPathComponent("news.txt")
        }
        client.files.download(path: "/news.txt", destination: destination).response { response, error in

            if let (metadata, _) = response {
                print("Downloaded news file name: \(metadata.name) success!!!")
            } else {
                print("download news fail:\(error!)")
            }
        }
        
    }
    
    
    // 掃描圖檔資料夾
    func scanLocalPhotoFiles(){
        do{
            localPhotoFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.localPhotoFilesPath.path!)
        }catch{
            print("scan file error:\(error)")
        }
    }

}