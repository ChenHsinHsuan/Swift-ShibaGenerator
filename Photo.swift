//
//  Photo.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/5/3.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit

class Photo: NSObject {
    let filePath:String!
    let fileName:String!
    
    init(iFilePath:String, iFileName:String) {
        filePath = iFilePath
        fileName = iFileName
    }
    
}
