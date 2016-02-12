//
//  UploadsUploader.swift
//  Image uploader
//
//  Created by Toni Sučić on 31.12.2015.
//  Copyright © 2015 Toni Sučić. All rights reserved.
//

import Foundation
import BrightFutures
import Alamofire

class UploadsUploader {
    
    let usernameData = NSString(string: "toni").dataUsingEncoding(NSUTF8StringEncoding)!
    let passwordData = NSData(contentsOfURL: NSURL(fileURLWithPath: "/Users/tonisucic/passcode"))!

    func uploadFile(fileURL: NSURL) -> Future<String, Error> {
        let promise = Promise<String, Error>()

        Alamofire.upload(
            .POST,
            "https://u.tonisucic.com/api/upload",
            headers: ["Content-Type": "multipart/form-data"],
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: self.usernameData, name: "usr")
                multipartFormData.appendBodyPart(data: self.passwordData, name: "pwd")
                multipartFormData.appendBodyPart(fileURL: fileURL, name: "file")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { res in
                        if res.response == nil {
                            promise.failure(.Error(message: "Failed to connect to the server."))
                            return
                        }
                        if res.response!.statusCode != 200 {
                            promise.failure(.Error(message: res.result.value!.valueForKey("error")! as! String))
                            return
                        }
                        promise.success(res.result.value!.valueForKey("success")! as! String)
                    }
                case .Failure(let encodingError):
                    promise.failure(.Error(message: "\(encodingError)"))
                }
            }
        )

        return promise.future
    }
    
}