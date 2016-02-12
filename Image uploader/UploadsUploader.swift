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
    
    let password = try! NSString(contentsOfFile: "/Users/tonisucic/passcode", encoding: NSUTF8StringEncoding)
    
    func uploadFile(fileURL: NSURL) -> Future<String, Error> {
        let promise = Promise<String, Error>()
        
        let loginParams = [
            "username": "toni",
            "password": password
        ]
        
        Alamofire.request(
            .POST,
            "https://u.tonisucic.com/api/login",
            parameters: loginParams)
            .responseJSON(completionHandler: { res in
                if let result = res.result.value {
                    if result.valueForKey("success") != nil {
                        Alamofire.upload(
                            .POST,
                            "https://u.tonisucic.com/api/upload",
                            headers: ["Content-Type": "multipart/form-data"],
                            multipartFormData: { multipartFormData in
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
                    } else {
                        promise.failure(.Error(message: res.result.value!.valueForKey("error")! as! String))
                    }
                } else {
                    promise.failure(.Error(message: "Server error"))
                }
            })
        
        return promise.future
    }
    
}