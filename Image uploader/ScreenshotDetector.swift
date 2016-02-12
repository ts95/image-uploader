//
//  ScreenshotDetector.swift
//  Image uploader
//
//  Created by Toni Sučić on 17.11.2015.
//  Copyright © 2015 Toni Sučić. All rights reserved.
//

import Foundation

typealias NewFileCallback = (fileURL: NSURL) -> Void

class ScreenshotDetector: NSObject, NSMetadataQueryDelegate {

    let query = NSMetadataQuery()

    var newFileCallback: NewFileCallback?

    override init() {
        super.init()

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: Selector("queryUpdated:"), name: NSMetadataQueryDidStartGatheringNotification, object: query)
        center.addObserver(self, selector: Selector("queryUpdated:"), name: NSMetadataQueryDidUpdateNotification, object: query)
        center.addObserver(self, selector: Selector("queryUpdated:"), name: NSMetadataQueryDidFinishGatheringNotification, object: query)

        query.delegate = self
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")
        query.startQuery()
    }

    deinit {
        query.stopQuery()
    }

    func queryUpdated(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            for v in userInfo.values {
                let items = v as! [NSMetadataItem]
                if items.count > 0 {
                    let item = items[0]
                    if let filename = item.valueForAttribute("kMDItemFSName") as? String {
                        let filenameWithPath = NSString(string: "~/Desktop/" + filename).stringByExpandingTildeInPath
                        let url = NSURL(fileURLWithPath: filenameWithPath, isDirectory: false)
                        if let cb = self.newFileCallback {
                            if NSFileManager.defaultManager().fileExistsAtPath(filenameWithPath) {
                                let now = NSDate()
                                var lastModified: AnyObject?
                                _ = try? url.getResourceValue(&lastModified, forKey: NSURLContentModificationDateKey)
                                let diff = now.timeIntervalSince1970 - lastModified!.timeIntervalSince1970
                                if diff < 4 {
                                    cb(fileURL: url)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
