//
//  ViewController.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/3/13.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit
import Photos
class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var demoLabel: UILabel!
    
    @IBOutlet weak var inputTextField: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var fontsizeSlider: UISlider!
    
    @IBOutlet weak var shibaImageView: UIImageView!
    
    var exportImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillBeHidden", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textFieldTextDidChangeOneCI:", name: UITextFieldTextDidChangeNotification, object: inputTextField)
        
        
        //MARK: guesture
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        self.view.addGestureRecognizer(tap)
        
        
        // ask photo permission
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
            switch status{
            case .Authorized:
                dispatch_async(dispatch_get_main_queue(), {
                    print("Authorized")
                })
                break
            case .Denied:
                dispatch_async(dispatch_get_main_queue(), {
                    print("Denied")
                })
                break
            default:
                dispatch_async(dispatch_get_main_queue(), {
                    print("Default")
                })
                break
            }
        })
        
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
    }
    
    
    @IBAction func convertPhoto(sender: AnyObject) {
        
        if(self.inputTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count == 0){
            let alertView = UIAlertController(title: "柴犬不知道你要說什麼", message:  "請於下方輸入格輸入文字!!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAciton = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Default, handler: nil)
            alertView.addAction(okAciton)
            self.presentViewController(alertView, animated: true, completion: nil)
            
            self.demoLabel.text = "在下面輸入文字"
            self.inputTextField.text = self.inputTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            return
        }
        
        
        UIGraphicsBeginImageContextWithOptions(self.shibaImageView.frame.size, true, 0.0)
        self.shibaImageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        
        
        CGContextTranslateCTM(UIGraphicsGetCurrentContext()!, 40, 0)
        self.demoLabel.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        self.exportImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        
        performSegueWithIdentifier("ExportSegue", sender: self)

    }
    
    
    

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if(segue.identifier == "ExportSegue"){
            let resultVC = segue.destinationViewController as! ResultViewController
            resultVC.exportImage = self.exportImage!
        }
    }

}

