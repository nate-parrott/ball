//
//  AppDelegate.swift
//  Ball
//
//  Created by nate parrott on 1/22/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let appController = AppController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // When dock icon is pressed, animate ball from dock pos
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        appController.dockIconClicked()
        return true
    }
}

