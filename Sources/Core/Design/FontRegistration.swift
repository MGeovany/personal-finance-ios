import CoreText
import Foundation
import UIKit

/// Makes sure the app's typefaces are registered before any view asks for one.
///
/// `UIAppFonts` in Info.plist should be enough. In practice a missing or renamed file
/// fails silently and every `Font.custom` call falls back to San Francisco, which is
/// how the app can look like it never shipped its own type at all. Registering from
/// the bundle and then checking `UIFont(name:)` catches that on the first launch
/// instead of in a screenshot weeks later.
///
/// Every bundled typeface is registered, not only the active one, so switching
/// `Typeface.active` is the single change that switch requires.
enum FontRegistration {
    static func register() {
        for name in Typeface.allCases.flatMap(\.fileNames) {
            registerFile(name)
        }

        #if DEBUG
        verify()
        #endif
    }

    private static func registerFile(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
            #if DEBUG
            print("[Cero] Font file missing from bundle: \(name).ttf")
            #endif
            return
        }

        var error: Unmanaged<CFError>?
        // `UIAppFonts` usually registers first; Code 105 means "already there".
        _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }

    #if DEBUG
    /// A face name that does not resolve looks exactly like a missing file, and for a
    /// variable font whose weights are named instances there is no file to go looking
    /// for. This says which of the two happened.
    private static func verify() {
        let active = Typeface.active
        let missing = active.faces.all.filter { UIFont(name: $0, size: 12) == nil }

        guard !missing.isEmpty else {
            print("[Cero] \(active.displayName) registered: \(active.faces.all.joined(separator: ", "))")
            return
        }

        print("[Cero] \(active.displayName) FAILED to load: \(missing.joined(separator: ", "))")
        let available = UIFont.fontNames(forFamilyName: active.displayName)
        print("[Cero] Faces actually available in \(active.displayName): \(available)")
    }
    #endif
}
