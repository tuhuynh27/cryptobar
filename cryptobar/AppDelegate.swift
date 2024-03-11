import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the window
        window = NSApplication.shared.windows.first
        window.orderOut(nil)
        // Hide the application icon from the dock
        NSApp.setActivationPolicy(.accessory)
    }
}
