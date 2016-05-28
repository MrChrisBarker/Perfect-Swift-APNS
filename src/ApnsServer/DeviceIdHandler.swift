//
//  DeviceIdHandler.swift
//  ApnsServer
//
//  Created by Chris Barker on 23/05/2016.
//  Copyright © 2016 MrChrisBarker. All rights reserved.
//

import PerfectLib

let DATABASE_NAME = "DbDeviceTokens"

class DeviceIdHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        if let deviceToken = request.params("deviceToken") {
            
            let token = deviceToken[0]
            
            DatabaseHelper.addDeviceTokenDb(token, intoDb: DATABASE_NAME)
            
        }
        response.requestCompletedCallback()
    }
    
}