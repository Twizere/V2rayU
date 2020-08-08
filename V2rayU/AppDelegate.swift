//
//  AppDelegate.swift
//  V2rayU
//
//  Created by yanue on 2018/10/9.
//  Copyright © 2018 yanue. All rights reserved.
//

import Cocoa
import ServiceManagement
import Swifter

let launcherAppIdentifier = "nezalab.agakoti.mac.Launcher"
let appVersion = getAppVersion()

let NOTIFY_TOGGLE_RUNNING_SHORTCUT = Notification.Name(rawValue: "NOTIFY_TOGGLE_RUNNING_SHORTCUT")
let NOTIFY_SWITCH_PROXY_MODE_SHORTCUT = Notification.Name(rawValue: "NOTIFY_SWITCH_PROXY_MODE_SHORTCUT")
let SERVERS_UPDATED = Notification.Name(rawValue: "SERVERS_UPDATED")
let LOGOUT_NEEDED = Notification.Name(rawValue:"LOGOUT_NEEDED")
let DISCONNECT_VPN = Notification.Name(rawValue:"DISCONNECT_VPN")
let LOGGED_IN_SUCCESSFULY = Notification.Name(rawValue:"LOGGED_IN_SUCCESSFULY")
let mainLogFilePath = NSHomeDirectory() + "/Library/Logs/agakoti.log"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // bar menu
    @IBOutlet weak var statusMenu: NSMenu!
    
    @IBOutlet weak var loginMenu: NSMenuItem!
    
    @IBOutlet weak var logoutMenu: NSMenuItem!
    
    @IBOutlet weak var accountTitleMenuItem: NSMenuItem!
    
    @IBOutlet weak var usernameMenuItem: NSMenuItem!
    
    @IBOutlet weak var emailMenuItem: NSMenuItem!
    
    @IBOutlet weak var toggleRunningMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // default settings
        self.checkDefault()
        //BASEAPI.doLog(text:"Agakoti is starting Up!!");
        loginCheck();
        ToggleRunning(false,true)
        // auto Clear Logs
        if UserDefaults.getBool(forKey: .autoClearLog) {
            print("ClearLogs")
            V2rayLaunch.ClearLogs()
        }

        // auto launch
        if UserDefaults.getBool(forKey: .autoLaunch) {
            // Insert code here to initialize your application
            let startedAtLogin = NSWorkspace.shared.runningApplications.contains {
                $0.bundleIdentifier == launcherAppIdentifier
            }

            if startedAtLogin {
                DistributedNotificationCenter.default().post(name: Notification.Name("terminateV2rayU"), object: Bundle.main.bundleIdentifier!)
            }
        }

        // check v2ray core
        V2rayCore().check()
        // generate plist
        V2rayLaunch.generateLaunchAgentPlist()
        // auto check updates
        if UserDefaults.getBool(forKey: .autoCheckVersion) {
            // check version
            V2rayUpdater.checkForUpdatesInBackground()
        }

        // start http server for pac
        V2rayLaunch.startHttpServer()

        // wake and sleep
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onSleepNote(note:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onWakeNote(note:)), name: NSWorkspace.didWakeNotification, object: nil)
        // url scheme
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleAppleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        let path = Bundle.main.bundlePath
        // /Users/yanue/Library/Developer/Xcode/DerivedData/V2rayU-cqwhqdwsnxsplqgolfwfywalmjps/Build/Products/Debug
        // working dir must be: /Applications/V2rayU.app
        NSLog(String.init(format: "working dir:%@", path))

        if !(path.contains("Developer/Xcode") || path.contains("/Applications/V2rayU.app") || path.contains("/Applications/Agakoti.app")) {
            makeToast(message: "Please drag 'Agakoti' to '/Applications' directory", displayDuration: 5.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                NSApplication.shared.terminate(self)
            }
        }

        // set global hotkey
        let notifyCenter = NotificationCenter.default
        notifyCenter.addObserver(forName: NOTIFY_TOGGLE_RUNNING_SHORTCUT, object: nil, queue: nil, using: {
            notice in
            ToggleRunning()
        })

        notifyCenter.addObserver(forName: NOTIFY_SWITCH_PROXY_MODE_SHORTCUT, object: nil, queue: nil, using: {
            notice in
            SwitchProxyMode()
        })
        
        notifyCenter.addObserver(forName: LOGGED_IN_SUCCESSFULY, object: nil, queue: nil, using: {
            notice in
            BASEAPI.doLog(text:"Debug4");
            // Showing the Notification
            let username = UserDefaults.get(forKey: .loginFullname);
            BASEAPI.doLog(text:"Debug5");
//            let noty = NSUserNotification()
//
//            noty.title = "Hi " + username!
//            noty.subtitle = "Welcome back to AGAKOTI VPN"
//            noty.hasActionButton = true
//            noty.soundName="NSUserNotificationDefaultSoundName"
//            NSUserNotificationCenter.default.deliver(noty)
//
            BASEAPI.doLog(text:"Debug6");
            let alert = NSAlert()
            BASEAPI.doLog(text:"Debug7");
            alert.messageText = "Hi " + username!
            alert.informativeText = "Welcome back to AGAKOTI VPN"
            alert.alertStyle = .informational
            //alert.addButton(withTitle: "OK")
            BASEAPI.doLog(text:"Debug8");
            alert.runModal()
            BASEAPI.doLog(text:"Debug9");
            
            //Hide Login Controls
            self.loginCheck();
            BASEAPI.doLog(text:"Debug10");
        })
        notifyCenter.addObserver(forName: LOGOUT_NEEDED, object: nil, queue: nil, using: {
            notice in
            
            UserDefaults.set(forKey: .loginToken, value:"")
            self.logout();
        })
        
        notifyCenter.addObserver(forName: SERVERS_UPDATED, object: nil, queue: nil, using: {
                   notice in
                    
               })
        
       notifyCenter.addObserver(forName: DISCONNECT_VPN, object: nil, queue: nil, using: {
                   notice in
                    ToggleRunning(false,true)
               })
        
        // Register global hotkey
        ShortcutsController.bindShortcuts()
        
        //Updating the servers
        let token = UserDefaults.get(forKey: .loginToken)
          if !(UserDefaults.get(forKey: .loginDueDate) == "" ||
              token == "" ){
              
              BASEAPI.getServers(token: token!)
          }
    }

    func checkDefault() {
        if UserDefaults.get(forKey: .v2rayCoreVersion) == nil {
            UserDefaults.set(forKey: .v2rayCoreVersion, value: V2rayCore.version)
        }
        if UserDefaults.get(forKey: .autoCheckVersion) == nil {
            UserDefaults.setBool(forKey: .autoCheckVersion, value: true)
        }
        if UserDefaults.get(forKey: .autoUpdateServers) == nil {
            UserDefaults.setBool(forKey: .autoUpdateServers, value: true)
        }
        if UserDefaults.get(forKey: .autoSelectFastestServer) == nil {
            UserDefaults.setBool(forKey: .autoSelectFastestServer, value: false)
        }
        if UserDefaults.get(forKey: .autoLaunch) == nil {
            SMLoginItemSetEnabled(launcherAppIdentifier as CFString, true)
            UserDefaults.setBool(forKey: .autoLaunch, value: true)
        }
        if UserDefaults.get(forKey: .runMode) == nil {
            UserDefaults.set(forKey: .runMode, value: RunMode.pac.rawValue)
        }
        if V2rayServer.count() == 0 {
            // add default
            V2rayServer.add(remark: "default", json: "", isValid: false)
        }
        
        // Login Info
        if UserDefaults.get(forKey: .loginToken) == nil {
            UserDefaults.set(forKey: .loginToken, value:"")
        }
        if UserDefaults.get(forKey: .loginFullname) == nil {
            UserDefaults.set(forKey: .loginFullname, value:"")
        }
        if UserDefaults.get(forKey: .loginPhoneEmail) == nil {
            UserDefaults.set(forKey: .loginPhoneEmail, value:"")
        }
        if UserDefaults.get(forKey: .loginDueDate) == nil {
            UserDefaults.set(forKey: .loginDueDate, value:"")
        }
        if UserDefaults.get(forKey: .loginUserId) == nil {
            UserDefaults.set(forKey: .loginUserId, value:"")
        }
        
    }
   

    @objc func handleAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let appleEventDescription = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            return
        }

        guard let appleEventURLString = appleEventDescription.stringValue else {
            return
        }

        _ = URL(string: appleEventURLString)
        // todo
    }

    @objc func onWakeNote(note: NSNotification) {
        print("onWakeNote")
        // check v2ray core
        V2rayCore().check()
        // auto check updates
        if UserDefaults.getBool(forKey: .autoCheckVersion) {
            // check version
            V2rayUpdater.checkForUpdatesInBackground()
        }
        // auto update subscribe servers
        if UserDefaults.getBool(forKey: .autoUpdateServers) {
            V2raySubSync().sync()
        }
        // ping
        PingSpeed().pingAll()
    }

    @objc func onSleepNote(note: NSNotification) {
        print("onSleepNote")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // unregister All shortcut
        MASShortcutMonitor.shared().unregisterAllShortcuts()
        // Insert code here to tear down your application
        V2rayLaunch.Stop()
        // restore system proxy
        V2rayLaunch.setSystemProxy(mode: .restore)
    }
    func loginCheck(){

        let token = UserDefaults.get(forKey: .loginToken)
        let username =  UserDefaults.get(forKey: .loginFullname)
        let email =  UserDefaults.get(forKey: .loginPhoneEmail)
        
        if(token=="" ){
            //  not logged in
            BASEAPI.doLog(text:"Is not  Logged in")
            
            //Hide the logout button
            loginMenu.isHidden=false
            logoutMenu.isHidden=true;
            
            //Hide the Account information
            accountTitleMenuItem.isHidden = true
            usernameMenuItem.isHidden = true
            emailMenuItem.isHidden = true

            logout()
            //Disable Connect and Disconnect button
            toggleRunningMenuItem.isHidden=true;
            
        }else{
            // logged in
            BASEAPI.doLog(text:"Is  Logged in")
            //Hide the login button
            logoutMenu.isEnabled=true;
             loginMenu.isHidden=true
            logoutMenu.isHidden=false;
            
            
            //Show the Account information
               usernameMenuItem.title =  username!
               emailMenuItem.title =  email!
               accountTitleMenuItem.isHidden = false
               usernameMenuItem.isHidden = false
               emailMenuItem.isHidden = false

            //Enable Connect and Disconnect button
            toggleRunningMenuItem.isHidden=false;
            
            
        }
    }
    func updateServers(){
        let defaults = UserDefaults.standard
               let token = defaults.string(forKey: "token")
               
               if(token != "" ){
                BASEAPI.getServers(token:token!)
                }
    }
    
    func logout(){
            print("Logging out...")
            BASEAPI.removeAllServers();
            UserDefaults.set(forKey: .loginToken, value:"")
            print("logged out");
            NotificationCenter.default
            .post(name: DISCONNECT_VPN, object: nil)
            openLoginWindow();
            
        
    }
    
    @IBAction func doLogout(_ sender: Any) {
        UserDefaults.set(forKey: .loginToken, value:"")
        loginCheck()
    }
    func openLoginWindow(){
        if loginWinCtrl != nil {
            loginWinCtrl.close()
        }
        let ctrl = LoginWindowController(windowNibName: "LoginWindowController")
        loginWinCtrl = ctrl
        LoginWindowController.instance=ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
        ctrl.window?.center()
    }
    @IBAction func loginWindow(_ sender: Any) {
           openLoginWindow()
       }
    
    
}
