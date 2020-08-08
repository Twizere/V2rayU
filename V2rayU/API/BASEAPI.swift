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
    
    static var PANEL_URL_FEED = "https://gitee.com/pacitwizere/AGAKOTI-APP-UPDATOR/raw/master/%20panel-url-mac.json"
    
    static var LOGIN = "/api/token"
    static var TOKEN_INFO = "/api/token/%@"
    static var GET_SERVERS = "/api/node?access_token=%@&type=v2ray&mode=link"
    static var GET_C0NFIGURATIONS = "/api/configuration"
    
    
    static func getPanelUrl(){
       
            Alamofire.request(PANEL_URL_FEED, method: .get).responseJSON {
                response in
                if response.data != nil {
                    do {
                            let json = try JSON(data: response.data!)
                            let url = json["url"].stringValue
                            doLog(text:url)
                            if(url != ""){
                                UserDefaults.set(forKey: .panelUrl, value:url)
                            }
                        }catch{
                      doLog(text: "Error while getting the Panel Url" )
                      sleep(5)
                      getPanelUrl()
                    
                    }
          
            
                }
        }
    }
    static func  Login(email:String, pwd:String) {
        
         var login = false
         var ret_msg = "Failed to Login"
        
        let url = UserDefaults.get(forKey: .panelUrl)! + LOGIN
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
                        let token = json["data"]["token"]
                        
                        //Saving all the information
                        saveUserInfo(token:token.stringValue, username: username.stringValue, email:email.stringValue)
                        doLog(text:"Login successfully")
                        doLog(text:"Debug-lg-1")
                        let accessToken = UserDefaults.get(forKey: .loginToken)
                        doLog(text:"Debug-lg-2")
                        if accessToken != nil{
                        BASEAPI.getTokenInfo(token: accessToken!)
                        }else{
                            doLog(text:"Invalid Token")
                            
                        }
                        doLog(text:"Debug-lg-3")
                        login = true;
                        ret_msg = json["msg"].stringValue
                        
                    }else{
                        
                        ret_msg = json["msg"].stringValue
                    }
                    doLog(text:"Debug-lg-1")
                }catch{
                    doLog(text: "Error during Login" )
                }
                    //Notfy login Window
                     let loginWindow = LoginWindowController.instance
                     if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:login, serversLoaded: false, msg:ret_msg)
                   
                }
            }
        }
        
       
    }
    
    static func getTokenInfo(token:String){
        doLog(text: "Debug-gT-0")
        let url = UserDefaults.get(forKey: .panelUrl)! + String(format: TOKEN_INFO,token)
        doLog(text: "Debug-gT-1")
        Alamofire.request(url, method: .get)
        .responseJSON { response in
            if response.data != nil {
                doLog(text: "Debug-gT-2")
                do{
                      let json = try JSON(data: response.data!)
                    doLog(text: "Debug-gT-3")
                    if(json["ret"]==1){
                        let expire_date = json["data"]["expireTime"]
                        let token = json["data"]["token"]
                        let userid = json["data"]["userId"]
                        doLog(text:json.stringValue)
                        //Saving all the information
                        doLog(text: "Debug-gT-4")
                        saveUserInfo(token: token.stringValue, userid: userid.stringValue, tokenDueDate: expire_date.stringValue)
                        
//
                        doLog(text:"Got the expire date")

                    }else{
                        
                        doLog(text:"failed to get expire Date")
                    }
                }catch{
                    doLog(text:"Error getting token information" )
                }
                
            }
        }
        
    }
    static func saveUserInfo(token:String="",userid:String="",username:String="",email:String="",tokenDueDate:String=""){
        doLog(text: "Debug-sU-0")
        if tokenDueDate != ""{
            UserDefaults.set(forKey: .loginDueDate, value:tokenDueDate)
        }
        doLog(text: "Debug-sU-1")
        if(token != ""){
            UserDefaults.set(forKey: .loginToken, value:token)
        }
        doLog(text: "Debug-sU-2")
        if(userid != ""){
            UserDefaults.set(forKey: .loginUserId, value:userid)
        }
        doLog(text: "Debug-sU-3")
        if(username != ""){
        UserDefaults.set(forKey: .loginFullname, value:username)
        }
        doLog(text: "Debug-sU-4")
        if(email != ""){
        UserDefaults.set(forKey: .loginPhoneEmail, value:email)
        }
        doLog(text: "Debug-sU-5")
    }
    static func getServers(token:String)  {
        let url = UserDefaults.get(forKey: .panelUrl)! + String(format: GET_SERVERS,token)
        
        Alamofire.request(url, method: .get)
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                        doLog(text:json["data"].stringValue)
                        let links = json["data"].stringValue
                        //remove all the servers
                        removeAllServers();
                        //Saving the Servers
                            importUri(url: links )
                        //Notfy login Window
                        let loginWindow = LoginWindowController.instance
                       
                        if(loginWindow != nil){
                            
                            loginWindow?.finishedLogin(isLogin:true, serversLoaded: true, msg:"Logged in succesfully")
                           
                        }
                        
                        doLog(text:"Got the servers")
                        
//                        NotificationCenter.default
//                        .post(name: SERVERS_UPDATED, object: nil)
//
                       
                                               
                        
                    }else{
                        
                        doLog(text:"Failed to get Servers")
                      
                    //Notify Login
                      let loginWindow = LoginWindowController.instance
                                              
                       if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:false, serversLoaded: false, msg:"Failed to get Servers")
                       }
                        // If Login again is needed || Token is expired
                        if(json["msg"].stringValue.contains("token is null")){
                            doLog(text:"Login again")
                            
                            //delete all servers
                            
                            NotificationCenter.default
                                .post(name: LOGOUT_NEEDED, object: nil)
                            
                            
                            
                        }
                    }
                }catch{
                    doLog(text:"Error getting servers" )
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
            doLog(text:error)
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
    static func doLog( text: String){
        do{
//            let file = URL.init(fileURLWithPath: mainLogFilePath);
//            
//            let oldtext = try! String(contentsOf:file)
//               try! (oldtext+"\n"+text).write(to: file, atomically: true, encoding: String.Encoding.utf8)
//           
               print(text)
            
        } catch let error as NSError{
            print("Failed writing to the File, Error:" + error.localizedDescription);
        }
       }
}
