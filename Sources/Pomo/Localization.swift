import Foundation

enum AppLanguage {
    static var isRussian: Bool {
        Locale.autoupdatingCurrent.language.languageCode?.identifier == "ru"
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
