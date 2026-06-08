import SpriteKit
import SwiftUI

class GameScene: SKScene {
    weak var gameState: GameState?

    private let pizzaRadius: CGFloat = 260
    private var pizzaCenter: CGPoint { CGPoint(x: size.width / 2, y: size.height / 2) }

    // Layers
    private var bgLayer: SKNode!
    private var territoryLayer: SKNode!
    private var toppingLayer: SKNode!
    private var cutLineLayer: SKNode!
    private var effectLayer: SKNode!
    private var knifeLayer: SKNode!
    private var aimLayer: SKNode!

    // Aim
    private var aimLine: SKShapeNode!
    private var aimDot: SKShapeNode!
    private var aimSectorHighlight: SKShapeNode!
    private var aimHitChanceLabel: SKLabelNode!
    private var aimDirection: CGVector = CGVector(dx: 0, dy: 1)
    private var isThrowInProgress = false

    // Knife
    private var knifeBody: SKShapeNode!

    // Territory: 120 sectors (3 degrees each) for smooth cuts
    private var sectorOwnership: [Int]
    private let sectorCount = 120
    private var sectorNodes: [SKShapeNode] = []

    // Status
    private var turnIndicator: SKShapeNode!

    // Player movement
    private var playerDots: [SKShapeNode] = []
    private var playerPositions: [CGPoint] = Array(repeating: .zero, count: 4)
    private var pressedKeys: Set<UInt16> = []
    private var lastUpdateTime: TimeInterval = 0
    private var lastTrailTime: TimeInterval = 0
    private var lastMousePosition: CGPoint?
    private let playerMoveSpeed: CGFloat = 150

