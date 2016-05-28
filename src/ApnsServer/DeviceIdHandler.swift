//
//  DeviceIdHandler.swift
//  ApnsServer
//
//  Created by Chris Barker on 23/05/2016.
//  Copyright © 2016 MrChrisBarker. All rights reserved.
//

import PerfectLib

class DeviceIdHandlerolD: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        if let deviceToken = request.params("deviceToken") {
            
            let token = deviceToken[0]
            
            addDeviceTokenDb(token, intoDb: "DbDeviceTokens")
            
        }
        response.requestCompletedCallback()
    }
    
    func addDeviceTokenDb(deviceToken: String, intoDb databaseName: String){
        
        do{
            let sqlite = try SQLite(databaseLocation())
            try sqlite.execute("INSERT INTO \(databaseName) (deviceToken, time) VALUES (?,?)", doBindings: {
                (stmt:SQLiteStmt) -> () in
                
                try stmt.bind(1, deviceToken)
                try stmt.bind(2, ICU.getNow())
                
            })
        }
        catch {
            print("Error inserting deviceToken: \(deviceToken) into database: \(databaseName)")
        }
        
    }
    
    func databaseLocation() -> String{
        return PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "APNSDeviceList"
    }
    
}