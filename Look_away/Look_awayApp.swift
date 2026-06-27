//
//  Look_awayApp.swift
//  Look_away
//
//  Created by Tejus Nagdev on 27/06/26.
//

import SwiftUI

@main
struct Look_awayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
