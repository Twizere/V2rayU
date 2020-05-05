//
//  BASEAPI.swift
//  ShadowsocksX-NG
//
//  Created by Youma W Guedalia Floriane on 2/2/20.
//  Copyright © 2020 qiuyuzhou. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

 class BASEAPI{
    static var loginWinCtrl: LoginWindowController!
    
    static var SEVER_ADD = "http://panel.agakoti.com"
    static var LOGIN = "/api/token"
    static var TOKEN_INFO = "/api/token/%@"
    static var GET_SERVERS = "/api/node?access_token=%@&type=v2ray&mode=link"
    static var GET_C0NFIGURATIONS = "/api/configuration"
    
    
    
    static func  Login(email:String, pwd:String) {
        
         var login = false
         var ret_msg = "Failed to Login"
        
        let url = SEVER_ADD + LOGIN
        var account = email;
        
        //Change phone number to email
        if Int(email) != nil {
         account = email + "@phone.com"
        }
        
        
        Alamofire.request(url, method: .post, parameters: ["email":account,"passwd":pwd, "device":"macbook", "app_version":"1.1"])
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                        
                        //let userid = Int(json["data"]["userId"].stringValue)
                        let username = json["data"]["fullname"]
                        let email = json["data"]["email"]
                        //let token = json["data"]["token"]
                        
                        //Saving all the information
                        saveUserInfo(username: username.stringValue, email:email.stringValue)
                        print("Login successfully")
                        BASEAPI.getTokenInfo(token: UserDefaults.standard.string(forKey: "token")!)
                        
                        login = true;
                        ret_msg = json["msg"].stringValue
                        
                    }else{
                        
                        ret_msg = json["msg"].stringValue
                    }
                }catch{
                    print("Error during Login" )
                }
                    //Notfy login Window
                     let loginWindow = LoginWindowController.instance
                     if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:login, serversLoaded: false, msg:ret_msg)
                   
                }
            }
        }
        
       
    }
    
    static func getTokenInfo(token:String){
        
        let url = SEVER_ADD + String(format: TOKEN_INFO,token)
        
        Alamofire.request(url, method: .get)
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                        let expire_date = json["data"]["expireTime"]
                        let token = json["data"]["token"]
                        let userid = json["data"]["userId"]
                        print(json)
                        //Saving all the information
                        saveUserInfo(token: token.stringValue, userid: userid.stringValue, tokenDueDate: expire_date.stringValue)
//
                        print("Got the expire date")

                    }else{
                        
                        print("failed to get expire Date")
                    }
                }catch{
                    print("Error getting token information" )
                }
                
            }
        }
        
    }
    static func saveUserInfo(token:String="",userid:String="",username:String="",email:String="",tokenDueDate:String=""){
        
        if tokenDueDate != ""{
            UserDefaults.set(forKey: .loginDueDate, value:tokenDueDate)
        }
        if(token != ""){
            UserDefaults.set(forKey: .loginToken, value:token)
        }
        if(userid != ""){
            UserDefaults.set(forKey: .loginUserId, value:userid)
        }
        if(username != ""){
        UserDefaults.set(forKey: .loginFullname, value:username)
        }
        if(email != ""){
        UserDefaults.set(forKey: .loginPhoneEmail, value:email)
        }
    }
    static func getServers(token:String)  {
       let url = SEVER_ADD + String(format: GET_SERVERS,token)
        
        Alamofire.request(url, method: .get)
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                       print(json["data"])
                        let links = json["data"].stringValue
                        //remove all the servers
                        removeAllServers();
                        //Saving the Servers
                            importUri(url: links )
                        //Notfy login Window
                        let loginWindow = LoginWindowController.instance
                       
                        if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:true, serversLoaded: true, msg:"Logged in succesfully")
                           
                        }
                        
                        print("Got the servers")
                        
//                        NotificationCenter.default
//                        .post(name: SERVERS_UPDATED, object: nil)
//
                       
                                               
                        
                    }else{
                        
                        print("Failed to get Servers")
                      
                    //Notify Login
                      let loginWindow = LoginWindowController.instance
                                              
                       if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:false, serversLoaded: false, msg:"Failed to get Servers")
                       }
                        // If Login again is needed || Token is expired
                        if(json["msg"].stringValue.contains("token is null")){
                            print("Login again")
                            
                            //delete all servers
                            
                            NotificationCenter.default
                                .post(name: LOGOUT_NEEDED, object: nil)
                            
                            
                            
                        }
                    }
                }catch{
                    print("Error getting servers" )
                    //Notify Login
                    let loginWindow = LoginWindowController.instance
                                            
                     if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:false, serversLoaded: false, msg:"Error getting servers")
                     }
                }
                
            }
        }
    }
    
    
    
    static func saveConfig(text:String,remark:String) {
        v2rayConfig.parseJson(jsonText: text)
        if v2rayConfig.errors.count > 0 {
            //error
            let error = v2rayConfig.errors[0]
            print(error)
        }
        // save
        V2rayServer.add(remark: remark, json: text,isValid:  v2rayConfig.isValid)
    }
    static func importUri(url: String) {
        let urls = url.split(separator: "\n")

        for url in urls {
            let uri = url.trimmingCharacters(in: .whitespaces)

            if uri.count == 0 {
               // noticeTip(title: "import server fail", subtitle: "", informativeText: "import error: uri not found")
                continue
            }

            if !ImportUri.supportProtocol(uri: uri) {
              //  noticeTip(title: "import server fail", subtitle: "", informativeText: "no found ss:// , ssr:// or vmess://")
                continue
            }

            if let importUri = ImportUri.importUri(uri: uri) {
                saveConfig(text: importUri.json, remark: importUri.remark)
                continue
            }

           // noticeTip(title: "import server fail", subtitle: "", informativeText: "no found ss:// , ssr:// or vmess://")
        }
        menuController.showServers()
    }
    
    static func removeAllServers()  {
       
         UserDefaults.del(forKey: .v2rayServerList)
        V2rayServer.loadConfig();
        
    }
}
