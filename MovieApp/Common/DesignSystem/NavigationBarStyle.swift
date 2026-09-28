import UIKit

enum NavigationBarStyle {
    // Sets fonts only, so iOS keeps its default bar backgrounds and scroll-edge effects.
    static func apply(to navigationBar: UINavigationBar, prefersLargeTitles: Bool) {
        navigationBar.prefersLargeTitles = prefersLargeTitles
        navigationBar.largeTitleTextAttributes = [.font: Typography.largeTitle, .foregroundColor: UIColor.textPrimary]
        navigationBar.titleTextAttributes = [.font: Typography.navigationTitle, .foregroundColor: UIColor.textPrimary]
    }
}
