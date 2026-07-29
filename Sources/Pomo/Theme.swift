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
    let honeyToken: OKLCHColor
    let tomatoToken: OKLCHColor
    let breakToken: OKLCHColor
    let skyToken: OKLCHColor
    let focusWashToken: OKLCHColor
    let breakWashToken: OKLCHColor

    var canvas: Color { canvasToken.color }
    var surface: Color { surfaceToken.color }
    var raised: Color { raisedToken.color }
    var border: Color { borderToken.color }
    var ink: Color { inkToken.color }
    var muted: Color { mutedToken.color }
    var honey: Color { honeyToken.color }
    var tomato: Color { tomatoToken.color }
    var breakGreen: Color { breakToken.color }
    var sky: Color { skyToken.color }
    var focusWash: Color { focusWashToken.color }
    var breakWash: Color { breakWashToken.color }

    static let light = PomoPalette(
        canvasToken: OKLCHColor(1.000, 0, 0, alpha: 0.02),
        surfaceToken: OKLCHColor(1.000, 0, 0, alpha: 0.18),
        raisedToken: OKLCHColor(1.000, 0, 0, alpha: 0.10),
        borderToken: OKLCHColor(1.000, 0, 0, alpha: 0.34),
        inkToken: OKLCHColor(0.170, 0, 0),
        mutedToken: OKLCHColor(0.500, 0, 0),
        honeyToken: OKLCHColor(0.460, 0.120, 135),
        tomatoToken: OKLCHColor(0.650, 0.175, 145),
        breakToken: OKLCHColor(0.675, 0.145, 145),
        skyToken: OKLCHColor(1.000, 0, 0, alpha: 0.08),
        focusWashToken: OKLCHColor(1.000, 0, 0, alpha: 0.20),
        breakWashToken: OKLCHColor(1.000, 0, 0, alpha: 0.20)
    )

    static let dark = PomoPalette(
        canvasToken: OKLCHColor(0.105, 0.010, 135),
        surfaceToken: OKLCHColor(0.175, 0.020, 135),
        raisedToken: OKLCHColor(0.235, 0.030, 135),
        borderToken: OKLCHColor(0.315, 0.035, 135),
        inkToken: OKLCHColor(0.965, 0.008, 135),
        mutedToken: OKLCHColor(0.710, 0.025, 135),
        honeyToken: OKLCHColor(0.670, 0.120, 135),
        tomatoToken: OKLCHColor(0.700, 0.130, 135),
        breakToken: OKLCHColor(0.770, 0.110, 145),
        skyToken: OKLCHColor(0.290, 0.035, 135),
        focusWashToken: OKLCHColor(0.245, 0.050, 135),
        breakWashToken: OKLCHColor(0.245, 0.045, 145)
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

private struct PomoPaletteEnvironmentKey: EnvironmentKey {
    static let defaultValue = PomoPalette.light
}

extension EnvironmentValues {
    var pomoPalette: PomoPalette {
        get { self[PomoPaletteEnvironmentKey.self] }
        set { self[PomoPaletteEnvironmentKey.self] = newValue }
    }
}

extension View {
    func pomoHelp(_ text: String) -> some View {
        help(text)
            .accessibilityHint(text)
    }
}
