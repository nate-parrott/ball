//
//  AppDelegate.swift
//  Ball
//
//  Created by nate parrott on 1/22/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var prefsWindowController: NSWindowController?
    
    let appController = AppController()
    
    @IBAction func showAbout(_ sender: Any) {
        NSLog("about clicky")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(
            options: [NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                string: "Created by Nate Parrot\nhttps://nateparrot.com\n",
                attributes: [
                    NSAttributedString.Key.font: NSFont.boldSystemFont(
                        ofSize: NSFont.smallSystemFontSize),
                ]
            )
          ]
        )
    }
    
    @IBAction func openPreferences(_ sender: Any) {
        if prefsWindowController == nil {
            prefsWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "PreferencesWindowController") as? NSWindowController
        }
        NSApp.activate(ignoringOtherApps: true)
        prefsWindowController?.showWindow(self)
    }

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
