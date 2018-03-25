// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import Pisth_Shared

/// The app delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Shared and unique instance.
    static var shared: AppDelegate!
    
    /// The app's window.
    var window: UIWindow?
    
    /// Updates available.
    var updates = [String]()
    
    /// Installed packages.
    var installed = [String]()
    
    /// SSH session.
    var session: NMSSHSession?
    
    /// Search for updates
    func searchForUpdates() {
        // Search for updates
        if let session = session {
            if session.isConnected && session.isAuthorized {
                if let packages = (try? session.channel.execute("aptitude -F%p --disable-columns search ~U").components(separatedBy: "\n")) {
                    self.updates = packages
                    
                    if TabBarController.shared != nil {
                        DispatchQueue.main.async {
                            ((TabBarController.shared.viewControllers?[3] as? UINavigationController)?.topViewController as? UpdatesViewController)?.tableView.reloadData()
                            if self.updates.count > 1 {
                                TabBarController.shared.viewControllers?[3].tabBarItem.badgeValue = "\(self.updates.count-1)"
                            } else {
                                TabBarController.shared.viewControllers?[3].tabBarItem.badgeValue = nil
                            }
                        }
                    }
                }
                
                if let installed = (try? session.channel.execute("apt-mark showmanual").components(separatedBy: "\n")) {
                    self.installed = installed
                    
                    DispatchQueue.main.async {
                        ((TabBarController.shared.viewControllers?[2] as? UINavigationController)?.topViewController as? InstalledTableViewController)?.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    /// Open the session.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
    
        UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        // Connect
        if DataManager.shared.connections.indices.contains(UserDefaults.standard.integer(forKey: "connection")) {
            let connection = DataManager.shared.connections[UserDefaults.standard.integer(forKey: "connection")]
            
            if let session = NMSSHSession.connect(toHost: connection.host, port: Int(connection.port), withUsername: connection.username) {
                if session.isConnected {
                    session.authenticate(byPassword: connection.password)
                }
                
                self.session = session
            }

        }
        
        return true
    }

    /// Search for updates.
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        let activityVC = ActivityViewController(message: "Loading...")
        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true) {
            self.searchForUpdates()
            activityVC.dismiss(animated: true, completion: nil)
        }
    }

}

