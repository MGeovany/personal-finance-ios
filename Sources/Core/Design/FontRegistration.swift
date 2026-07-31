import CoreText
import Foundation
import UIKit

/// Makes sure every Inter face in the bundle is actually registered before any
/// view asks for it.
///
/// `UIAppFonts` in Info.plist should be enough. In practice a missing or renamed
/// file fails silently and every `Font.custom` call falls back to San Francisco,
/// which is how the app can look like it never shipped a Google Font. Registering
/// from the bundle and checking `UIFont(name:)` catches that on the first launch.
enum FontRegistration {
    static func register() {
        let filenames = [
            "Inter-Light.ttf",
            "Inter-Regular.ttf",
            "Inter-Medium.ttf",
            "Inter-SemiBold.ttf",
            "Inter-Bold.ttf",
            "InterDisplay-Regular.ttf",
            "InterDisplay-SemiBold.ttf",
            "InterDisplay-Bold.ttf",
        ]

        for filename in filenames {
            registerFile(filename)
        }

        #if DEBUG
        let missing = DesignSystem.Face.all.filter { UIFont(name: $0, size: 12) == nil }
        if missing.isEmpty {
            print("[Cero] Inter registered: \(DesignSystem.Face.all.joined(separator: ", "))")
        } else {
            print("[Cero] Inter FAILED to load: \(missing.joined(separator: ", "))")
            let available = UIFont.familyNames
                .filter { $0.localizedCaseInsensitiveContains("inter") }
                .flatMap { UIFont.fontNames(forFamilyName: $0) }
            print("[Cero] Available Inter faces: \(available)")
        }
        #endif
    }

    private static func registerFile(_ filename: String) {
        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf")
                ?? Bundle.main.url(forResource: filename, withExtension: nil) else {
            #if DEBUG
            print("[Cero] Font file missing from bundle: \(filename)")
            #endif
            return
        }

        var error: Unmanaged<CFError>?
        // `UIAppFonts` usually registers first; Code 105 means "already there".
        _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }
}
