//
//  PreferncesView.swift
//  Ball
//
//  Created by cro on 30/06/2024.
//

import Foundation
import AppKit

class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var enableDisableSound: NSButton!
    @IBOutlet weak var ballColour: NSPopUpButton!
    @IBOutlet weak var sizeSlider: NSSlider!
    @IBOutlet weak var sizeLabel: NSTextField!
    
    override func viewDidLoad() {
        enableDisableSound.state = UserDefaults.standard.bool(forKey: "enableDisableSound") ? .off : .on
        let ballSize = Int32(UserDefaults.standard.float(forKey: "ballSize"))
        sizeLabel.stringValue = "\(ballSize)%"
        sizeSlider.intValue = ballSize
        
    }
    
    @IBAction func selectBallColour(_ sender: NSPopUpButton) {
        let tag = sender.title
        UserDefaults.standard.set(tag, forKey: "selectedBallColour")
    }
    
    @IBAction func sizeSliderChanged(_ sender: NSSlider) {
        sizeLabel.stringValue = "\(sender.intValue)%"
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp || event.type == .keyDown {
                let value: Float = sender.floatValue == 0 ? -1 : sender.floatValue
                let oldValue = UserDefaults.standard.float(forKey: "ballSize")
                if value != oldValue {
                    UserDefaults.standard.set(value, forKey: "ballSize")
                }
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "Preferences"
    }
}
