import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    if let screen = NSScreen.screens.first {
      self.setFrame(screen.visibleFrame, display: true)
    } else {
      let windowFrame = self.frame
      self.setFrame(windowFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
