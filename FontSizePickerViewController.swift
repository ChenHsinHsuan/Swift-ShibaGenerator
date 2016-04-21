//
//  FontSizePickerViewController.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/4/21.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit

class FontSizePickerViewController: UIViewController {

    var delegate: ViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    @IBAction func fontSizeChange(sender: UISlider) {
        delegate?.setFontSize(CGFloat(sender.value))
    }

    
}
