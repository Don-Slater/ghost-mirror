import AppKit
import SwiftUI

private enum GhostReplicaLogo {
    static let fileName = "ghost-mirror-logo-replica"

    static var url: URL? {
        if let bundled = Bundle.main.url(forResource: fileName, withExtension: "png") {
            return bundled
        }
        let devPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/\(fileName).png")
        return FileManager.default.fileExists(atPath: devPath.path) ? devPath : nil
    }

    static var image: NSImage? {
        guard let url else { return nil }
        return NSImage(contentsOf: url)
    }
}

struct GhostMarkView: View {
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            GhostShape()
                .fill(Color.white)
            GhostEyes()
                .fill(Color.black)
        }
        .frame(width: size, height: size)
    }
}

struct GhostLogoView: View {
    var markSize: CGFloat = 88
    var wordmarkSize: CGFloat = 48

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            GhostMarkView(size: markSize)
                .shadow(color: .white.opacity(0.12), radius: 18, y: 4)

            Text("GHOST MIRROR")
                .font(.custom("DINAlternate-Bold", size: wordmarkSize))
                .fontWeight(.heavy)
                .tracking(9)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.90)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .shadow(color: .white.opacity(0.08), radius: 8, y: 2)
        }
        .frame(maxWidth: 760)
    }
}

struct GhostReplicaLogoView: View {
    private var logoImage: NSImage? {
        GhostReplicaLogo.image
    }

    var body: some View {
        Group {
            if let logoImage {
                Image(nsImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .saturation(0)
                    .contrast(1.08)
                    .shadow(color: .white.opacity(0.08), radius: 12, y: 2)
            } else {
                GhostLogoView(markSize: 96, wordmarkSize: 52)
            }
        }
        .frame(width: 780, height: 160)
        .clipped()
        .accessibilityLabel("Ghost Mirror")
    }
}

private struct GhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 120
        let sy = rect.height / 120
        var p = Path()
        p.move(to: CGPoint(x: 60 * sx, y: 7 * sy))
        p.addCurve(
            to: CGPoint(x: 18 * sx, y: 56 * sy),
            control1: CGPoint(x: 34 * sx, y: 7 * sy),
            control2: CGPoint(x: 20 * sx, y: 29 * sy)
        )
        p.addCurve(
            to: CGPoint(x: 4 * sx, y: 101 * sy),
            control1: CGPoint(x: 17 * sx, y: 73 * sy),
            control2: CGPoint(x: 10 * sx, y: 91 * sy)
        )
        p.addCurve(
            to: CGPoint(x: 10 * sx, y: 109 * sy),
            control1: CGPoint(x: 1 * sx, y: 106 * sy),
            control2: CGPoint(x: 5 * sx, y: 112 * sy)
        )
        p.addLine(to: CGPoint(x: 39 * sx, y: 96 * sy))
        p.addCurve(
            to: CGPoint(x: 50 * sx, y: 102 * sy),
            control1: CGPoint(x: 44 * sx, y: 94 * sy),
            control2: CGPoint(x: 47 * sx, y: 96 * sy)
        )
        p.addLine(to: CGPoint(x: 55 * sx, y: 113 * sy))
        p.addCurve(
            to: CGPoint(x: 67 * sx, y: 113 * sy),
            control1: CGPoint(x: 58 * sx, y: 120 * sy),
            control2: CGPoint(x: 64 * sx, y: 120 * sy)
        )
        p.addLine(to: CGPoint(x: 74 * sx, y: 101 * sy))
        p.addCurve(
            to: CGPoint(x: 88 * sx, y: 96 * sy),
            control1: CGPoint(x: 78 * sx, y: 94 * sy),
            control2: CGPoint(x: 83 * sx, y: 93 * sy)
        )
        p.addLine(to: CGPoint(x: 110 * sx, y: 108 * sy))
        p.addCurve(
            to: CGPoint(x: 116 * sx, y: 101 * sy),
            control1: CGPoint(x: 115 * sx, y: 111 * sy),
            control2: CGPoint(x: 120 * sx, y: 106 * sy)
        )
        p.addCurve(
            to: CGPoint(x: 102 * sx, y: 56 * sy),
            control1: CGPoint(x: 110 * sx, y: 91 * sy),
            control2: CGPoint(x: 103 * sx, y: 73 * sy)
        )
        p.addCurve(
            to: CGPoint(x: 60 * sx, y: 7 * sy),
            control1: CGPoint(x: 100 * sx, y: 29 * sy),
            control2: CGPoint(x: 86 * sx, y: 7 * sy)
        )
        p.closeSubpath()
        return p
    }
}

private struct GhostEyes: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 120
        let sy = rect.height / 120
        var p = Path()
        p.addEllipse(in: CGRect(x: 39 * sx, y: 38 * sy, width: 13 * sx, height: 24 * sy))
        p.addEllipse(in: CGRect(x: 68 * sx, y: 38 * sy, width: 13 * sx, height: 24 * sy))
        return p
    }
}
