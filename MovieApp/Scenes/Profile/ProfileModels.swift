enum ProfileModel {
    nonisolated enum Section: Hashable, Sendable {
        case account
        case data
        case preferences
        case about
    }

    nonisolated struct DisplayedThemeOption: Hashable, Sendable {
        let theme: AppTheme
        let title: String
        let isSelected: Bool
    }

    nonisolated enum Row: Hashable, Sendable {
        case guest(title: String, message: String)
        case clearSavedData(title: String)
        case clearWatchHistory(title: String)
        case appearance(title: String, options: [DisplayedThemeOption])
        case version(title: String, value: String)
        case attribution(text: String)
    }

    nonisolated struct DisplayedSection: Hashable, Sendable {
        let section: Section
        let header: String?
        let rows: [Row]
    }

    enum LoadProfile {
        struct Request {}

        struct Response {
            let appInfo: AppInfo
            let theme: AppTheme
        }

        struct ViewData: Equatable {
            let sections: [DisplayedSection]
        }
    }

    enum ChangeAppearance {
        struct Request {
            let theme: AppTheme
        }
    }
}
