import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameState = GameState()

    var body: some View {
        ZStack {
            SpriteView(scene: gameState.scene)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top HUD
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { i in
                        PlayerHUD(
                            name: gameState.playerNames[i],
                            percentage: gameState.territories[i],
                            color: gameState.playerColors[i],
                            isActive: gameState.currentPlayer == i,
                            isEliminated: gameState.territories[i] <= 0
                        )
                    }
                }
                .padding(.top, 8)

                Spacer()

                // Bottom bar
                VStack(spacing: 6) {
                    // Status message
                    Text(gameState.statusMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .animation(.easeInOut(duration: 0.2), value: gameState.statusMessage)

                    // Knife info
                    HStack(spacing: 4) {
                        Text(gameState.selectedKnife.name)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 2)

                    // Style selector
                    HStack(spacing: 10) {
                        ForEach(gameState.availableStyles.filter { $0.id == "standard" || $0.id == "spin" }) { style in
                            StyleButton(
                                style: style,
                                isSelected: gameState.selectedStyle?.id == style.id,
                                cooldownLeft: gameState.styleCooldowns[style.id, default: 0]
                            ) {
                                gameState.selectStyle(style)
                            }
                        }
                    }

                    // Selected style stats
                    if let style = gameState.selectedStyle {
                        StyleStatsBar(style: style, knife: gameState.selectedKnife)
                            .padding(.top, 4)
                    }
                }
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            }

            // Turn overlay for AI
            if gameState.currentPlayer != 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(gameState.playerNames[gameState.currentPlayer])'s turn")
                            .font(.caption)
                            .foregroundStyle(gameState.playerColors[gameState.currentPlayer])
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(.black.opacity(0.5))
                            )
                        Spacer()
                    }
                    .padding(.bottom, 100)
                }
                .allowsHitTesting(false)
            }

            if gameState.currentPlayer == 0 && !gameState.isGameOver {
                VStack {
                    Spacer()
                    Text("YOUR TURN")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.black.opacity(0.55)))
                        .overlay(Capsule().strokeBorder(.red.opacity(0.7), lineWidth: 1.5))
                        .shadow(color: .red.opacity(0.35), radius: 8)
                    Spacer().frame(height: 108)
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            if gameState.isGameOver {
                GameOverOverlay(
                    winnerName: gameState.winnerName,
                    winnerColor: gameState.playerColors[
                        gameState.playerNames.firstIndex(of: gameState.winnerName) ?? 0
                    ],
                    playerNames: gameState.playerNames,
                    playerColors: gameState.playerColors,
                    territories: gameState.territories,
                    onPlayAgain: gameState.reset
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: gameState.isGameOver)
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlay: View {
    let winnerName: String
    let winnerColor: Color
    let playerNames: [String]
    let playerColors: [Color]
    let territories: [Double]
    let onPlayAgain: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(winnerName == "You" ? "You win!" : "\(winnerName) wins!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(winnerColor)

                VStack(spacing: 8) {
                    ForEach(0..<playerNames.count, id: \.self) { i in
                        HStack {
                            Text(playerNames[i])
                                .foregroundStyle(playerColors[i])
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("\(Int(territories[i].rounded()))%")
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                        }
                    }
                }
                .frame(width: 220)
                .padding(.vertical, 4)

                Button("Play Again", action: onPlayAgain)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .buttonStyle(.borderedProminent)
                    .tint(winnerColor)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.black.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(winnerColor.opacity(0.8), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 24)
        }
    }
}

// MARK: - Player HUD

struct PlayerHUD: View {
    let name: String
    let percentage: Double
    let color: Color
    let isActive: Bool
    let isEliminated: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isEliminated ? .gray : color)

            Text("\(Int(percentage))%")
                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(isEliminated ? .gray : .white)

            // Territory bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isEliminated ? .gray : color)
                        .frame(width: geo.size.width * max(0, percentage / 100))
                }
            }
            .frame(width: 50, height: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(isActive ? 0.7 : 0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isActive ? color : .clear, lineWidth: 2)
                )
        )
        .opacity(isEliminated ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: percentage)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Style Button

struct StyleButton: View {
    let style: ThrowingStyle
    let isSelected: Bool
    let cooldownLeft: Int
    let action: () -> Void

    private var isOnCooldown: Bool { cooldownLeft > 0 }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    Text(style.icon)
                        .font(.title2)

                    if isOnCooldown {
                        Text("\(cooldownLeft)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Circle().fill(.red.opacity(0.8)))
                            .offset(x: 14, y: -10)
                    }
                }

                Text(style.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(isOnCooldown ? 0.4 : 0.9))
            }
            .frame(width: 64, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.orange.opacity(0.35) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? .orange : .white.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isOnCooldown)
        .opacity(isOnCooldown ? 0.4 : 1.0)
    }
}

// MARK: - Stats Bar

struct StyleStatsBar: View {
    let style: ThrowingStyle
    let knife: Knife

    var body: some View {
        let stats = EffectiveStats(knife: knife, style: style)
        HStack(spacing: 16) {
            StatPip(label: "SPD", value: stats.speed, max: 5, color: .cyan)
            StatPip(label: "RNG", value: stats.range, max: 5, color: .green)
            StatPip(label: "WID", value: stats.cutWidth, max: 5, color: .orange)
            StatPip(label: "PRE", value: stats.precision, max: 5, color: .purple)
        }
    }
}

struct StatPip: View {
    let label: String
    let value: Double
    let max: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 2) {
                ForEach(0..<Int(max), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Double(i) < value ? color : .white.opacity(0.15))
                        .frame(width: 6, height: 8)
                }
            }
        }
    }
}
