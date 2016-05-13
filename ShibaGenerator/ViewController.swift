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
import ImgurAnonymousAPIClient
import Social
import SVProgressHUD
import SystemConfiguration
import MobileCoreServices
import AVFoundation
import Spring

class ViewController: UIViewController, UITextFieldDelegate, UIActionSheetDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var componentView: UIView!
    @IBOutlet weak var shibaImageView: UIImageView!
    @IBOutlet weak var demoLabel: UILabel!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var demoTextWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTextField: UITextField!
    
    
    
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var exportImage:UIImage?
    let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    
    

    enum ToolMode {
        case KEYIN          //keyin mode
        case DRAWING        //drawing mode
    }

    var toolMode = ToolMode.KEYIN
    var imgurClient:ImgurAnonymousAPIClient? = nil
    
    
    @IBOutlet weak var inputToolbar: UIToolbar!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var drawingToolView: SpringView!

    
    
    var textAlignVertical = true
    var photoIndex = 1
    var newPhotoCounter = 0
    var updatePhotoCounter = 0
    
    var tempInputString = ""

    var imagePicker:UIImagePickerController?;
    
    //for Drawing
    @IBOutlet var pancels: [UIButton]!
    let colors: [(CGFloat, CGFloat, CGFloat)] = [
        (0, 0, 0),
        (105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0),
        (1.0, 0, 0),
        (0, 0, 1.0),
        (51.0 / 255.0, 204.0 / 255.0, 1.0),
        (102.0 / 255.0, 204.0 / 255.0, 0),
        (102.0 / 255.0, 1.0, 0),
        (160.0 / 255.0, 82.0 / 255.0, 45.0 / 255.0),
        (1.0, 102.0 / 255.0, 0),
        (1.0, 1.0, 0),
        (1.0, 1.0, 1.0),
        ]
    var lastPoint = CGPoint.zero
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var swiped = false
    var selectedPancel:UIButton?
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    
    @IBOutlet weak var demoBrushImageView: UIImageView!
    @IBOutlet weak var brushSizeSlider: UISlider!
    @IBOutlet weak var brushOpacitySlider: UISlider!
    
    
