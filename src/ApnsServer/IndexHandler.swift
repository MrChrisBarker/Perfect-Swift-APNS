//
//  IndexHandler.swift
//  ApnsServer
//
//  Created by Chris Barker on 18/05/2016.
//  Copyright © 2016 MrChrisBarker. All rights reserved.
//

import PerfectLib
//import APNS



public func PerfectServerModuleInit(){

    Routing.Handler.registerGlobally()
    
    Routing.Routes["GET", ["/push", "push"] ] = { (_:WebResponse) in return IndexHandler() }
    Routing.Routes["GET", ["/logdevice", "logdevice"] ] = { (_:WebResponse) in return DeviceIdHandler() }
    Routing.Routes["GET", ["/listtokens", "listtokens"] ] = { (_:WebResponse) in return TokenHandler() }
    
    TokenHandler.createDBWithName("DbDeviceTokens")
    
}

class IndexHandler: RequestHandler{
   
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        let configurationName = "com.calicoware.APNS-Test-application"
        
        if let message: String = request.param("message") {
            
            NotificationPusher.addConfigurationIOS(configurationName) {
                (net:NetTCPSSL) in
                
                net.keyFilePassword = "789789"
                
                let certPath = "./webroot/Certificates.pem"
                let privatePath = "./webroot/ck.pem"
                
                guard net.useCertificateFile(certPath) &&
                    net.usePrivateKeyFile(privatePath) &&
                    net.checkPrivateKey()
                    else {
                        
                        let code = Int32(net.errorCode())
                        print("Error validating private key file: \(net.errorStr(code))")
                        return
                }
            }
            
            NotificationPusher.development = true // set to toggle to the APNS sandbox server
            
            let deviceTokens: Array<String> = TokenHandler().getDeviceTokenListFromDbWithName("DbDeviceTokens")
            
            for deviceToken: String in deviceTokens {
                
                let deviceId = deviceToken
                let ary = [IOSNotificationItem.AlertBody(message), IOSNotificationItem.Sound("default")]
                let n = NotificationPusher()
                
                n.apnsTopic = "com.calicoware.APNS-Test-application"
                
                n.pushIOS(configurationName, deviceToken: deviceId, expiration: 0, priority: 10, notificationItems: ary) {
                    response in
                    
                    print("NotificationResponse: \(response.code) \(response.body)")
                }
                
            }
            
        }
    

        response.requestCompletedCallback()
    }
    
}

class TokenHandler: RequestHandler{

    func handleRequest(request: WebRequest, response: WebResponse) {
     
        if let deviceTokens: Array<String> = getDeviceTokenListFromDbWithName("DbDeviceTokens") {
            
            print("DEVICE TOKEN LIST: \(deviceTokens)")
            print("")
            response.appendBodyString(String(deviceTokens))
            
        }
        
        response.requestCompletedCallback()
        
    }
    
    func getDeviceTokenListFromDbWithName(databaseName: String) ->Array<String>{
        
        var deviceTokenList = Array<String>()
        
        do{
            let sqlite = try SQLite(TokenHandler.databaseLocation())
            
            try sqlite.forEachRow("SELECT DISTINCT deviceToken, time FROM \(databaseName) ORDER BY time DESC") {
                (stmt:SQLiteStmt, i:Int) -> () in
                
                let name: String = stmt.columnText(0)
                deviceTokenList.append(name)
                
            }
        }
        catch{
            print("")
        }
        
        return deviceTokenList
        
    }
    
    static func createDBWithName(databaseName: String){
        
        do {
            let sqlite = try SQLite(databaseLocation())
            try sqlite.execute("CREATE TABLE IF NOT EXISTS \(databaseName) (id INTEGER PRIMARY KEY, deviceToken TEXT, time REAL)")
        }
        catch {
            print("Error creating Database with name \(databaseName)")
        }
        
    }
    
    static func databaseLocation() -> String{
        return PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "APNSDeviceList"
    }
    
}

class DeviceIdHandler: RequestHandler {
    
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
