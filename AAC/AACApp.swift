//
//  AACApp.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//

import SwiftUI

@main
struct AACApp: App {
    @State private var isLoading = true
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#else
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    var body: some Scene {
        WindowGroup {
            Group {
                AutomaticAssessment()
                    .task {
                        requestCameraPermission()
                        requestAudioPermission()
                    }
            }
            .environment(\.colorScheme, .light)
        }
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateCancel
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication,

                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {

        return AppDelegate.orientationLock

    }

}
#endif
