import AppKit
import SwiftUI

struct OKLCHColor: Sendable {
    let lightness: Double
    let chroma: Double
    let hue: Double
    let alpha: Double

    init(_ lightness: Double, _ chroma: Double, _ hue: Double, alpha: Double = 1) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
        self.alpha = alpha
    }

    var nsColor: NSColor {
        let angle = hue * .pi / 180
        let a = chroma * cos(angle)
        let b = chroma * sin(angle)

        let lPrime = lightness + 0.396_337_777_4 * a + 0.215_803_757_3 * b
        let mPrime = lightness - 0.105_561_345_8 * a - 0.063_854_172_8 * b
        let sPrime = lightness - 0.089_484_177_5 * a - 1.291_485_548 * b

        let l = lPrime * lPrime * lPrime
        let m = mPrime * mPrime * mPrime
        let s = sPrime * sPrime * sPrime

        let linearRed = 4.076_741_662_1 * l - 3.307_711_591_3 * m + 0.230_969_929_2 * s
        let linearGreen = -1.268_438_004_6 * l + 2.609_757_401_1 * m - 0.341_319_396_5 * s
        let linearBlue = -0.004_196_086_3 * l - 0.703_418_614_7 * m + 1.707_614_701 * s

        func encode(_ component: Double) -> Double {
            let encoded: Double
            if component <= 0.003_130_8 {
                encoded = 12.92 * component
            } else {
                encoded = 1.055 * pow(component, 1 / 2.4) - 0.055
            }
            return min(max(encoded, 0), 1)
        }

        return NSColor(
            srgbRed: encode(linearRed),
            green: encode(linearGreen),
            blue: encode(linearBlue),
            alpha: alpha
        )
    }

    var color: Color {
        Color(nsColor: nsColor)
    }
}

struct PomoPalette: Sendable {
    let canvasToken: OKLCHColor
    let surfaceToken: OKLCHColor
    let raisedToken: OKLCHColor
    let borderToken: OKLCHColor
    let inkToken: OKLCHColor
    let mutedToken: OKLCHColor
    let focusAccentToken: OKLCHColor
    let restAccentToken: OKLCHColor
    let focusWashToken: OKLCHColor
    let breakWashToken: OKLCHColor

    var canvas: Color { canvasToken.color }
    var surface: Color { surfaceToken.color }
    var raised: Color { raisedToken.color }
    var border: Color { borderToken.color }
    var ink: Color { inkToken.color }
    var muted: Color { mutedToken.color }
    var focusAccent: Color { focusAccentToken.color }
    var restAccent: Color { restAccentToken.color }
    var onFocusAccent: Color { accentForeground(for: focusAccentToken) }
    var onRestAccent: Color { accentForeground(for: restAccentToken) }
    var focusWash: Color { focusWashToken.color }
    var breakWash: Color { breakWashToken.color }

    private func accentForeground(for token: OKLCHColor) -> Color {
        token.lightness >= 0.62
            ? OKLCHColor(0.180, 0.008, 265).color
            : .white
    }

    static let light = PomoPalette(
        canvasToken: OKLCHColor(0.975, 0.004, 255),
        surfaceToken: OKLCHColor(0.995, 0.002, 255),
        raisedToken: OKLCHColor(0.935, 0.008, 255),
        borderToken: OKLCHColor(0.820, 0.010, 255),
        inkToken: OKLCHColor(0.170, 0.012, 265),
        mutedToken: OKLCHColor(0.430, 0.012, 265),
        focusAccentToken: OKLCHColor(0.575, 0.205, 29),
        restAccentToken: OKLCHColor(0.535, 0.165, 250),
        focusWashToken: OKLCHColor(0.930, 0.045, 29),
        breakWashToken: OKLCHColor(0.925, 0.040, 250)
    )

    static let dark = PomoPalette(
        canvasToken: OKLCHColor(0.130, 0.010, 265),
        surfaceToken: OKLCHColor(0.185, 0.014, 265),
        raisedToken: OKLCHColor(0.245, 0.016, 265),
        borderToken: OKLCHColor(0.350, 0.018, 265),
        inkToken: OKLCHColor(0.965, 0.004, 255),
        mutedToken: OKLCHColor(0.720, 0.010, 255),
        focusAccentToken: OKLCHColor(0.720, 0.175, 29),
        restAccentToken: OKLCHColor(0.745, 0.135, 250),
        focusWashToken: OKLCHColor(0.260, 0.060, 29),
        breakWashToken: OKLCHColor(0.260, 0.050, 250)
    )
}

extension PomoThemeMode {
    var palette: PomoPalette {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}

extension EnvironmentValues {
    @Entry var pomoPalette = PomoPalette.light
    @Entry var pomoReduceMotionOverride: Bool?
}

extension View {
    func pomoHelp(_ text: String) -> some View {
        help(text)
            .accessibilityHint(text)
    }
}
