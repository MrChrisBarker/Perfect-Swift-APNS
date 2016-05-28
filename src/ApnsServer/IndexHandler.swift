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
        
//        let aps = ["sound":"default", "alert":"testPush()"]
//        let payload = ["aps":aps]
//        try! APNSNetwork().sendPush("com.myapp.bundle",
//                                    priority: 10,
//                                    payload: payload,
//                                    deviceToken: "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe",
//                                    certificatePath: NSBundle.mainBundle().pathForResource("push", ofType: "p12")!,
//                                    passphrase: "",
//                                    sandbox: true) { (response) -> Void in
//                                        
//        }
        
        
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
            
            try sqlite.forEachRow("SELECT deviceToken, time FROM \(databaseName) ORDER BY time DESC") {
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
