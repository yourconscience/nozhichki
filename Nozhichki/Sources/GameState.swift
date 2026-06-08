import SwiftUI
import SpriteKit
import Combine

@MainActor
class GameState: ObservableObject {
    @Published var currentPlayer: Int = 0
    @Published var territories: [Double] = [25, 25, 25, 25]
    @Published var selectedStyle: ThrowingStyle? = .standard
    @Published var styleCooldowns: [String: Int] = [:]
    @Published var availableStyles: [ThrowingStyle] = ThrowingStyle.starterStyles
    @Published var statusMessage: String = "Aim and click to throw"
    @Published var isGameOver: Bool = false
    @Published var winnerName: String = ""

    let playerNames = ["You", "Blue", "Green", "Yellow"]
    let playerColors: [Color] = [.red, .blue, .green, .yellow]
    let selectedKnife: Knife = .kitchen

    lazy var scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 900, height: 700))
        scene.scaleMode = .aspectFill
        scene.gameState = self
        return scene
    }()

    func selectStyle(_ style: ThrowingStyle) {
        selectedStyle = style
    }

    func onCutCompleted(cutter: Int, targetPlayer: Int, percentage: Double) {
        territories[targetPlayer] -= percentage
        territories[cutter] += percentage
        territories = territories.map { max(0, min(100, $0)) }

        // Style cooldowns intentionally disabled for the first playable slice:
        // players should be able to switch styles freely after every throw.

        nextTurn()
    }

    func reset() {
        territories = [25, 25, 25, 25]
        currentPlayer = 0
        styleCooldowns.removeAll()
        isGameOver = false
        winnerName = ""
        statusMessage = "Aim and click to throw"
        scene.resetGame()
    }

    func nextTurn() {
        if isGameOver { return }
        // Decrease all cooldowns
        for key in styleCooldowns.keys {
            styleCooldowns[key] = max(0, (styleCooldowns[key] ?? 0) - 1)
        }

        // Advance to next living player
        for _ in 0..<4 {
            currentPlayer = (currentPlayer + 1) % 4
            if territories[currentPlayer] > 0 { break }
        }

        if currentPlayer != 0 {
            scene.scheduleAITurn()
        }
    }
}