//    var drawMode = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
        
        self.appDelegate.delegate = self
        
        //Observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.keyboardWasShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.keyboardWillBeHidden), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.textFieldTextDidChangeOneCI(_:)), name: UITextFieldTextDidChangeNotification, object: inputTextField)
        
        
        //guesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        
        
        // ask photo permission
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
        })
        
        // ask camera permission
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
        })
        
        if Reachability.isConnectedToNetwork() {
            if let client = Dropbox.authorizedClient {
                appDelegate.syncPhoto(client)
                appDelegate.syncNews(client)
            }else{
                UIAlertView(title: "網路連線異常", message: "請確認網路連線狀況...", delegate: nil, cancelButtonTitle: "我知道了").show()
            }
        }else{
            UIAlertView(title: "網路連線異常", message: "請確認網路連線狀況...", delegate: nil, cancelButtonTitle: "我知道了").show()
        }
        
    }


    func dismissKeyboard(){
        self.inputTextField.resignFirstResponder()
        self.inputTextView.resignFirstResponder()
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if(segue.identifier == "ExportSegue"){
//            let resultVC = segue.destinationViewController as! ResultViewController
//            resultVC.exportImage = self.exportImage!
//        }
    }
    
    
    
    //MARK: - Keyboard
    func keyboardWasShown(aNotification:NSNotification) {
        let info = aNotification.userInfo
        
        let kbSize = info![UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size
        
        let contentInsets:UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize!.height, 0.0)
        
        scrollView.contentInset = contentInsets
        
        scrollView.scrollIndicatorInsets = contentInsets
    
        var aRect = self.view.frame
        aRect.size.height -= kbSize!.height
        
        if (!CGRectContainsPoint(aRect, inputTextView.frame.origin)){
            scrollView.scrollRectToVisible(inputTextView.frame, animated: true)
        }
        
    }
    
    func keyboardWillBeHidden() {
        let contentInsects:UIEdgeInsets = UIEdgeInsetsZero
        scrollView.contentInset = contentInsects
        scrollView.scrollIndicatorInsets = contentInsects
    }
    
    
    //MARK: - My Delegate
    func setShibaImage(replaceImage:UIImage){
        shibaImageView.image = replaceImage
    }
    
    
    func setButtonColor (color: UIColor) {
        if textAlignVertical{
            demoLabel.textColor = color
        }else{
            inputTextView.textColor = color
        }
    }
    
    
    
    func showExportOption(){
        
        genImage()
        
        
        let alertController = UIAlertController(title: "請選擇您想匯出的方式", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        let sponseAction = UIAlertAction(title: "再看一次廣告贊助作者", style: UIAlertActionStyle.Destructive) { _ in
            if (self.appDelegate.myInterstitial!.isReady){
                self.appDelegate.myInterstitial!.presentFromRootViewController(self)
            }else{
                let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
                let alertView = UIAlertController(title: "APP偵測到你的網路異常", message: "謝謝你這麼有心～等網路正常再幫我點吧～謝謝", preferredStyle: UIAlertControllerStyle.Alert)
                alertView.addAction(okAciton)
                self.presentViewController(alertView, animated: true, completion: nil)
            }
            
        }

        
        
        let shareToLineAction = UIAlertAction(title: "分享到LINE", style: UIAlertActionStyle.Default) { _ in
            
            
            var pasteBoard = UIPasteboard(name: "jp.naver.linecamera.pasteboard", create: true)!
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                pasteBoard = UIPasteboard.generalPasteboard()
            }
            
            pasteBoard.setData(UIImageJPEGRepresentation(self.exportImage!, 1.0)!, forPasteboardType: "public.jpeg")
            
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
                self.imgurClient?.uploadImage(self.exportImage, withFilename: "\(self.appDelegate.printTimestamp()).jpg", completionHandler: { (url, erorr) in
                    
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
            self.exportImage = nil
        }
        
        alertController.addAction(sponseAction)
        alertController.addAction(shareToLineAction)
        alertController.addAction(shareToFBAction);
        alertController.addAction(imgurAction)
        alertController.addAction(exportPictureAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion:nil)

    }
    
    
    //MARK: - IBAction
    
    @IBAction func fontSizeChange(sender: UISlider) {
        
        if textAlignVertical {
            self.demoLabel.font = UIFont(name: self.demoLabel.font!.fontName, size: CGFloat(sender.value))
            self.demoTextWidthLayoutConstraint.constant = CGFloat(sender.value)
            self.demoLabel.layoutIfNeeded()
        }else{
            self.inputTextView.font = UIFont(name: self.inputTextView.font!.fontName, size: CGFloat(sender.value))
        }
    }

    
    @IBAction func modeChange(sender: UIButton) {
        if toolMode == ToolMode.KEYIN {
            toolMode = ToolMode.DRAWING
            
            
            for thePancel in pancels {
                thePancel.frame.origin.y = drawingToolView.frame.height * 0.8
                if thePancel.tag == 0 {
                    selectedPancel = thePancel
                    thePancel.frame.origin.y = drawingToolView.frame.height * 0.6
                }
            }
            drawPreview()
            
            drawingToolView.hidden = false
            inputToolbar.hidden = true
            scrollView.userInteractionEnabled = false
            sender.setTitle("打字", forState: UIControlState.Normal)
        }else{
            toolMode = ToolMode.KEYIN
            sender.setTitle("畫畫", forState: UIControlState.Normal)
            drawingToolView.hidden = true
            inputToolbar.hidden = false
            scrollView.userInteractionEnabled = true
        }
    }
    
    
    @IBAction func changePhotoButtonPressed(sender: UIButton) {
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("photoPickerPopover") as! PhotoPickerViewController
        popoverVC.modalPresentationStyle = .Popover
        popoverVC.preferredContentSize = CGSizeMake(UIScreen.mainScreen().bounds.width - 20 , UIScreen.mainScreen().bounds.height - 100)
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
            popoverVC.delegate = self
        }
        presentViewController(popoverVC, animated: true, completion: nil)
    }
    
    
    
    
    
    @IBAction func exportButtonPressed(sender: UIButton) {
        inputTextView.backgroundColor = UIColor.clearColor()
        self.appDelegate.myInterstitial!.presentFromRootViewController(self)
    }
    
    
    
    @IBAction func showNewsButtonPressed(sender: UIButton) {
        appDelegate.showNews()
    }
    
    
    @IBAction func customPhotoButtonPressed(sender: UIButton) {
        
        let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if(authStatus == AVAuthorizationStatus.Authorized) {
            // do your logic
            let actionController = UIAlertController(title: "請選擇自訂圖檔來源", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            let cameraAction = UIAlertAction(title: "立馬拍一張", style: UIAlertActionStyle.Default){ _ in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                    self.imagePicker = UIImagePickerController()
                    self.imagePicker!.delegate = self
                    self.imagePicker!.mediaTypes = [kUTTypeImage as String]
                    self.imagePicker!.sourceType = UIImagePickerControllerSourceType.Camera
                    self.imagePicker!.allowsEditing = true
                    
                    self.presentViewController(self.imagePicker!, animated: true, completion: nil)
                }
            }
            
            
            let galleryAction = UIAlertAction(title: "從我的相機膠卷挑一張", style: UIAlertActionStyle.Default){ _ in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
                    self.imagePicker = UIImagePickerController()
                    self.imagePicker!.delegate = self
                    self.imagePicker!.mediaTypes = [kUTTypeImage as String]
                    self.imagePicker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                    self.imagePicker!.allowsEditing = true
                    
                    self.presentViewController(self.imagePicker!, animated: true, completion: nil)
                }
            }
            
            let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Destructive, handler: nil)
            
            actionController.addAction(cameraAction)
            actionController.addAction(galleryAction)
            actionController.addAction(cancelAction)
            presentViewController(actionController, animated: true, completion: {})

        }else{
            UIAlertView(title: "請打開隱私權設定", message:"設定>PTT回文圖產生器 \r\n將照片與相機功能開啟" , delegate: nil, cancelButtonTitle: "我知道了").show()
            
        }
    }

    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
        shibaImageView.image = image
    }
    

    
    
    @IBAction func changeAlign(sender: UIButton) {
        let actionController = UIAlertController(title: "請選擇", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let verticalModeAction = UIAlertAction(title: "直式", style: UIAlertActionStyle.Default){ _ in
            if (self.inputTextView.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count > 0 && self.inputTextView.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "你想說什麼"){
                self.inputTextField.text = self.inputTextView.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                self.demoLabel.text = self.inputTextField.text
            }
            
            self.demoTextWidthLayoutConstraint.constant = CGFloat(self.demoLabel.font.pointSize)
            self.demoLabel.layoutIfNeeded()
            self.inputTextView.hidden = true
            self.demoLabel.hidden = false
            self.inputTextField.hidden = false
            self.textAlignVertical = true
        }
        
        
        let horizontalModeAction = UIAlertAction(title: "橫式", style: UIAlertActionStyle.Default){ _ in
            if (self.inputTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count > 0 ){
                self.inputTextView.text = self.inputTextField.text!
                self.inputTextView.textColor = UIColor.whiteColor()
            }else{
                self.inputTextView.textColor = UIColor.lightGrayColor()
                self.inputTextView.text = "你想說什麼"
            }
            
            let screenWidth = UIScreen.mainScreen().bounds.size.width
            self.demoTextWidthLayoutConstraint.constant = screenWidth - 40 - 39
            self.inputTextView.hidden = false
            self.demoLabel.hidden = true
            self.inputTextField.hidden = true
            self.textAlignVertical = false

        }
        
        actionController.addAction(verticalModeAction)
        actionController.addAction(horizontalModeAction)
        presentViewController(actionController, animated: true, completion: {})
        
    }
    
    
    @IBAction func colorPickerButtonPressed(sender: UIButton) {
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("colorPickerPopover") as! ColorPickerViewController
        popoverVC.modalPresentationStyle = .Popover
        popoverVC.preferredContentSize = CGSizeMake(284, 446)
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
            popoverVC.delegate = self
        }
        presentViewController(popoverVC, animated: true, completion: nil)
    }

    
   
    // Override the iPhone behavior that presents a popover as fullscreen
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .None
    }
    
    

    //MARK: - TextField Delegate
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
    
    
    
    //MARK: - TextView Delegate
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (textView.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "你想說什麼"){
            textView.text = ""
            textView.textColor = UIColor.whiteColor()
        }
        textView.backgroundColor = UIColor(red: 128, green: 128, blue: 128, alpha: 0.5)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count == 0  {
            textView.text = "你想說什麼"
            textView.textColor = UIColor.lightGrayColor()
        }
        
        textView.backgroundColor = UIColor.clearColor()
    }

 
    

 
    
    // MARK: 產生圖片
    func genImage() {
//        let image = self.shibaImageView
//        UIGraphicsBeginImageContextWithOptions(image.frame.size, true, 0.0)
//        image.layer.renderInContext(UIGraphicsGetCurrentContext()!)
//        CGContextTranslateCTM(UIGraphicsGetCurrentContext()!, 40, 0)
//        self.demoLabel.layer.renderInContext(UIGraphicsGetCurrentContext()!)
//        self.exportImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsBeginImageContextWithOptions(componentView.frame.size, true, 0.0)
        componentView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        self.exportImage = UIGraphicsGetImageFromCurrentImageContext()        
        UIGraphicsEndImageContext()
    }
    
    
    
    
   //MARK: - Drawing code
   
    
    @IBAction func colorPenPressed(sender: UIButton) {
        
        for thePancel in pancels {
            thePancel.frame.origin.y = drawingToolView.frame.height * 0.8
            selectedPancel = nil
        }
        
        sender.frame.origin.y = drawingToolView.frame.height * 0.6
        selectedPancel = sender
        
        var index = sender.tag ?? 0
        if index < 0 || index >= colors.count {
            index = 0
        }
        
        (red, green, blue) = colors[index]
        
        if index == colors.count - 1 {
            opacity = 1.0
        }
        
        drawPreview()
    }
    
    
    func drawPreview() {
        UIGraphicsBeginImageContext(demoBrushImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, CGFloat(brushSizeSlider.value))
        
        CGContextSetRGBStrokeColor(context, red, green, blue, CGFloat(brushOpacitySlider.value))
        CGContextMoveToPoint(context, demoBrushImageView.frame.width/2, demoBrushImageView.frame.height/2)
        CGContextAddLineToPoint(context, demoBrushImageView.frame.width/2, demoBrushImageView.frame.height/2)
        CGContextStrokePath(context)
        demoBrushImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    
    
    @IBAction func brushValueChange(sender: UISlider) {
        if sender.tag == 0 {
            //大小
            brushWidth = CGFloat(sender.value)
        }else if sender.tag == 1 {
            //透明度
            opacity = CGFloat(sender.value)
        }
        drawPreview()
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = false
        print("touchesBegan")
        if let touch = touches.first{
            lastPoint = touch.locationInView(self.shibaImageView)
        }
        
        if !swiped {
            drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        
    }
    
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        // 1
        
        UIGraphicsBeginImageContext(shibaImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: shibaImageView.frame.size.width, height: shibaImageView.frame.size.height))
        
        
        

        // 2
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brushWidth)
        
//        CGContextSetShouldAntialias(context, true)
        if selectedPancel?.tag == 10 {
            CGContextSetBlendMode(context, CGBlendMode.Clear)
            CGContextSetRGBStrokeColor(context, red, green, blue, 1.0)
        }else{
            CGContextSetBlendMode(context, CGBlendMode.Normal)
            CGContextSetRGBStrokeColor(context, red, green, blue, opacity)
        }
        
        CGContextBeginPath(context)
        // 3
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
    

        // 4
        CGContextStrokePath(context)
        
        // 5
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//        tempImageView.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // 6
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self.shibaImageView)
            drawLineFrom(lastPoint, toPoint: currentPoint)
            
            // 7  
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !swiped {
            drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        
        // Merge tempImageView into mainImageView
//        UIGraphicsBeginImageContext(shibaImageView.frame.size)
//        mainImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: mainImageView.frame.size.width, height: mainImageView.frame.size.height), blendMode: CGBlendMode.Normal, alpha: 1.0)
//        tempImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: tempImageView.frame.size.width, height: tempImageView.frame.size.height), blendMode: CGBlendMode.Normal, alpha: opacity)
//        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        tempImageView.image = nil
    }
    

   
}

