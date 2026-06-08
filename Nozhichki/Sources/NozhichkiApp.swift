import SwiftUI
import SpriteKit

@main
struct NozhichkiApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .frame(minWidth: 900, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 700)
    }
}
