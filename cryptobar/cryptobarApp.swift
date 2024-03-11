import SwiftUI

@main
struct cryptobarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        WindowGroup {
            ContentView()
        }
    }
}
