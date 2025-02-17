import Cocoa
import FlutterMacOS
import window_manager


class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    let frame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(frame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // this block plus the import at the top is form
  // https://github.com/leanflutter/window_manager/tree/main/packages/window_manager
  // -- see instructions for "Hidden at launch" 
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
      super.order(place, relativeTo: otherWin)
      hiddenWindowAtLaunch()
  }

}
