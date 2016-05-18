//
//  PhotoPickerViewController.swift
//  ShibaGenerator
//
//  Created by ChenHsin-Hsuan on 2016/5/3.
//  Copyright © 2016年 AirconTW. All rights reserved.
//

import UIKit

private let reuseIdentifier = "PhotoCell"

class PhotoPickerViewController: UICollectionViewController {

    var delegate: ViewController? = nil
    var localPhotoFiles:[Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        do{
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath((localPhotoFilesPath as NSURL).path!)
            for theFileName in files {
               self.localPhotoFiles.append(Photo(iFilePath: localPhotoFilesPath.URLByAppendingPathComponent(theFileName).path!, iFileName: theFileName.substringToIndex(theFileName.rangeOfString(".")!.startIndex)))
            }
        }catch{
            print("load image files fail...")
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return localPhotoFiles.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> PhotoCollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        let thePhoto = localPhotoFiles[indexPath.row]
        
        cell.nameLabel.text = thePhoto.fileName
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            var image = UIImage(contentsOfFile: thePhoto.filePath)
            UIGraphicsBeginImageContextWithOptions(image!.size, true, 0)
            image!.drawAtPoint(CGPointZero)
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            dispatch_async(dispatch_get_main_queue()) {
                cell.imageView.image = image
            }
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    

    
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return true
    }
 
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.setShibaImage(UIImage(contentsOfFile: localPhotoFiles[indexPath.row].filePath)!)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
 

}
