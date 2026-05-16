import SwiftUI

enum FRCLiveLayout {
    static let tabContentHorizontalPadding: CGFloat = 16
    static let tabContentTopPadding: CGFloat = 8
    static let tabContentBottomPadding: CGFloat = 88
}

extension View {
    /// Sekme kök ekranları: başlık, üst bar ikonlarıyla aynı satırda.
    func frcliveTabScreenTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }

    func frcliveTabContentPadding() -> some View {
        padding(.horizontal, FRCLiveLayout.tabContentHorizontalPadding)
            .padding(.top, FRCLiveLayout.tabContentTopPadding)
            .padding(.bottom, FRCLiveLayout.tabContentBottomPadding)
    }
}
