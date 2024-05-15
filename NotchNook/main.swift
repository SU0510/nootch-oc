//
//  main.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import Foundation

import AppKit

let appDelegate = AppDelegate()

let application = NSApplication.shared
application.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
