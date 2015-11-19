//
//  ImgServiceUploader.swift
//  Image uploader
//
//  Created by Toni Sučić on 16.11.2015.
//  Copyright © 2015 Toni Sučić. All rights reserved.
//

import Foundation
import BrightFutures
import Alamofire

class ImgServiceUploader {
    
    let passcodeData = NSData(contentsOfURL: NSURL(fileURLWithPath: "/Users/tonisucic/passcode"))!
    
    func uploadFile(fileURL: NSURL) -> Future<String, Error> {
        let promise = Promise<String, Error>()
        
        Alamofire.upload(
            .POST,
            "https://img.tonisucic.com/upload",
            headers: ["Content-Type": "multipart/form-data"],
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(fileURL: fileURL, name: "image")
                multipartFormData.appendBodyPart(data: self.passcodeData, name: "passcode")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseString { response in
                        if response.response == nil {
                            promise.failure(.Error(message: "Failed to connect to the server."))
                            return
                        }
                        if response.response!.statusCode != 200 {
                            promise.failure(.Error(message: response.result.value!))
                            return
                        }
                        promise.success(response.result.value!)
                    }
                case .Failure(let encodingError):
                    promise.failure(.Error(message: "\(encodingError)"))
                }
            }
        )
        
        return promise.future
    }
    
}