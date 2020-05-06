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
        
        print(msg);
        if(!isLogin){
          shakeWindows()
            redMsgView.stringValue = msg
            loginButton.title = "Login"
        }else{
            if(!serversLoaded){
                loginButton.title = "Loading locations ..."
                BASEAPI.getServers(token: UserDefaults.standard.string(forKey: "token")!)
            }else{
                
            greenMsgView.stringValue = msg;
                loginButton.title = "Login"
               
            window?.performClose(self)
            NotificationCenter.default
                            .post(name:LOGGED_IN_SUCCESSFULY, object: nil)

            }
           
        }
         loginButton.isEnabled = true;
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
