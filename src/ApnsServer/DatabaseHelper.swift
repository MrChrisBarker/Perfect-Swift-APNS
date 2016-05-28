//
//  DatabaseHelper.swift
//  ApnsServer
//
//  Created by Chris Barker on 23/05/2016.
//  Copyright © 2016 MrChrisBarker. All rights reserved.
//

import PerfectLib

class DatabaseHelper: AnyObject {
    
    
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
    
    static func addDeviceTokenDb(deviceToken: String, intoDb databaseName: String){
        
        do{
            let sqlite = try SQLite(DatabaseHelper.databaseLocation())
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
    
    static func getDeviceTokenListFromDbWithName(databaseName: String) ->Array<String>{
        
        var deviceTokenList = Array<String>()
        
        do{
            let sqlite = try SQLite(databaseLocation())
            
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
    
}