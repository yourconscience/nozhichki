import SwiftUI
import SpriteKit

// MARK: - Knife

struct Knife: Identifiable {
    let id: String
    let name: String
    let speed: Int
    let power: Int
    let cutWidth: Int
    let precision: Int
    let passive: String
    let unlockCondition: String

    var isDefault: Bool { id == "kitchen" }
}

extension Knife {
    static let all: [Knife] = [
        Knife(id: "kitchen", name: "Kitchen Knife", speed: 3, power: 3, cutWidth: 3, precision: 3,
              passive: "None", unlockCondition: "Default"),
        Knife(id: "cleaver", name: "Cleaver", speed: 1, power: 5, cutWidth: 5, precision: 2,
              passive: "Cuts stun territory 1 turn", unlockCondition: "Win 3 games"),
        Knife(id: "stiletto", name: "Stiletto", speed: 5, power: 2, cutWidth: 1, precision: 5,
              passive: "+15% critical cut chance", unlockCondition: "Win with >60% territory"),
        Knife(id: "santoku", name: "Santoku", speed: 4, power: 3, cutWidth: 2, precision: 4,
              passive: "Every 3rd cut grants bonus throw", unlockCondition: "Use 5+ styles in a win"),
        Knife(id: "nakiri", name: "Nakiri", speed: 2, power: 4, cutWidth: 4, precision: 2,
              passive: "Topping zones yield +20% area", unlockCondition: "Win without active items"),
    ]

    static let kitchen = all[0]
}

// MARK: - Throwing Style

struct ThrowingStyle: Identifiable {
    let id: String
    let name: String
    let icon: String
    let speed: Int
    let range: Int
    let cutWidth: Int
    let precision: Int
    let cooldown: Int
    let trajectoryType: TrajectoryType
}

enum TrajectoryType {
    case straight
    case arc
    case spiral
    case bounce
    case fan
    case curve
    case instant
}

extension ThrowingStyle {
    static let standard = ThrowingStyle(
        id: "standard", name: "Standard", icon: "🔪",
        speed: 3, range: 4, cutWidth: 2, precision: 4, cooldown: 0,
        trajectoryType: .straight)

    static let spin = ThrowingStyle(
        id: "spin", name: "Spin", icon: "🌀",
        speed: 3, range: 3, cutWidth: 4, precision: 3, cooldown: 0,
        trajectoryType: .straight)

    static let lob = ThrowingStyle(
        id: "lob", name: "Lob", icon: "🎯",
        speed: 2, range: 3, cutWidth: 1, precision: 2, cooldown: 2,
        trajectoryType: .arc)

    static let noSpin = ThrowingStyle(
        id: "nospin", name: "No-Spin", icon: "➡️",
        speed: 4, range: 5, cutWidth: 1, precision: 5, cooldown: 0,
        trajectoryType: .straight)

    static let ricochet = ThrowingStyle(
        id: "ricochet", name: "Ricochet", icon: "💥",
        speed: 4, range: 4, cutWidth: 2, precision: 1, cooldown: 2,
        trajectoryType: .bounce)

    static let fan = ThrowingStyle(
        id: "fan", name: "Fan", icon: "🪭",
        speed: 4, range: 3, cutWidth: 1, precision: 2, cooldown: 3,
        trajectoryType: .fan)

    static let sidearm = ThrowingStyle(
        id: "sidearm", name: "Sidearm", icon: "↪️",
        speed: 4, range: 3, cutWidth: 2, precision: 4, cooldown: 0,
        trajectoryType: .curve)

    static let starterStyles: [ThrowingStyle] = [standard, spin, lob]
    static let allStyles: [ThrowingStyle] = [standard, spin, lob, noSpin, ricochet, fan, sidearm]
}

// MARK: - Effective Stats

struct EffectiveStats {
    let speed: Double
    let range: Double
    let cutWidth: Double
    let precision: Double

    init(knife: Knife, style: ThrowingStyle) {
        self.speed = Double(knife.speed) * 0.6 + Double(style.speed) * 0.4
        self.range = Double(style.range)
        self.cutWidth = Double(knife.cutWidth) * 0.6 + Double(style.cutWidth) * 0.4
        self.precision = Double(knife.precision) * 0.6 + Double(style.precision) * 0.4
    }
}
