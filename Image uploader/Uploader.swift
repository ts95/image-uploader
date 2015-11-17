//
//  Uploader.swift
//  Image uploader
//
//  Created by Toni Sučić on 16.11.2015.
//  Copyright © 2015 Toni Sučić. All rights reserved.
//

import Foundation
import BrightFutures

protocol UploaderProtocol {
    // Returns a link to the uploaded image
    func uploadFile(fileURL: NSURL) -> Future<String, Error>
}