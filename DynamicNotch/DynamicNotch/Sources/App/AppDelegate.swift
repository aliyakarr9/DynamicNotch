import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = NotchWindowController()
        windowController?.showWindow(nil)

       
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}
