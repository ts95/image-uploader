//
//  AppDelegate.swift
//  Image uploader
//
//  Created by Toni Sučić on 16.11.2015.
//  Copyright © 2015 Toni Sučić. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    
    let defaultIcon = NSImage(named: "statusIcon")!
    let loadingIcon = NSImage(named: "statusIconLoading")!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    
    let detector = ScreenshotDetector()
    let uploader = ImgServiceUploader()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        defaultIcon.template = true
        loadingIcon.template = false
        
        statusItem.image = defaultIcon
        statusItem.menu = statusMenu
        
        statusItem.button?.window?.registerForDraggedTypes([NSFilenamesPboardType])
        statusItem.button!.window?.delegate = self
        
        detector.newFileCallback = { fileURL in
            self.uploadImage(fileURL, deleteFile: true)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // ...
    }
    
    func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.Copy
    }
    
    func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let supportedExtensions = [".gif", ".jpeg", ".jpg", ".png", ".webm"]
        let pasteboard = sender.draggingPasteboard()
        
        if let filenames = pasteboard.propertyListForType(NSFilenamesPboardType) as? [String] {
            if filenames.count > 1 {
                return false
            }
            
            let filename = filenames[0]
            
            let isValid = supportedExtensions
                .filter { supportedExtension in filename.hasSuffix(supportedExtension) }
                .count == 1
            
            if isValid {
                let url = NSURL(fileURLWithPath: filename, isDirectory: false)
                uploadImage(url)
            }
            
            return isValid
        }
        
        return false
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func uploadImage(url: NSURL, deleteFile: Bool = false) {
        statusItem.image = loadingIcon
        
        uploader
            .uploadFile(url)
            .onSuccess(callback: { linkToImage in
                if deleteFile {
                    let fileManager = NSFileManager.defaultManager()
                    try! fileManager.removeItemAtURL(url)
                }
                
                let onlineURL = NSURL(string: linkToImage)!
                
                let pasteboard = NSPasteboard.generalPasteboard()
                pasteboard.clearContents()
                //pasteboard.setData(NSData(contentsOfURL: onlineURL), forType: NSPasteboardTypePNG)
                pasteboard.setString(linkToImage, forType: NSPasteboardTypeString)
                
                NSWorkspace.sharedWorkspace().openURL(onlineURL)
            })
            .onFailure(callback: { err in
                print(err)
                
                let notification = NSUserNotification()
                notification.title = "Image uploader"
                notification.informativeText = "An error ocurred when uploading the image."
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
            })
            .onComplete(callback: { _ in
                self.statusItem.image = self.defaultIcon
            })
    }

}