    private let playerSKColors: [SKColor] = [
        SKColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 0.45),
        SKColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 0.45),
        SKColor(red: 0.2, green: 0.75, blue: 0.35, alpha: 0.45),
        SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 0.45),
    ]

    private let playerStrokeColors: [SKColor] = [
        SKColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.8),
        SKColor(red: 0.3, green: 0.5, blue: 0.95, alpha: 0.8),
        SKColor(red: 0.25, green: 0.8, blue: 0.4, alpha: 0.8),
        SKColor(red: 0.95, green: 0.8, blue: 0.15, alpha: 0.8),
    ]

    override init(size: CGSize) {
        sectorOwnership = Array(repeating: 0, count: 120)
        let per = 120 / 4
        for i in 0..<120 { sectorOwnership[i] = i / per }
        super.init(size: size)
    }

    required init?(coder: NSCoder) {
        sectorOwnership = Array(repeating: 0, count: 120)
        super.init(coder: coder)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.1, blue: 0.08, alpha: 1.0)

        view.window?.acceptsMouseMovedEvents = true
        let ta = NSTrackingArea(rect: view.bounds,
            options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: view, userInfo: nil)
        view.addTrackingArea(ta)
        view.window?.makeFirstResponder(view)

        setupLayers()
        setupPizza()
        buildSectorNodes()
        setupToppings()
        setupCrust()
        setupAim()
        setupKnife()

        turnIndicator = SKShapeNode(circleOfRadius: 8)
        turnIndicator.position = pizzaCenter
        turnIndicator.fillColor = playerSKColors[0].withAlphaComponent(0.8)
        turnIndicator.strokeColor = .white
        turnIndicator.lineWidth = 2
        turnIndicator.zPosition = 55
        addChild(turnIndicator)
        setupPlayerDots()
    }

    // MARK: - Setup

    private func setupLayers() {
        bgLayer = SKNode(); bgLayer.zPosition = 0; addChild(bgLayer)
        territoryLayer = SKNode(); territoryLayer.zPosition = 10; addChild(territoryLayer)
        toppingLayer = SKNode(); toppingLayer.zPosition = 20; addChild(toppingLayer)
        cutLineLayer = SKNode(); cutLineLayer.zPosition = 30; addChild(cutLineLayer)
        effectLayer = SKNode(); effectLayer.zPosition = 40; addChild(effectLayer)
        knifeLayer = SKNode(); knifeLayer.zPosition = 50; addChild(knifeLayer)
        aimLayer = SKNode(); aimLayer.zPosition = 60; addChild(aimLayer)
    }

    private func setupPizza() {
        let shadow = SKShapeNode(circleOfRadius: pizzaRadius + 8)
        shadow.position = CGPoint(x: pizzaCenter.x + 4, y: pizzaCenter.y - 4)
        shadow.fillColor = SKColor(white: 0, alpha: 0.3)
        shadow.strokeColor = .clear
        bgLayer.addChild(shadow)

        let base = SKShapeNode(circleOfRadius: pizzaRadius)
        base.position = pizzaCenter
        base.fillColor = SKColor(red: 0.92, green: 0.82, blue: 0.48, alpha: 1.0)
        base.strokeColor = .clear
        bgLayer.addChild(base)

        let sauce = SKShapeNode(circleOfRadius: pizzaRadius - 15)
        sauce.position = pizzaCenter
        sauce.fillColor = SKColor(red: 0.85, green: 0.35, blue: 0.15, alpha: 0.3)
        sauce.strokeColor = .clear
        bgLayer.addChild(sauce)
    }

    private func buildSectorNodes() {
        sectorNodes.forEach { $0.removeFromParent() }
        sectorNodes.removeAll()
        let sa = (2 * .pi) / CGFloat(sectorCount)

        for i in 0..<sectorCount {
            let a0 = sa * CGFloat(i)
            let a1 = a0 + sa + 0.005

            let path = CGMutablePath()
            path.move(to: .zero)
            path.addArc(center: .zero, radius: pizzaRadius - 2,
                        startAngle: a0, endAngle: a1, clockwise: false)
            path.closeSubpath()

            let node = SKShapeNode(path: path)
            node.position = pizzaCenter
            node.fillColor = playerSKColors[sectorOwnership[i]]
            node.strokeColor = .clear
            territoryLayer.addChild(node)
            sectorNodes.append(node)
        }
        drawBorders()
    }

    private func drawBorders() {
        territoryLayer.children
            .filter { ($0 as? SKShapeNode)?.name == "border" }
            .forEach { $0.removeFromParent() }

        let sa = (2 * .pi) / CGFloat(sectorCount)
        for i in 0..<sectorCount {
            let next = (i + 1) % sectorCount
            if sectorOwnership[i] != sectorOwnership[next] {
                let angle = sa * CGFloat(next)
                let path = CGMutablePath()
                path.move(to: CGPoint(
                    x: pizzaCenter.x + cos(angle) * 15,
                    y: pizzaCenter.y + sin(angle) * 15))
                path.addLine(to: CGPoint(
                    x: pizzaCenter.x + cos(angle) * (pizzaRadius - 5),
                    y: pizzaCenter.y + sin(angle) * (pizzaRadius - 5)))
                let border = SKShapeNode(path: path)
                border.name = "border"
                border.strokeColor = SKColor(white: 1, alpha: 0.25)
                border.lineWidth = 1.5
                border.lineCap = .round
                territoryLayer.addChild(border)
            }
        }
    }

    private func refreshTerritoryVisuals() {
        for i in 0..<sectorCount {
            sectorNodes[i].fillColor = playerSKColors[sectorOwnership[i]]
        }
        drawBorders()
        syncPercentages()
    }

    private func syncPercentages() {
        guard let gs = gameState else { return }
        var c = [0, 0, 0, 0]
        for o in sectorOwnership { c[o] += 1 }
        DispatchQueue.main.async {
            for i in 0..<4 { gs.territories[i] = Double(c[i]) / Double(self.sectorCount) * 100 }
        }
    }

    private func setupToppings() {
        for _ in 0..<10 {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let d = CGFloat.random(in: 50...pizzaRadius * 0.8)
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 12...18))
            dot.position = CGPoint(x: pizzaCenter.x + cos(a) * d, y: pizzaCenter.y + sin(a) * d)
            dot.fillColor = SKColor(red: 0.65, green: 0.12, blue: 0.08, alpha: 0.5)
            dot.strokeColor = SKColor(red: 0.5, green: 0.1, blue: 0.05, alpha: 0.3)
            dot.lineWidth = 1
            toppingLayer.addChild(dot)
        }
        for _ in 0..<6 {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let d = CGFloat.random(in: 40...pizzaRadius * 0.75)
            let m = SKShapeNode(ellipseOf: CGSize(width: 16, height: 10))
            m.position = CGPoint(x: pizzaCenter.x + cos(a) * d, y: pizzaCenter.y + sin(a) * d)
            m.fillColor = SKColor(red: 0.85, green: 0.8, blue: 0.65, alpha: 0.4)
            m.strokeColor = SKColor(red: 0.7, green: 0.6, blue: 0.45, alpha: 0.3)
            m.zRotation = CGFloat.random(in: 0...(2 * .pi))
            toppingLayer.addChild(m)
        }
        for _ in 0..<5 {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let d = CGFloat.random(in: 30...pizzaRadius * 0.85)
            let o = SKShapeNode(circleOfRadius: 8)
            o.position = CGPoint(x: pizzaCenter.x + cos(a) * d, y: pizzaCenter.y + sin(a) * d)
            o.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.1, alpha: 0.35)
            o.strokeColor = .clear
            toppingLayer.addChild(o)
            let hole = SKShapeNode(circleOfRadius: 3)
            hole.fillColor = SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 0.4)
            hole.strokeColor = .clear
            o.addChild(hole)
        }
    }

    private func setupCrust() {
        let crust = SKShapeNode(circleOfRadius: pizzaRadius)
        crust.position = pizzaCenter
        crust.fillColor = .clear
        crust.strokeColor = SKColor(red: 0.78, green: 0.6, blue: 0.28, alpha: 1.0)
        crust.lineWidth = 12
        crust.glowWidth = 2
        bgLayer.addChild(crust)

        let inner = SKShapeNode(circleOfRadius: pizzaRadius - 10)
        inner.position = pizzaCenter
        inner.fillColor = .clear
        inner.strokeColor = SKColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 0.4)
        inner.lineWidth = 1
        bgLayer.addChild(inner)
    }

    private func setupAim() {
        aimLine = SKShapeNode()
        aimLine.strokeColor = .white
        aimLine.lineWidth = 2
        aimLine.alpha = 0.7
        aimLayer.addChild(aimLine)

        aimDot = SKShapeNode()
        aimDot.alpha = 0.8
        aimLayer.addChild(aimDot)
        aimSectorHighlight = SKShapeNode()
        aimSectorHighlight.alpha = 0
        aimSectorHighlight.zPosition = -1
        aimLayer.addChild(aimSectorHighlight)

        aimHitChanceLabel = SKLabelNode()
        aimHitChanceLabel.fontName = "HelveticaNeue-Bold"
        aimHitChanceLabel.fontSize = 13
        aimHitChanceLabel.alpha = 0
        aimHitChanceLabel.zPosition = 2
        aimLayer.addChild(aimHitChanceLabel)

    }

    private func setupKnife() {
        let blade = CGMutablePath()
        blade.move(to: CGPoint(x: 0, y: 20))
        blade.addLine(to: CGPoint(x: -4, y: 0))
        blade.addLine(to: CGPoint(x: -3, y: -12))
        blade.addLine(to: CGPoint(x: 0, y: -18))
        blade.addLine(to: CGPoint(x: 3, y: -12))
        blade.addLine(to: CGPoint(x: 4, y: 0))
        blade.closeSubpath()

        knifeBody = SKShapeNode(path: blade)
        knifeBody.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1.0)
        knifeBody.strokeColor = SKColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0)
        knifeBody.lineWidth = 1
        knifeBody.isHidden = true
        knifeBody.setScale(1.2)
        knifeLayer.addChild(knifeBody)
    }

    private func setupPlayerDots() {
        playerDots.forEach { $0.removeFromParent() }
        playerDots.removeAll()

        resetPlayerPositions()

        for player in 0..<4 {
            let dot = SKShapeNode(circleOfRadius: player == 0 ? 7 : 6)
            dot.fillColor = playerStrokeColors[player]
            dot.strokeColor = .white.withAlphaComponent(player == 0 ? 0.9 : 0.45)
            dot.lineWidth = player == 0 ? 2 : 1
            dot.zPosition = 55
            dot.position = playerPositions[player]
            addChild(dot)
            playerDots.append(dot)
        }
    }

    private func resetPlayerPositions() {
        for player in 0..<4 {
            playerPositions[player] = territorySpawnPoint(for: player)
        }
        for player in 0..<min(playerDots.count, playerPositions.count) {
            playerDots[player].position = playerPositions[player]
        }
    }

    private func territorySpawnPoint(for player: Int) -> CGPoint {
        let sa = (2 * .pi) / CGFloat(sectorCount)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var count: CGFloat = 0

        for i in 0..<sectorCount where sectorOwnership[i] == player {
            let angle = sa * (CGFloat(i) + 0.5)
            x += cos(angle)
            y += sin(angle)
            count += 1
        }

        if count == 0 {
            return pizzaCenter
        }

        let targetAngle: CGFloat
        if hypot(x, y) < 0.001 {
            guard let first = sectorOwnership.firstIndex(of: player) else { return pizzaCenter }
            targetAngle = sa * (CGFloat(first) + 0.5)
        } else {
            targetAngle = atan2(y, x)
        }

        var bestSector = sectorOwnership.firstIndex(of: player) ?? 0
        var bestDelta = CGFloat.greatestFiniteMagnitude
        for i in 0..<sectorCount where sectorOwnership[i] == player {
            let angle = sa * (CGFloat(i) + 0.5)
            let delta = abs(shortestAngleDelta(from: targetAngle, to: angle))
            if delta < bestDelta {
                bestDelta = delta
                bestSector = i
            }
        }

        let angle = sa * (CGFloat(bestSector) + 0.5)
        return CGPoint(
            x: pizzaCenter.x + cos(angle) * pizzaRadius * 0.45,
            y: pizzaCenter.y + sin(angle) * pizzaRadius * 0.45
        )
    }

    private func sectorIndex(at point: CGPoint) -> Int? {
        let dx = point.x - pizzaCenter.x
        let dy = point.y - pizzaCenter.y
        guard hypot(dx, dy) <= pizzaRadius - 6 else { return nil }

        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }
        let sa = (2 * .pi) / CGFloat(sectorCount)
        return Int(angle / sa) % sectorCount
    }

    private func isPoint(_ point: CGPoint, inTerritoryOf player: Int) -> Bool {
        guard let sector = sectorIndex(at: point) else { return false }
        return sectorOwnership[sector] == player
    }

    private func pizzaExitPoint(from start: CGPoint, direction: CGVector) -> CGPoint {
        let sx = start.x - pizzaCenter.x
        let sy = start.y - pizzaCenter.y
        let b = sx * direction.dx + sy * direction.dy
        let c = sx * sx + sy * sy - pizzaRadius * pizzaRadius
        let discriminant = max(0, b * b - c)
        let t = -b + sqrt(discriminant)
        return CGPoint(x: start.x + direction.dx * t, y: start.y + direction.dy * t)
    }

    private func addTrailDot(at point: CGPoint, color: SKColor) {
        let trail = SKShapeNode(circleOfRadius: 3)
        trail.position = point
        trail.fillColor = color.withAlphaComponent(0.35)
        trail.strokeColor = .clear
        trail.zPosition = 54
        addChild(trail)
        trail.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.45),
                SKAction.scale(to: 0.25, duration: 0.45)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Input

    override func mouseMoved(with event: NSEvent) {
        guard !isThrowInProgress, gameState?.currentPlayer == 0 else { return }
        lastMousePosition = event.location(in: self)
        updateAimDirection(to: event.location(in: self))
        updateAimVisuals()
    }

    override func mouseDown(with event: NSEvent) {
        guard !isThrowInProgress, gameState?.currentPlayer == 0 else { return }
        lastMousePosition = event.location(in: self)
        updateAimDirection(to: event.location(in: self))
        throwKnife(direction: aimDirection, power: 0.8)
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isThrowInProgress, gameState?.currentPlayer == 0 else { return }
        lastMousePosition = event.location(in: self)
        updateAimDirection(to: event.location(in: self))
        updateAimVisuals()
    }

    override func keyDown(with event: NSEvent) {
        pressedKeys.insert(event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        pressedKeys.remove(event.keyCode)
    }

    private func updateAimDirection(to point: CGPoint) {
        let origin = playerPositions[0]
        let dx = point.x - origin.x, dy = point.y - origin.y
        let len = hypot(dx, dy)
        guard len > 5 else { return }
        aimDirection = CGVector(dx: dx / len, dy: dy / len)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = min(1.0 / 30.0, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        guard gameState?.currentPlayer == 0,
              gameState?.isGameOver != true,
              gameState?.hasStartedGame == true,
              !isThrowInProgress else {
            return
        }

        var move = CGVector(dx: 0, dy: 0)
        if pressedKeys.contains(13) { move.dy += 1 } // W
        if pressedKeys.contains(1) { move.dy -= 1 }  // S
        if pressedKeys.contains(0) { move.dx -= 1 }  // A
        if pressedKeys.contains(2) { move.dx += 1 }  // D

        let len = hypot(move.dx, move.dy)
        guard len > 0 else { return }

        move.dx /= len
        move.dy /= len

        let current = playerPositions[0]
        let step = playerMoveSpeed * CGFloat(dt)
        let proposed = CGPoint(x: current.x + move.dx * step, y: current.y + move.dy * step)

        if isPoint(proposed, inTerritoryOf: 0) {
            playerPositions[0] = proposed
        } else {
            let proposedX = CGPoint(x: current.x + move.dx * step, y: current.y)
            let proposedY = CGPoint(x: current.x, y: current.y + move.dy * step)
            if isPoint(proposedX, inTerritoryOf: 0) {
                playerPositions[0].x = proposedX.x
            }
            if isPoint(proposedY, inTerritoryOf: 0) {
                playerPositions[0].y = proposedY.y
            }
        }

        playerDots[0].position = playerPositions[0]
        if currentTime - lastTrailTime > 0.05 {
            lastTrailTime = currentTime
            addTrailDot(at: playerPositions[0], color: playerStrokeColors[0])
        }

        if let lastMousePosition {
            updateAimDirection(to: lastMousePosition)
            updateAimVisuals()
        }
    }

    private func updateAimVisuals() {
        guard !isThrowInProgress, gameState?.currentPlayer == 0 else {
            aimLine.alpha = 0
            aimDot.alpha = 0
            aimSectorHighlight.alpha = 0
            aimHitChanceLabel.alpha = 0
            return
        }

        aimLine.alpha = 0.7
        aimDot.alpha = 0.8

        // Dashed aim line
        let origin = playerPositions[0]
        let start = CGPoint(
            x: origin.x + aimDirection.dx * 14,
            y: origin.y + aimDirection.dy * 14)
        let end = CGPoint(
            x: origin.x + aimDirection.dx * (pizzaRadius + 20),
            y: origin.y + aimDirection.dy * (pizzaRadius + 20))
        let path = CGMutablePath()
        let total = hypot(end.x - start.x, end.y - start.y)
        var t: CGFloat = 0
        while t < total {
            let t0 = t / total, t1 = min((t + 12) / total, 1)
            path.move(to: CGPoint(x: start.x + (end.x - start.x) * t0, y: start.y + (end.y - start.y) * t0))
            path.addLine(to: CGPoint(x: start.x + (end.x - start.x) * t1, y: start.y + (end.y - start.y) * t1))
            t += 20
        }
        aimLine.path = path

        // Landing indicator arc
        var aimAngle = atan2(aimDirection.dy, aimDirection.dx)
        if aimAngle < 0 { aimAngle += 2 * .pi }
        let arcPath = CGMutablePath()
        arcPath.addArc(center: pizzaCenter, radius: pizzaRadius + 6,
                       startAngle: aimAngle - 0.08, endAngle: aimAngle + 0.08, clockwise: false)
        aimDot.path = arcPath
        aimDot.fillColor = .clear
        aimDot.strokeColor = SKColor(white: 1, alpha: 0.6)
        aimDot.lineWidth = 3

        guard let gs = gameState else {
            aimSectorHighlight.alpha = 0
            aimHitChanceLabel.alpha = 0
            return
        }

        let stats = EffectiveStats(knife: gs.selectedKnife, style: gs.selectedStyle ?? .standard)
        let landingDistance = pizzaRadius * CGFloat(0.3 + stats.range * 0.12) * 0.8
        let landingPoint = CGPoint(
            x: origin.x + aimDirection.dx * landingDistance,
            y: origin.y + aimDirection.dy * landingDistance)
        guard let sector = sectorIndex(at: landingPoint) else {
            aimSectorHighlight.alpha = 0
            aimHitChanceLabel.alpha = 0
            return
        }

        let maxCut = 2 + Int(stats.cutWidth * 2)

        let chordPath = CGMutablePath()
        if let endpoints = chordEndpoints(landingPoint: landingPoint, direction: aimDirection) {
            chordPath.move(to: endpoints.0)
            chordPath.addLine(to: endpoints.1)
        }
        aimSectorHighlight.path = chordPath
        aimSectorHighlight.position = .zero
        aimSectorHighlight.fillColor = .clear
        aimSectorHighlight.strokeColor = playerStrokeColors[gs.currentPlayer].withAlphaComponent(0.45)
        aimSectorHighlight.lineWidth = 2
        aimSectorHighlight.alpha = 1

        let actualClaimSize = computeChordClaimSize(
            landingPoint: landingPoint,
            direction: aimDirection,
            landingSector: sector,
            player: gs.currentPlayer,
            maxCut: maxCut
        )
        let hitChance = computeHitChance(precision: stats.precision, actualClaimSize: actualClaimSize)
        let hitPercent = Int(round(hitChance * 100))
        aimHitChanceLabel.text = "HIT: \(hitPercent)%"
        aimHitChanceLabel.fontColor = hitChance > 0.7
            ? SKColor.systemGreen
            : (hitChance >= 0.4 ? SKColor.systemYellow : SKColor.systemRed)
        aimHitChanceLabel.position = CGPoint(x: landingPoint.x, y: landingPoint.y + 28)
        aimHitChanceLabel.alpha = 1
    }

    // MARK: - Territory Cutting Logic

    /// Find how far (in sectors) from `from` to the nearest sector owned by `player`,
    /// searching in the given direction (+1 = clockwise, -1 = counter-clockwise).
    /// Returns nil if the whole circle is searched without finding one.
    private func distanceToOwned(from sector: Int, player: Int, direction: Int) -> Int? {
        for d in 1..<sectorCount {
            let idx = (sector + d * direction + sectorCount) % sectorCount
            if sectorOwnership[idx] == player { return d }
        }
        return nil
    }

    /// Core mechanic: knife lands at a point, then cuts a chord perpendicular
    /// to the throw direction. The chord expands from the landing sector in
    /// both sector directions, stops at the thrower's territory, and is capped
    /// by maxCut sectors in each direction.
    private func performChordCut(landingPoint: CGPoint, direction: CGVector,
                                 landingSector: Int, player: Int, maxCut: Int) -> (Int, (CGPoint, CGPoint)?) {
        let targets = chordCutSectors(
            landingPoint: landingPoint,
            direction: direction,
            landingSector: landingSector,
            player: player,
            maxCut: maxCut
        )

        var flipped = 0
        for idx in targets where sectorOwnership[idx] != player {
            sectorOwnership[idx] = player
            flipped += 1
        }

        return (flipped, chordEndpoints(landingPoint: landingPoint, direction: direction))
    }

    private func chordCutSectors(landingPoint: CGPoint, direction: CGVector,
                                 landingSector: Int, player: Int, maxCut: Int) -> [Int] {
        guard chordContainsSector(landingPoint: landingPoint, direction: direction, sector: landingSector),
              sectorOwnership[landingSector] != player else {
            return []
        }

        var sectors = [landingSector]

        for dir in [-1, 1] {
            for step in 1...maxCut {
                let idx = (landingSector + dir * step + sectorCount) % sectorCount
                if !chordContainsSector(landingPoint: landingPoint, direction: direction, sector: idx) {
                    break
                }
                if sectorOwnership[idx] == player {
                    break
                }
                sectors.append(idx)
            }
        }

        return sectors
    }

    private func computeChordClaimSize(landingPoint: CGPoint, direction: CGVector,
                                       landingSector: Int, player: Int, maxCut: Int) -> Int {
        chordCutSectors(
            landingPoint: landingPoint,
            direction: direction,
            landingSector: landingSector,
            player: player,
            maxCut: maxCut
        ).count
    }

    private func chordContainsSector(landingPoint: CGPoint, direction: CGVector, sector: Int) -> Bool {
        let dx = landingPoint.x - pizzaCenter.x
        let dy = landingPoint.y - pizzaCenter.y
        let projection = dx * direction.dx + dy * direction.dy
        let ratio = min(1, max(-1, projection / pizzaRadius))
        let halfAngle = acos(ratio)
        let sa = (2 * .pi) / CGFloat(sectorCount)
        let chordAngle = normalizedAngle(atan2(direction.dy, direction.dx))
        let sectorAngle = sa * (CGFloat(sector) + 0.5)
        return abs(shortestAngleDelta(from: chordAngle, to: sectorAngle)) <= halfAngle + sa * 0.5
    }

    private func chordEndpoints(landingPoint: CGPoint, direction: CGVector) -> (CGPoint, CGPoint)? {
        let dx = landingPoint.x - pizzaCenter.x
        let dy = landingPoint.y - pizzaCenter.y
        let projection = dx * direction.dx + dy * direction.dy
        let clampedProjection = min(pizzaRadius - 1, max(-pizzaRadius + 1, projection))
        let halfLength = sqrt(max(0, pizzaRadius * pizzaRadius - clampedProjection * clampedProjection))
        let perp = CGVector(dx: -direction.dy, dy: direction.dx)
        let base = CGPoint(
            x: pizzaCenter.x + direction.dx * clampedProjection,
            y: pizzaCenter.y + direction.dy * clampedProjection
        )

        return (
            CGPoint(x: base.x + perp.dx * halfLength, y: base.y + perp.dy * halfLength),
            CGPoint(x: base.x - perp.dx * halfLength, y: base.y - perp.dy * halfLength)
        )
    }

    private func normalizedAngle(_ angle: CGFloat) -> CGFloat {
        var value = angle
        while value < 0 { value += 2 * .pi }
        while value >= 2 * .pi { value -= 2 * .pi }
        return value
    }

    private func shortestAngleDelta(from a: CGFloat, to b: CGFloat) -> CGFloat {
        var delta = b - a
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        return delta
    }

    private func computeHitChance(precision: Double, actualClaimSize: Int) -> Double {
        let baseHitChance = 0.5 + (precision / 5.0) * 0.3
        let landSizeFactor = max(0.2, 1.0 - Double(actualClaimSize) / 15.0)
        return min(0.95, max(0.15, baseHitChance * landSizeFactor))
    }

    // MARK: - Throwing

    private func throwKnife(direction: CGVector, power: Double = 1.0) {
        guard let gs = gameState else { return }
        isThrowInProgress = true
        aimLine.alpha = 0; aimDot.alpha = 0; aimSectorHighlight.alpha = 0; aimHitChanceLabel.alpha = 0

        let style = gs.selectedStyle ?? .standard
        let stats = EffectiveStats(knife: gs.selectedKnife, style: style)
        let throwSpeed: CGFloat = 300 + CGFloat(stats.speed) * 80
        let player = gs.currentPlayer

        // Precision-based scatter
        let scatter = (1.0 - stats.precision / 5.0) * 0.15
        let angle = atan2(direction.dy, direction.dx) + CGFloat.random(in: -scatter...scatter)
        let dir = CGVector(dx: cos(angle), dy: sin(angle))

        // Landing point: from the current player's position outward.
        let throwDistance = pizzaRadius * CGFloat(0.3 + stats.range * 0.12) * CGFloat(power)
        let startPos = playerPositions[player]
        let landingPt = CGPoint(
            x: startPos.x + dir.dx * throwDistance,
            y: startPos.y + dir.dy * throwDistance)

        // Check if landing is inside pizza
        let landDistFromCenter = hypot(landingPt.x - pizzaCenter.x, landingPt.y - pizzaCenter.y)
        let hitsInside = landDistFromCenter < pizzaRadius

        knifeBody.position = startPos
        knifeBody.zRotation = atan2(dir.dy, dir.dx) - .pi / 2
        knifeBody.isHidden = false
        knifeBody.alpha = 1
        knifeBody.setScale(1.2)

        let target = hitsInside ? landingPt : pizzaExitPoint(from: startPos, direction: dir)

        let dist = hypot(target.x - startPos.x, target.y - startPos.y)
        let dur = max(0.15, Double(dist / throwSpeed))

        let throwAction: SKAction
        let actionDuration: Double
        if style.trajectoryType == .arc {
            actionDuration = dur * 1.2

            let arcPath = CGMutablePath()
            arcPath.move(to: startPos)
            let mid = CGPoint(x: (startPos.x + target.x) * 0.5, y: (startPos.y + target.y) * 0.5)
            let control = CGPoint(x: mid.x + dir.dx * 120, y: mid.y + dir.dy * 120 + 50)
            arcPath.addQuadCurve(to: target, control: control)

            let follow = SKAction.follow(arcPath, asOffset: false, orientToPath: false, duration: actionDuration)
            follow.timingMode = .easeIn
            let scale = SKAction.sequence([
                SKAction.scale(to: 1.75, duration: actionDuration * 0.45),
                SKAction.scale(to: 1.2, duration: actionDuration * 0.55)
            ])
            throwAction = SKAction.group([follow, scale])
        } else {
            actionDuration = dur
            let move = SKAction.move(to: target, duration: dur)
            move.timingMode = .easeOut
            throwAction = move
        }

        var extra = SKAction.wait(forDuration: 0)
        if style.id == "spin" {
            extra = SKAction.rotate(byAngle: .pi * 4, duration: actionDuration)
        }

        turnIndicator.fillColor = playerStrokeColors[player]
        DispatchQueue.main.async { gs.statusMessage = "\(gs.playerNames[player]) throws!" }

        knifeBody.run(SKAction.group([throwAction, extra])) { [weak self] in
            self?.onKnifeLanded(at: target, direction: dir, stats: stats, style: style,
                                player: player, hitInside: hitsInside)
        }

        if power > 0.9 {
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 3, y: -2, duration: 0.03),
                SKAction.moveBy(x: -6, y: 4, duration: 0.03),
                SKAction.moveBy(x: 4, y: -3, duration: 0.03),
                SKAction.moveBy(x: -1, y: 1, duration: 0.03)])
            scene?.run(shake)
        }
    }

    private func onKnifeLanded(at pos: CGPoint, direction: CGVector, stats: EffectiveStats,
                                style: ThrowingStyle, player: Int, hitInside: Bool) {
        guard let gs = gameState else { return }

        // Knife flash
        knifeBody.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)]))

        var flipped = 0

        if hitInside {
            let dx = pos.x - pizzaCenter.x, dy = pos.y - pizzaCenter.y
            var angle = atan2(dy, dx)
            if angle < 0 { angle += 2 * .pi }
            let sa = (2 * .pi) / CGFloat(sectorCount)
            let sectorIdx = Int(angle / sa) % sectorCount

            let maxCut = 2 + Int(stats.cutWidth * 2)
            let actualClaimSize = computeChordClaimSize(
                landingPoint: pos,
                direction: direction,
                landingSector: sectorIdx,
                player: player,
                maxCut: maxCut
            )
            let hitChance = computeHitChance(precision: stats.precision, actualClaimSize: actualClaimSize)
            let didHit = Double.random(in: 0...1) < hitChance


            if didHit {
                let (cut, chord) = performChordCut(
                    landingPoint: pos,
                    direction: direction,
                    landingSector: sectorIdx,
                    player: player,
                    maxCut: maxCut
                )
                flipped = cut
                let successfulHit = flipped > 0
                showCoinFlip(at: pos, didHit: successfulHit)


                if flipped > 0 {
                    refreshTerritoryVisuals()

                    if let chord {
                        drawChordCutLine(from: chord.0, to: chord.1)
                    }
                    emitCutParticles(at: pos, color: playerStrokeColors[player], count: 8 + flipped * 2)
                    spawnSliceLabel(at: pos, flipped: flipped, color: playerStrokeColors[player])
                    let pct = max(1, Int(round(Double(flipped) * 100 / Double(sectorCount))))
                    DispatchQueue.main.async {
                        gs.statusMessage = "\(gs.playerNames[player]) claimed \(pct)%!"
                    }
                } else {
                    emitMissParticles(at: pos)
                    spawnMissLabel(at: pos, delay: 0.65)
                    DispatchQueue.main.async {
                        gs.statusMessage = "\(gs.playerNames[player]) missed their cut!"
                    }
                }
            } else {
                emitMissParticles(at: pos)
                showCoinFlip(at: pos, didHit: false)
                spawnMissLabel(at: pos, delay: 0.65)
                DispatchQueue.main.async {
                    gs.statusMessage = "\(gs.playerNames[player]) missed their cut!"
                }
            }
        } else {
            // Missed the pizza entirely
            emitMissParticles(at: pos)
            spawnMissLabel(at: pos, delay: 0)
            DispatchQueue.main.async {
                gs.statusMessage = "\(gs.playerNames[player]) missed their cut!"
            }
        }

        // Fade knife out
        knifeBody.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.5, duration: 0.2)]),
            SKAction.run { [weak self] in
                self?.knifeBody.isHidden = true
                self?.knifeBody.setScale(1.2)
                self?.knifeBody.alpha = 1
            }]))

        // Win check
        var counts = [0, 0, 0, 0]
        for o in sectorOwnership { counts[o] += 1 }
        let alive = counts.filter { $0 > 0 }.count
        if alive == 1 || counts.max()! > sectorCount / 2 {
            let winner = counts.firstIndex(of: counts.max()!)!
            DispatchQueue.main.async {
                gs.statusMessage = winner == 0 ? "You win!" : "\(gs.playerNames[winner]) wins!"
                gs.isGameOver = true
                gs.winnerName = gs.playerNames[winner]
            }
            aimSectorHighlight.alpha = 0
            isThrowInProgress = true
            return
        }

        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            self?.isThrowInProgress = false
            self?.updateAimVisuals()
            DispatchQueue.main.async { gs.nextTurn() }
        }
    }

    private func drawCutLine(from landingPt: CGPoint, borderAngle: CGFloat) {
        let borderR = pizzaRadius * 0.7
        let borderPt = CGPoint(
            x: pizzaCenter.x + cos(borderAngle) * borderR,
            y: pizzaCenter.y + sin(borderAngle) * borderR)

        let cutPath = CGMutablePath()
        cutPath.move(to: landingPt)
        cutPath.addLine(to: borderPt)

        let cutNode = SKShapeNode(path: cutPath)
        cutNode.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 0.5)
        cutNode.lineWidth = 1.5
        cutNode.lineCap = .round
        cutLineLayer.addChild(cutNode)

        // Fade the cut line over time
        cutNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 5),
            SKAction.fadeOut(withDuration: 2),
            SKAction.removeFromParent()]))
    }

    private func drawChordCutLine(from start: CGPoint, to end: CGPoint) {
        let cutPath = CGMutablePath()
        cutPath.move(to: start)
        cutPath.addLine(to: end)

        let cutNode = SKShapeNode(path: cutPath)
        cutNode.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 0.5)
        cutNode.lineWidth = 1.5
        cutNode.lineCap = .round
        cutLineLayer.addChild(cutNode)

        cutNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 5),
            SKAction.fadeOut(withDuration: 2),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnSliceLabel(at pos: CGPoint, flipped: Int, color: SKColor) {
        let claimedPercent = max(1, Int(round(Double(flipped) * 100 / Double(sectorCount))))
        let label = SKLabelNode(text: "SLICE! +\(claimedPercent)%")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = min(28, 22 + CGFloat(flipped))
        label.fontColor = color
        label.position = pos
        label.zPosition = 100
        effectLayer.addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.8),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnMissLabel(at pos: CGPoint, delay: TimeInterval) {
        let label = SKLabelNode(text: "MISS!")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 26
        label.fontColor = SKColor.systemRed
        label.position = pos
        label.zPosition = 100
        label.alpha = 0
        effectLayer.addChild(label)

        label.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.fadeIn(withDuration: 0.05),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.8),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func showCoinFlip(at pos: CGPoint, didHit: Bool) {
        let finalText = didHit ? "HIT" : "MISS"
        let finalColor = didHit ? SKColor.systemGreen : SKColor.systemRed

        let label = SKLabelNode(text: "HIT")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 28
        label.fontColor = SKColor.systemGreen
        label.position = pos
        label.zPosition = 100
        label.setScale(0.9)
        effectLayer.addChild(label)

        var actions: [SKAction] = []
        for i in 0..<8 {
            let text = i.isMultiple(of: 2) ? "HIT" : "MISS"
            let color = i.isMultiple(of: 2) ? SKColor.systemGreen : SKColor.systemRed
            actions.append(SKAction.run {
                label.text = text
                label.fontColor = color
            })
            actions.append(SKAction.scale(to: 1.15, duration: 0.04))
            actions.append(SKAction.scale(to: 0.95, duration: 0.04))
        }

        actions.append(SKAction.run {
            label.text = finalText
            label.fontColor = finalColor
        })
        actions.append(SKAction.scale(to: 1.25, duration: 0.08))
        actions.append(SKAction.scale(to: 1.0, duration: 0.08))
        actions.append(SKAction.wait(forDuration: 0.35))
        actions.append(SKAction.fadeOut(withDuration: 0.2))
        actions.append(SKAction.removeFromParent())

        label.run(SKAction.sequence(actions))
    }

    // MARK: - Particles

    private func emitCutParticles(at pos: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let sz = CGFloat.random(in: 2...5)
            let p = SKShapeNode(rectOf: CGSize(width: sz, height: sz * 1.5), cornerRadius: 1)
            p.position = pos
            p.fillColor = color.withAlphaComponent(0.9)
            p.strokeColor = .clear
            p.zRotation = CGFloat.random(in: 0...(2 * .pi))
            effectLayer.addChild(p)
            let dx = CGFloat.random(in: -120...120), dy = CGFloat.random(in: -120...120)
            let m = SKAction.moveBy(x: dx, y: dy, duration: 0.5); m.timingMode = .easeOut
            p.run(SKAction.group([m, SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.5),
                                  SKAction.fadeOut(withDuration: 0.5), SKAction.scale(to: 0.3, duration: 0.5)])) {
                p.removeFromParent()
            }
        }
        for _ in 0..<4 {
            let c = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...8))
            c.position = pos
            c.fillColor = SKColor(red: 0.95, green: 0.9, blue: 0.5, alpha: 0.8)
            c.strokeColor = .clear
            effectLayer.addChild(c)
            let m = SKAction.moveBy(x: CGFloat.random(in: -40...40), y: CGFloat.random(in: -40...40), duration: 0.4)
            m.timingMode = .easeOut
            c.run(SKAction.group([m, SKAction.fadeOut(withDuration: 0.4)])) { c.removeFromParent() }
        }
    }

    private func emitMissParticles(at pos: CGPoint) {
        for _ in 0..<3 {
            let p = SKShapeNode(circleOfRadius: 2)
            p.position = pos
            p.fillColor = SKColor(white: 0.7, alpha: 0.6)
            p.strokeColor = .clear
            effectLayer.addChild(p)
            p.run(SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20), duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)])) { p.removeFromParent() }
        }
    }

    // MARK: - AI

    func scheduleAITurn() {
        guard gameState?.isGameOver != true else { return }
        run(SKAction.wait(forDuration: Double.random(in: 1.0...1.8))) { [weak self] in self?.performAIThrow() }
    }

    private func performAIThrow() {
        guard let gs = gameState else { return }
        let me = gs.currentPlayer
        turnIndicator.fillColor = playerStrokeColors[me]

        // AI strategy: find the direction where the nearest enemy territory
        // is closest to our border -- maximize the cut
        let sa = (2 * .pi) / CGFloat(sectorCount)
        var bestAngle: CGFloat = CGFloat.random(in: 0...(2 * .pi))
        var bestScore = Int.max

        for i in 0..<sectorCount {
            if sectorOwnership[i] == me { continue }

            // How far is this enemy sector from our territory?
            let cwDist = distanceToOwned(from: i, player: me, direction: 1) ?? sectorCount
            let ccwDist = distanceToOwned(from: i, player: me, direction: -1) ?? sectorCount
            let minDist = min(cwDist, ccwDist)

            // Prefer sectors that are close to our border but deep into enemy territory
            // (small minDist = close to border = small cut, large minDist = big cut but risky)
            // Sweet spot: 3-8 sectors away
            let score = abs(minDist - 5)
            if score < bestScore {
                bestScore = score
                bestAngle = sa * CGFloat(i) + sa / 2
            }
        }

        var moveAngle = bestAngle + .pi
        var bestMoveDelta = CGFloat.greatestFiniteMagnitude
        for i in 0..<sectorCount where sectorOwnership[i] == me {
            let prev = (i - 1 + sectorCount) % sectorCount
            let next = (i + 1) % sectorCount
            guard sectorOwnership[prev] != me || sectorOwnership[next] != me else { continue }

            let angle = sa * (CGFloat(i) + 0.5)
            let delta = abs(shortestAngleDelta(from: bestAngle, to: angle))
            if delta < bestMoveDelta {
                bestMoveDelta = delta
                moveAngle = angle
            }
        }

        let targetPos = CGPoint(
            x: pizzaCenter.x + cos(moveAngle) * pizzaRadius * 0.72,
            y: pizzaCenter.y + sin(moveAngle) * pizzaRadius * 0.72
        )
        let safeTarget = isPoint(targetPos, inTerritoryOf: me) ? targetPos : territorySpawnPoint(for: me)
        let move = SKAction.move(to: safeTarget, duration: 0.45)
        move.timingMode = .easeInEaseOut
        playerDots[me].run(move) { [weak self] in
            guard let self else { return }
            self.playerPositions[me] = safeTarget
            self.addTrailDot(at: safeTarget, color: self.playerStrokeColors[me])

            let throwAngle = bestAngle + CGFloat.random(in: -0.1...0.1)
            let dir = CGVector(dx: cos(throwAngle), dy: sin(throwAngle))
            self.throwKnife(direction: dir, power: Double.random(in: 0.7...1.1))
        }
    }

    func resetGame() {
        sectorOwnership = (0..<sectorCount).map { $0 % 4 }.shuffled()
        buildSectorNodes()
        syncPercentages()
        resetPlayerPositions()
        pressedKeys.removeAll()
        lastUpdateTime = 0
        lastTrailTime = 0

        isThrowInProgress = false
        cutLineLayer.removeAllChildren()
        effectLayer.removeAllChildren()
        aimSectorHighlight.alpha = 0
        aimHitChanceLabel.alpha = 0
        turnIndicator.fillColor = playerSKColors[0].withAlphaComponent(0.8)

        knifeBody.removeAllActions()
        knifeBody.isHidden = true
        knifeBody.alpha = 1
        knifeBody.setScale(1.2)

        updateAimVisuals()
    }
}
