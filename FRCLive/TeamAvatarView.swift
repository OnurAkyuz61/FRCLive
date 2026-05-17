import SwiftUI

struct TeamAvatarView: View {
    let avatarURLString: String
    let size: CGFloat

    var body: some View {
        Group {
            if let url = URL(string: avatarURLString), !avatarURLString.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color.white
            Image("FIRST_Vertical_RGB")
                .resizable()
                .scaledToFit()
                .padding(size * 0.18)
        }
    }
}
