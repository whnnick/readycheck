import AppKit
import SwiftUI

struct ServiceSwitcherIcon: View {
    let name: String
    let `extension`: String

    var body: some View {
        if let image = Self.image(name: name, extension: `extension`) {
            Image(nsImage: image).resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16).accessibilityHidden(true)
        }
    }

    static func image(name: String, extension fileExtension: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension) else { return nil }
        return NSImage(contentsOf: url)
    }
}
