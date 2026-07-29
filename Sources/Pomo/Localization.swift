import Foundation

enum AppLanguage {
    private static let supportedLanguages = ["en", "ru"]

    static var identifier: String {
        Bundle.preferredLocalizations(
            from: supportedLanguages,
            forPreferences: Locale.preferredLanguages
        ).first ?? "en"
    }

    static var isRussian: Bool {
        identifier == "ru"
    }

    static var locale: Locale {
        Locale(identifier: isRussian ? "ru_RU" : "en_US")
    }
}

func appText(_ russian: String, _ english: String) -> String {
    AppLanguage.isRussian ? russian : english
}

func appMinutes(_ value: Int) -> String {
    AppLanguage.isRussian ? "\(value) мин" : "\(value) min"
}
