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

    nonisolated struct DisplayedConfirmation: Hashable, Sendable {
        let title: String
        let message: String
        let confirmTitle: String
        let cancelTitle: String
    }

    nonisolated enum Row: Hashable, Sendable {
        case guest(title: String, message: String)
        case signIn(title: String, isEnabled: Bool)
        case account(name: String, username: String)
        case signOut(title: String, confirmation: DisplayedConfirmation)
        case clearSavedData(title: String)
        case clearWatchHistory(title: String)
        case appearance(title: String, options: [DisplayedThemeOption])
        case version(title: String, value: String)
        case attribution(text: String)
    }

    enum AccountState: Equatable {
        case guest
        case signInPending
        case signInFailed
        case signedIn(Account)
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
            let accountState: AccountState
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

    enum SignIn {
        struct Request {}
    }

    enum SignOut {
        struct Request {}
    }
}
