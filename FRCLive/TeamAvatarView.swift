import SwiftUI
import UIKit

struct TeamAvatarView: View {
    let avatarURLString: String
    let size: CGFloat

    @State private var loadedImage: UIImage?

    private var cornerRadius: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)

            Group {
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .padding(size * 0.08)
                } else {
                    avatarPlaceholder
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .task(id: avatarURLString) {
            loadedImage = await TeamAvatarImageLoader.load(from: avatarURLString)
        }
    }

    private var avatarPlaceholder: some View {
        Image("FIRST_Vertical_RGB")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .padding(size * 0.16)
    }
}

private enum TeamAvatarImageLoader {
    static func load(from urlString: String) async -> UIImage? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }

        if url.isFileURL {
            return UIImage(contentsOfFile: url.path)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
