//
//  AppDelegate.swift
//  Image uploader
//
//  Created by Toni Sučić on 16.11.2015.
//  Copyright © 2015 Toni Sučić. All rights reserved.
//

import Cocoa
import BrightFutures

func shell(input: String) -> (output: String, exitCode: Int32) {
    let task = NSTask()
    task.arguments = ["-c", input]
    task.launchPath = "/bin/bash"

    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
    
    return (output, task.terminationStatus)
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    
    let defaultIcon = NSImage(named: "statusIcon")!
    let loadingIcon = NSImage(named: "statusIconLoading")!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    
    let detector = ScreenshotDetector()
    let uploader = ImgServiceUploader()
    
    var imageUploadEnabled: Bool {
        get {
            return statusMenu.itemWithTag(1)!.state == NSOnState
        }
    }
    
    var supportedExtensions = [".gif", ".jpeg", ".jpg", ".png", ".webm", ".mp4"]
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        defaultIcon.template = true
        loadingIcon.template = false
        
        statusItem.image = defaultIcon
        statusItem.menu = statusMenu
        
        statusItem.button?.window?.registerForDraggedTypes([NSFilenamesPboardType, NSURLPboardType])
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
        if hasFfmpeg() {
            supportedExtensions.append(".mov")
        }
        
        let pasteboard = sender.draggingPasteboard()
        
        if let filenames = pasteboard.propertyListForType(NSFilenamesPboardType) as? [String] {
            let filename = filenames[0]
            
            let isValid = supportedExtensions
                .filter { supportedExtension in filename.hasSuffix(supportedExtension) }
                .count == 1
            
            if isValid && filename.hasSuffix(".mov") {
                let url = NSURL(fileURLWithPath: filename)
                uploadImage(url, deleteFile: true)
            } else if isValid {
                let url = NSURL(fileURLWithPath: filename)
                uploadImage(url)
            }
            
            return isValid
        }
        
        return false
    }
    
    @IBAction func uploadedFromClipboard(sender: NSMenuItem) {
        let pasteboard = NSPasteboard.generalPasteboard()
       
        if let filenames = pasteboard.propertyListForType(NSFilenamesPboardType) as? [String] {
            let filename = filenames[0]
            
            let isValid = supportedExtensions
                .filter { supportedExtension in filename.hasSuffix(supportedExtension) }
                .count == 1
            
            if isValid {
                let url = NSURL(fileURLWithPath: filename)
                uploadImage(url)
            }
       }
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func activeClicked(sender: NSMenuItem) {
        if sender.state == NSOnState {
            sender.state = NSOffState
        } else {
            sender.state = NSOnState
        }
    }
    
    func uploadImage(url: NSURL, deleteFile: Bool = false) {
        if !imageUploadEnabled {
            return
        }
        
        if statusItem.image == loadingIcon {
            let notification = NSUserNotification()
            notification.title = "Image uploader"
            notification.informativeText = "An upload is already in progress. Wait for it to finish."
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
            return
        }
        
        statusItem.image = loadingIcon
        
        var urlFuture: Future<NSURL, NoError>
        
        if url.pathExtension! == "mov" {
            urlFuture = getCompressedMP4File(forMovFilePath: url.path!)
                .map({ filePath in NSURL(fileURLWithPath: filePath) })
        } else {
            urlFuture = Future<NSURL, NoError>(value: url)
        }
        
        urlFuture
            .onSuccess(callback: { uploadURL in
                self.uploader.uploadFile(uploadURL)
                    .onSuccess(callback: { linkToImage in
                        if deleteFile {
                            let fileManager = NSFileManager.defaultManager()
                            try! fileManager.removeItemAtURL(uploadURL)
                        }
                        
                        let onlineURL = NSURL(string: linkToImage)!
                        
                        let pasteboard = NSPasteboard.generalPasteboard()
                        pasteboard.clearContents()
                        pasteboard.setString(linkToImage, forType: NSPasteboardTypeString)
                        
                        NSWorkspace.sharedWorkspace().openURL(onlineURL)
                    })
                    .onFailure(callback: { err in
                        print(err)
                        
                        let notification = NSUserNotification()
                        notification.title = "Image uploader"
                        notification.informativeText = "An error ocurred while uploading the image."
                        notification.soundName = NSUserNotificationDefaultSoundName
                        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                    })
                    .onComplete(callback: { _ in
                        self.statusItem.image = self.defaultIcon
                    })
            })
    }
    
    func hasFfmpeg() -> Bool {
        let (output, exitCode) = shell("/usr/local/bin/brew list | grep ffmpeg")
        if exitCode == EXIT_FAILURE {
            return false
        }
        return output.containsString("ffmpeg")
    }
    
    func getCompressedMP4File(forMovFilePath movFilePath: String) -> Future<String, NoError> {
        let promise = Promise<String, NoError>()
        
        Queue.global.async {
            let nMovFilePath = movFilePath.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
            let tmpName = NSString(string: "~/.\(NSDate().timeIntervalSince1970)").stringByStandardizingPath
            
            shell("/usr/local/bin/ffmpeg -i \(nMovFilePath) -vcodec copy -acodec copy \(tmpName).mp4")
            shell("/usr/local/bin/ffmpeg -i \(tmpName).mp4 -vcodec libx264 -crf 35 \(tmpName).compressed.mp4")
            shell("rm \(tmpName).mp4")
            
            promise.success("\(tmpName).compressed.mp4")
        }
        
        return promise.future
    }
}
