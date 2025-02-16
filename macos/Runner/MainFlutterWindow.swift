import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    let frame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(frame, display: true)
    self.minSize = NSSize(width: 1920/2, height: 1200/2)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
