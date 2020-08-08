//
//  LoginWindowController.swift
//  ShadowsocksX-NG
//
//  Created by Youma W Guedalia Floriane on 2/2/20.
//  Copyright © 2020 qiuyuzhou. All rights reserved.
//

import Cocoa

class LoginWindowController: NSWindowController {
    
   static var instance:LoginWindowController?=nil
    
    @IBOutlet weak var emailView: NSTextFieldCell!
    @IBOutlet weak var pwdView: NSSecureTextFieldCell!
    @IBOutlet weak var loginButton: NSButton!
    
    @IBOutlet weak var redMsgView: NSTextField!
    
    @IBOutlet weak var greenMsgView: NSTextField!
    override func windowDidLoad() {
        super.windowDidLoad()
        redMsgView.stringValue = ""
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        BASEAPI.getPanelUrl()
    }
   override func keyUp(with event: NSEvent)

    {
        //print(event.keyCode)
        if event.keyCode == 36 && loginButton.isEnabled
        {
            doLogin()
        }
        super.keyUp(with: event)
        
    }
    @IBAction func didLogin(_ sender: AnyObject) {
        
        doLogin()
        
        
    }

    func doLogin(){
        loginButton.title = "Logging in...."
        loginButton.isEnabled = false
        redMsgView.stringValue = ""
        BASEAPI.Login(email: emailView.stringValue, pwd: pwdView.stringValue)
        
    }
    func finishedLogin(isLogin : Bool, serversLoaded : Bool, msg:String) {
       //Cleaning the message
        redMsgView.stringValue = ""
        //greenMsgView.stringValue = msg;
        BASEAPI.doLog(text:"Debug-4");
        BASEAPI.doLog(text:msg);
        if(!isLogin){
          shakeWindows()
            redMsgView.stringValue = msg
            loginButton.title = "Login"
        }else{
            BASEAPI.doLog(text:"Debug-3");
            if(!serversLoaded){
                BASEAPI.doLog(text:"Debug-2");
                loginButton.title = "Loading locations ..."
                 BASEAPI.doLog(text:loginButton.title);
                BASEAPI.doLog(text:"Debug-1");
                 let accessToken = UserDefaults.get(forKey: .loginToken)
                BASEAPI.getServers(token: accessToken!);
                BASEAPI.doLog(text:"Debug0");
            }else{
            BASEAPI.doLog(text:"Debug1");
            greenMsgView.stringValue = msg;
                loginButton.title = "Login"
            BASEAPI.doLog(text:"Debug1");
            window?.performClose(self)
            NotificationCenter.default
                            .post(name:LOGGED_IN_SUCCESSFULY, object: nil)
            BASEAPI.doLog(text:"Debug2");
            }
           
        }
         loginButton.isEnabled = true;
        BASEAPI.doLog(text:"Debug3");
    }
    
    
        
    func shakeWindows(){
        let numberOfShakes:Int = 8
        let durationOfShake:Float = 0.5
        let vigourOfShake:Float = 0.05
        
        let frame:CGRect = (window?.frame)!
        let shakeAnimation = CAKeyframeAnimation()
        
        let shakePath = CGMutablePath()
        
        shakePath.move(to: CGPoint(x:NSMinX(frame), y:NSMinY(frame)))
        
        for _ in 1...numberOfShakes{
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) - frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) + frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
        }
        
        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        window?.animations = ["frameOrigin":shakeAnimation]
        window?.animator().setFrameOrigin(window!.frame.origin)
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
    
 NSWorkspace.shared.open(URL(string: "http://www.agakoti.com/password/reset")!)
    }
    @IBAction func openRegister(_ sender: Any) {
     NSWorkspace.shared.open(URL(string: "http://www.agakoti.com/auth/register")!)
        
    }
}
