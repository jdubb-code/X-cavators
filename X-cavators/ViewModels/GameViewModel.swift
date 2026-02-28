//
//  GameViewModel.swift
//  X-cavators
//
//  Game state management and game loop coordination
//

import SwiftUI
import QuartzCore
import Combine

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameMode: GameMode

    @Published var rover: Rover
    @Published var joystickInput: CGVector = .zero
    @Published var gameSize: CGSize = .zero
    var worldSize: CGSize = .zero
    @Published var cameraOffset: CGPoint = .zero
    @Published var batteryDepleted: Bool = false
    @Published var artifacts: [Artifact] = []
    @Published var hazards: [Hazard] = []
    @Published var gridWaypoints: [CGPoint] = []
    @Published var currentWaypointIndex: Int = 0
    @Published var discoveredArtifactModalData: Artifact?
    @Published var currentArchaeologyFact: String?
    @Published var coins: Int = 0
    @Published var homeBase: HomeBase?
    @Published var upgrades: [Upgrade] = []
    @Published var damage: Int = 0
    @Published var needsRepair: Bool = false
    @Published var showingTrivia: Bool = false

    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var artifactsInRange: Set<UUID> = []
    private var totalArtifactsDiscovered: Int = 0
    private var rewardedArtifacts: Set<UUID> = []

    // Hazard avoidance state
    private var isStuck: Bool = false
    private var stuckFrameCount: Int = 0
    private var lastValidPosition: CGPoint?
    private var avoidanceWaypoint: CGPoint?
    private let stuckThreshold: Int = 15  // 0.25 seconds at 60 FPS (more sensitive)
    private var isBackingUp: Bool = false
    private var backupFrameCount: Int = 0
    private let backupDuration: Int = 30  // 0.5 seconds backup time

    // Multi-scan state
    private var scanningArtifactID: UUID?
    private var scanWaitFrames: Int = 0
    private let scanWaitDuration: Int = 20  // 0.33 seconds at 60 FPS (very fast scanning)
    private var isRescanningBackup: Bool = false  // Backing up from artifact
    private var isRescanningReturn: Bool = false  // Returning to artifact
    private var rescanArtifactPosition: CGPoint?  // Position of artifact being rescanned

    // Battery state
    private var isReturningToBase: Bool = false
    private let lowBatteryThreshold: CGFloat = 25.0

    let gprDetectionRadius: CGFloat = 60
    let numberOfArtifacts = 30
    let numberOfRocks = 8
    let numberOfPuddles = 6
    let numberOfMudPatches = 6
    let gridSpacing: CGFloat = 50
    let waypointTolerance: CGFloat = 25

    let artifactNames = [
        "Ancient Pottery", "Stone Tool", "Bronze Coin",
        "Arrowhead", "Bone Fragment", "Ceramic Bowl", "Metal Spearhead",
        "Carved Statue", "Gold Ring", "Shell Necklace",
        "Copper Bracelet",
        "Iron Nail", "Jade Amulet",
        "Silver Pendant", "Mosaic Piece",
        "Flint Dagger", "Obsidian Mirror", "Clay Tablet", "Bronze Axe",
        "Ivory Comb", "Terracotta Figurine", "Lapis Lazuli Bead",
        "Woven Basket Fragment", "Iron Sword Hilt", "Amber Pendant",
        "Papyrus Scroll Fragment", "Stone Cylinder Seal",
        "Coral Earring", "Gilded Sarcophagus Lid", "Wooden Amulet"
    ]

    let archaeologyFacts = [
        "Archaeology comes from the Greek words \"archia\", meaning \"ancient things\", and \"logos\", meaning \"theory\" or \"science\".",
        "The oldest known stone tools are 3.3 million years old, discovered in Kenya and predating the earliest known humans.",
        "Pompeii was buried under volcanic ash in 79 AD and remained hidden for nearly 1,700 years until its rediscovery in 1748.",
        "The Rosetta Stone, discovered in 1799, was key to deciphering Egyptian hieroglyphics after being unreadable for over 1,400 years.",
        "King Tutankhamun's tomb, discovered in 1922, contained over 5,000 artifacts and is one of the most intact royal tombs ever found.",
        "Archaeologists use stratigraphy, the study of rock layers, to determine the relative age of artifacts found at dig sites.",
        "The term \"archaeology\" was first used in its modern sense by Danish scholar Christian Jürgensen Thomsen in the 1830s.",
        "Ground-penetrating radar allows archaeologists to \"see\" underground structures without digging, revolutionizing site surveys.",
        "The Great Pyramid of Giza was the world's tallest human-made structure for over 3,800 years, until 1311 AD.",
        "Carbon-14 dating, developed in the 1940s, can determine the age of organic materials up to 50,000 years old.",
        "The Dead Sea Scrolls, discovered in caves between 1947-1956, are among the oldest surviving biblical manuscripts.",
        "Machu Picchu was never found by Spanish conquistadors and remained unknown to the outside world until 1911.",
        "Archaeologists often work with forensic anthropologists, botanists, and chemists to analyze their findings from multiple angles.",
        "The city of Troy, described in Homer's Iliad, was considered mythical until archaeologist Heinrich Schliemann discovered it in 1870.",
        "Underwater archaeology explores shipwrecks and submerged cities, with some sites dating back over 9,000 years."
    ]

    init(gameMode: GameMode) {
        self.gameMode = gameMode
        self.rover = Rover(position: CGPoint(x: 400, y: 400))

        // Initialize shop upgrades
        self.upgrades = [
            Upgrade(id: .gprUpgrade, name: "GPR Upgrade", description: "Increase detection radius", basePrice: 150, icon: "antenna.radiowaves.left.and.right"),
            Upgrade(id: .speedBoost, name: "Speed Boost", description: "Faster rover movement", basePrice: 200, icon: "hare.fill"),
            Upgrade(id: .extraBattery, name: "Extra Battery", description: "Increase battery capacity", basePrice: 300, icon: "battery.100"),
            Upgrade(id: .terrainScanner, name: "Terrain Scanner", description: "See hazards from farther", basePrice: 100, icon: "map.fill"),
            Upgrade(id: .deepDrill, name: "Deep Drill", description: "Scan artifacts faster", basePrice: 250, icon: "wrench.and.screwdriver.fill"),
            Upgrade(id: .armorPlating, name: "Armor Plating", description: "Better obstacle protection", basePrice: 200, icon: "shield.fill"),
            Upgrade(id: .solarPanel, name: "Solar Panel", description: "Reduce battery drain", basePrice: 300, icon: "sun.max.fill")
        ]
    }

    func startGame(size: CGSize) {
        gameSize = size
        worldSize = CGSize(width: size.width * 2, height: size.height * 2)
        let startPosition = CGPoint(x: worldSize.width / 2, y: worldSize.height / 2)
        rover.position = startPosition
        rover.batteryLevel = rover.maxBattery

        // Create home base at starting position
        homeBase = HomeBase(position: startPosition)

        spawnHazards()
        spawnArtifacts()

        if gameMode == .auto {
            generateGridWaypoints()
            currentWaypointIndex = 0
        }

        lastUpdateTime = CACurrentMediaTime()
        startGameLoop()
    }

    private func spawnHazards() {
        hazards.removeAll()
        let margin: CGFloat = 100
        let homeBaseExclusion: CGFloat = 200
        let maxAttempts = 100

        let defs: [(minR: CGFloat, maxR: CGFloat, type: Hazard.HazardType, count: Int)] = [
            (20, 35, .rock,   numberOfRocks),
            (25, 40, .puddle, numberOfPuddles),
            (40, 60, .mud,    numberOfMudPatches)
        ]

        for def in defs {
            for _ in 0..<def.count {
                let radius = CGFloat.random(in: def.minR...def.maxR)
                var position = CGPoint.zero
                var attempts = 0
                repeat {
                    let x = CGFloat.random(in: margin...(worldSize.width - margin))
                    let y = CGFloat.random(in: margin...(worldSize.height - margin))
                    position = CGPoint(x: x, y: y)
                    attempts += 1
                } while attempts < maxAttempts &&
                        (isPositionNearHomeBase(position, exclusionRadius: homeBaseExclusion) ||
                         isHazardOverlapping(position, radius: radius) ||
                         isPositionTooCloseToArtifact(position, minDistance: radius + 60))
                hazards.append(Hazard(position: position, radius: radius, type: def.type))
            }
        }
    }

    private func spawnArtifacts() {
        artifacts.removeAll()
        let margin: CGFloat = 100
        var availableNames = artifactNames.shuffled()

        for index in 0..<numberOfArtifacts {
            var position: CGPoint
            var attempts = 0
            let maxAttempts = 100

            repeat {
                let x = CGFloat.random(in: margin...(worldSize.width - margin))
                let y = CGFloat.random(in: margin...(worldSize.height - margin))
                position = CGPoint(x: x, y: y)
                attempts += 1
            } while attempts < maxAttempts &&
                    (isPositionNearHomeBase(position, exclusionRadius: 150) ||
                     isPositionTooCloseToHazard(position) ||
                     isPositionTooCloseToArtifact(position, minDistance: 70))

            let name = availableNames[index % availableNames.count]
            let isDeep = Bool.random()
            let scansRequired = isDeep ? Int.random(in: 3...5) : 0

            let artifact = Artifact(
                position: position,
                name: name,
                isDeep: isDeep,
                scansRequired: scansRequired
            )
            artifacts.append(artifact)
        }
    }

    private func isPositionNearHomeBase(_ position: CGPoint, exclusionRadius: CGFloat) -> Bool {
        guard let base = homeBase else { return false }
        let dx = position.x - base.position.x
        let dy = position.y - base.position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance < exclusionRadius
    }

    private func isPositionTooCloseToHazard(_ position: CGPoint, bufferZone: CGFloat = 80) -> Bool {
        for hazard in hazards {
            let dx = position.x - hazard.position.x
            let dy = position.y - hazard.position.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < hazard.radius + bufferZone {
                return true
            }
        }
        return false
    }

    // Returns true if position overlaps any already-placed hazard (used during hazard spawning)
    private func isHazardOverlapping(_ position: CGPoint, radius: CGFloat) -> Bool {
        for hazard in hazards {
            let dx = position.x - hazard.position.x
            let dy = position.y - hazard.position.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < radius + hazard.radius + 20 {
                return true
            }
        }
        return false
    }

    // Returns true if position is too close to any already-placed artifact
    private func isPositionTooCloseToArtifact(_ position: CGPoint, minDistance: CGFloat) -> Bool {
        for artifact in artifacts {
            let dx = position.x - artifact.position.x
            let dy = position.y - artifact.position.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < minDistance {
                return true
            }
        }
        return false
    }

    func stopGame() {
        stopGameLoop()
    }

    func resetGame() {
        stopGameLoop()
        artifacts.removeAll()
        hazards.removeAll()
        artifactsInRange.removeAll()
        rewardedArtifacts.removeAll()
        coins = 0
        damage = 0
        needsRepair = false
        batteryDepleted = false
        let startPosition = CGPoint(x: worldSize.width / 2, y: worldSize.height / 2)
        rover.position = startPosition
        rover.velocity = .zero
        rover.batteryLevel = rover.maxBattery
        joystickInput = .zero

        // Reset home base
        homeBase = HomeBase(position: startPosition)

        // Reset hazard avoidance state
        isStuck = false
        stuckFrameCount = 0
        lastValidPosition = nil
        avoidanceWaypoint = nil
        isBackingUp = false
        backupFrameCount = 0

        // Reset multi-scan state
        scanningArtifactID = nil
        scanWaitFrames = 0
        isRescanningBackup = false
        isRescanningReturn = false
        rescanArtifactPosition = nil

        // Reset battery state
        isReturningToBase = false

        // Reset modal state
        showingTrivia = false
        discoveredArtifactModalData = nil
        currentArchaeologyFact = nil
        totalArtifactsDiscovered = 0

        spawnHazards()
        spawnArtifacts()

        if gameMode == .auto {
            generateGridWaypoints()
            currentWaypointIndex = 0
        }

        lastUpdateTime = CACurrentMediaTime()
        startGameLoop()
    }

    func toggleGameMode() {
        // Switch between manual and auto mode
        gameMode = (gameMode == .manual) ? .auto : .manual

        // Reset joystick input
        joystickInput = .zero

        // Reset auto mode state
        if gameMode == .auto {
            generateGridWaypoints()
            currentWaypointIndex = 0
        }

        // Reset hazard avoidance state
        isStuck = false
        stuckFrameCount = 0
        lastValidPosition = nil
        avoidanceWaypoint = nil
        isBackingUp = false
        backupFrameCount = 0

        // Reset multi-scan state
        scanningArtifactID = nil
        scanWaitFrames = 0
        isRescanningBackup = false
        isRescanningReturn = false
        rescanArtifactPosition = nil

        // Reset battery state
        isReturningToBase = false
    }

    private func generateGridWaypoints() {
        gridWaypoints.removeAll()
        let margin = gridSpacing

        // Horizontal pass: scan left to right on each row
        var y = margin
        while y < worldSize.height - margin {
            var x = margin
            while x < worldSize.width - margin {
                gridWaypoints.append(CGPoint(x: x, y: y))
                x += gridSpacing
            }
            y += gridSpacing
        }

        // Vertical pass: scan top to bottom in each column
        var x = margin
        while x < worldSize.width - margin {
            var y = margin
            while y < worldSize.height - margin {
                gridWaypoints.append(CGPoint(x: x, y: y))
                y += gridSpacing
            }
            x += gridSpacing
        }
    }

    private func updateAutoMode() {
        guard gameMode == .auto && !gridWaypoints.isEmpty else { return }
        guard currentWaypointIndex < gridWaypoints.count else {
            joystickInput = .zero
            return
        }

        // Priority 0: Return to home base if battery is low
        if rover.batteryLevel < lowBatteryThreshold {
            isReturningToBase = true
        }

        // Check if we're at home base and fully charged
        if isReturningToBase, let base = homeBase {
            if base.isRoverInRange(rover: rover) && rover.batteryLevel >= getMaxBattery() * 0.95 {
                isReturningToBase = false
            } else {
                // Navigate to home base
                let dx = base.position.x - rover.position.x
                let dy = base.position.y - rover.position.y
                let distance = sqrt(dx * dx + dy * dy)

                if distance > 10 {
                    let direction = CGVector(dx: dx / distance * 1.5, dy: dy / distance * 1.5)
                    joystickInput = direction
                } else {
                    joystickInput = .zero
                }
                return
            }
        }

        // Priority 1: Check if currently on a deep artifact that needs scanning
        if let deepArtifactID = checkForDeepArtifactNeedingScans() {
            if scanningArtifactID == nil {
                // Just discovered artifact that needs scanning
                scanningArtifactID = deepArtifactID
                scanWaitFrames = 0
                isRescanningBackup = false
                isRescanningReturn = false

                // Store artifact position
                if let artifact = artifacts.first(where: { $0.id == deepArtifactID }) {
                    rescanArtifactPosition = artifact.position
                }
            }

            if scanningArtifactID == deepArtifactID {
                // If we just returned to the artifact, stop the return phase
                if isRescanningReturn {
                    isRescanningReturn = false
                    scanWaitFrames = 0
                }

                // Check if artifact is identified
                let artifact = artifacts.first { $0.id == deepArtifactID }
                if artifact?.isIdentified == true {
                    // Finished scanning, move on to next waypoint
                    scanningArtifactID = nil
                    scanWaitFrames = 0
                    isRescanningBackup = false
                    isRescanningReturn = false
                    rescanArtifactPosition = nil
                    // Don't return here - let it continue to waypoint navigation
                } else {
                    // Still needs more scans
                    scanWaitFrames += 1

                    if scanWaitFrames > effectiveScanWaitDuration {
                        // Waited long enough, back up to leave detection radius
                        scanWaitFrames = 0
                        isRescanningBackup = true

                        // Calculate backward direction (away from artifact)
                        if let artifactPos = rescanArtifactPosition {
                            let dx = rover.position.x - artifactPos.x
                            let dy = rover.position.y - artifactPos.y
                            let distance = sqrt(dx * dx + dy * dy)

                            if distance > 0 {
                                // Move backward away from artifact at 5x speed
                                let backwardDirection = CGVector(dx: dx / distance * 5.0, dy: dy / distance * 5.0)
                                joystickInput = backwardDirection
                            }
                        }
                        return
                    }

                    joystickInput = .zero  // Stop moving while scanning
                    return
                }
            }
        } else {
            // Not on artifact anymore
            if isRescanningBackup {
                // Check if artifact was identified while backing up
                if scanningArtifactID != nil {
                    let artifact = artifacts.first { $0.id == scanningArtifactID }
                    if artifact?.isIdentified == true {
                        // Artifact is now identified, stop rescanning
                        scanningArtifactID = nil
                        scanWaitFrames = 0
                        isRescanningBackup = false
                        isRescanningReturn = false
                        rescanArtifactPosition = nil
                    } else {
                        // We've backed up enough, now return to the artifact
                        isRescanningBackup = false
                        isRescanningReturn = true
                    }
                } else {
                    // No artifact being scanned, just stop backing up
                    isRescanningBackup = false
                }
            }

            // If we were scanning but lost the artifact and not in rescan mode, reset
            if !isRescanningReturn && !isRescanningBackup && scanningArtifactID != nil {
                scanningArtifactID = nil
                scanWaitFrames = 0
                rescanArtifactPosition = nil
            }
        }

        // Handle returning to artifact for rescan
        if isRescanningReturn && rescanArtifactPosition != nil && scanningArtifactID != nil {
            // First check if the artifact we're scanning is still unidentified
            let artifact = artifacts.first { $0.id == scanningArtifactID }
            if artifact?.isIdentified == true {
                // Artifact is now identified, stop rescanning
                scanningArtifactID = nil
                scanWaitFrames = 0
                isRescanningBackup = false
                isRescanningReturn = false
                rescanArtifactPosition = nil
                // Fall through to normal navigation
            } else {
                // Still needs scanning, continue returning to it
                let artifactPos = rescanArtifactPosition!
                let dx = artifactPos.x - rover.position.x
                let dy = artifactPos.y - rover.position.y
                let distance = sqrt(dx * dx + dy * dy)

                if distance > 0 {
                    // Move toward artifact at 5x speed
                    let direction = CGVector(dx: dx / distance * 5.0, dy: dy / distance * 5.0)
                    joystickInput = direction
                    return
                }
            }
        }

        // Priority 2: Check if stuck and activate hazard avoidance (but not during rescanning)
        if detectIfStuck() && !isStuck && !isRescanningBackup && !isRescanningReturn {
            isStuck = true
            isBackingUp = true
            backupFrameCount = 0
        }

        // Safety check: if we've been stuck too long, skip to next waypoint (but not during rescanning)
        if isStuck && stuckFrameCount > 120 && !isRescanningBackup && !isRescanningReturn {  // 2 seconds stuck
            currentWaypointIndex += 1
            if currentWaypointIndex >= gridWaypoints.count {
                joystickInput = .zero
                return
            }
            isStuck = false
            stuckFrameCount = 0
            isBackingUp = false
            backupFrameCount = 0
            avoidanceWaypoint = nil
        }

        // Priority 3: Handle avoidance — compute waypoint immediately, no backing up
        if isBackingUp {
            isBackingUp = false
            backupFrameCount = 0
            let target = gridWaypoints[currentWaypointIndex]
            avoidanceWaypoint = calculateAvoidanceWaypoint(targetWaypoint: target)
        }

        // Priority 4: Navigate to avoidance waypoint or normal waypoint
        let targetWaypoint: CGPoint
        if let avoidance = avoidanceWaypoint {
            targetWaypoint = avoidance
            // Check if reached avoidance waypoint
            let dx = targetWaypoint.x - rover.position.x
            let dy = targetWaypoint.y - rover.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < waypointTolerance {
                avoidanceWaypoint = nil
                isStuck = false
                stuckFrameCount = 0
            }
        } else {
            targetWaypoint = gridWaypoints[currentWaypointIndex]
        }

        // Navigate to target waypoint
        let dx = targetWaypoint.x - rover.position.x
        let dy = targetWaypoint.y - rover.position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < waypointTolerance && avoidanceWaypoint == nil {
            // Only advance waypoint if we're at a grid waypoint (not avoidance)
            currentWaypointIndex += 1
            if currentWaypointIndex >= gridWaypoints.count {
                joystickInput = .zero
                return
            }
        } else {
            // Normal speed for regular waypoint navigation
            let direction = CGVector(dx: dx / distance, dy: dy / distance)
            joystickInput = direction
        }
    }

    private func startGameLoop() {
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopGameLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func gameLoop() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        updateGame(deltaTime: deltaTime)
    }

    private func updateGame(deltaTime: Double) {
        // Don't update if needs repair or battery depleted
        if needsRepair || batteryDepleted {
            return
        }

        if gameMode == .auto {
            updateAutoMode()
        }

        let bounds = CGRect(origin: .zero, size: worldSize)
        let oldPosition = rover.position

        let speedMultiplier = getTerrainSpeedMultiplier()
        rover.update(
            joystickInput: joystickInput,
            deltaTime: deltaTime,
            bounds: bounds,
            speedMultiplier: speedMultiplier,
            effectiveMaxSpeed: effectiveMaxSpeed,
            effectiveDrainRate: effectiveBatteryDrain
        )

        if checkObstacleCollision() {
            rover.revertPosition(to: oldPosition)
            rover.velocity = .zero

            // Add damage on collision (manual mode only)
            if gameMode == .manual {
                damage += 10

                // Check if damage reaches 100
                if damage >= 100 {
                    damage = 100
                    needsRepair = true
                    respawnToBase()
                }
            }
        }

        // Recharge battery if at home base
        if let base = homeBase, base.isRoverInRange(rover: rover) {
            rover.recharge(deltaTime: deltaTime, effectiveMaxBattery: getMaxBattery())
        }

        // Detect battery depletion in manual mode
        if gameMode == .manual && rover.batteryLevel <= 0 && !batteryDepleted && !needsRepair {
            batteryDepleted = true
        }

        checkArtifactDetection()
        updateCamera()
    }

    private func updateCamera() {
        let targetX = rover.position.x - gameSize.width / 2
        let targetY = rover.position.y - gameSize.height / 2
        cameraOffset = CGPoint(
            x: max(0, min(worldSize.width  - gameSize.width,  targetX)),
            y: max(0, min(worldSize.height - gameSize.height, targetY))
        )
    }

    private func respawnToBase() {
        guard let base = homeBase else { return }
        rover.position = base.position
        rover.velocity = .zero
        joystickInput = .zero
    }

    private func getTerrainSpeedMultiplier() -> CGFloat {
        for hazard in hazards {
            if !hazard.type.isObstacle && hazard.contains(point: rover.position) {
                return hazard.type.speedMultiplier
            }
        }
        return 1.0
    }

    private func checkObstacleCollision() -> Bool {
        for hazard in hazards {
            if hazard.willCollide(with: rover) {
                return true
            }
        }
        return false
    }

    private func detectIfStuck() -> Bool {
        // Check if rover position hasn't changed significantly
        if let last = lastValidPosition {
            let dx = rover.position.x - last.x
            let dy = rover.position.y - last.y
            let moved = sqrt(dx * dx + dy * dy)

            if moved < 1.0 {  // Barely moved (more sensitive)
                stuckFrameCount += 1
                if stuckFrameCount > stuckThreshold {
                    return true
                }
            } else {
                stuckFrameCount = 0
            }
        }
        lastValidPosition = rover.position
        return false
    }

    private func isCurrentlyInHazard() -> Bool {
        for hazard in hazards where hazard.type.isObstacle {
            if hazard.contains(point: rover.position) {
                return true
            }
        }
        return false
    }

    private func findNearestHazard() -> Hazard? {
        var nearest: Hazard?
        var minDistance = CGFloat.infinity

        for hazard in hazards {
            let dx = hazard.position.x - rover.position.x
            let dy = hazard.position.y - rover.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < minDistance {
                minDistance = distance
                nearest = hazard
            }
        }

        return nearest
    }

    private func distanceToPoint(_ point: CGPoint) -> CGFloat {
        let dx = point.x - rover.position.x
        let dy = point.y - rover.position.y
        return sqrt(dx * dx + dy * dy)
    }

    private func calculateAvoidanceWaypoint(targetWaypoint: CGPoint) -> CGPoint {
        guard let hazard = findNearestHazard() else {
            return targetWaypoint
        }

        // Calculate direction away from hazard center
        let awayFromHazardX = rover.position.x - hazard.position.x
        let awayFromHazardY = rover.position.y - hazard.position.y
        let distFromHazard = sqrt(awayFromHazardX * awayFromHazardX + awayFromHazardY * awayFromHazardY)

        // Normalize direction away from hazard
        let awayDirX = distFromHazard > 0 ? awayFromHazardX / distFromHazard : 0
        let awayDirY = distFromHazard > 0 ? awayFromHazardY / distFromHazard : 0

        // Calculate two perpendicular directions
        let perp1 = CGVector(dx: -awayDirY, dy: awayDirX)
        let perp2 = CGVector(dx: awayDirY, dy: -awayDirX)

        // Offset from the rover's current position — rover slides sideways past the hazard.
        // Buffer = hazard radius + rover half-width + 15 px clearance.
        let offset = hazard.radius + rover.size.width / 2 + 15

        let options = [
            CGPoint(x: rover.position.x + perp1.dx * offset, y: rover.position.y + perp1.dy * offset),
            CGPoint(x: rover.position.x + perp2.dx * offset, y: rover.position.y + perp2.dy * offset),
            CGPoint(x: rover.position.x + (perp1.dx + awayDirX) * offset * 0.8, y: rover.position.y + (perp1.dy + awayDirY) * offset * 0.8),
            CGPoint(x: rover.position.x + (perp2.dx + awayDirX) * offset * 0.8, y: rover.position.y + (perp2.dy + awayDirY) * offset * 0.8),
        ]

        // Pick the option that is closest to target and not in a hazard
        var bestOption = options[0]
        var bestScore = CGFloat.infinity

        for option in options {
            // Skip if this option is inside a hazard
            var inHazard = false
            for h in hazards where h.type.isObstacle {
                let dx = option.x - h.position.x
                let dy = option.y - h.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < h.radius + 15 {  // 15 px safety buffer
                    inHazard = true
                    break
                }
            }

            if !inHazard {
                // Calculate distance to target
                let dx = targetWaypoint.x - option.x
                let dy = targetWaypoint.y - option.y
                let distToTarget = sqrt(dx * dx + dy * dy)

                if distToTarget < bestScore {
                    bestScore = distToTarget
                    bestOption = option
                }
            }
        }

        // Clamp to world bounds
        let clampedX = max(50, min(worldSize.width - 50, bestOption.x))
        let clampedY = max(50, min(worldSize.height - 50, bestOption.y))

        return CGPoint(x: clampedX, y: clampedY)
    }

    private func checkForDeepArtifactNeedingScans() -> UUID? {
        for artifact in artifacts {
            if artifact.isDiscovered &&
               !artifact.isIdentified &&
               artifact.isInRange(of: rover, detectionRadius: effectiveGPRRadius) {
                return artifact.id
            }
        }
        return nil
    }

    private func checkArtifactDetection() {
        var currentlyInRange: Set<UUID> = []

        for index in artifacts.indices {
            let artifact = artifacts[index]
            let inRange = artifact.isInRange(of: rover, detectionRadius: effectiveGPRRadius)

            if inRange {
                currentlyInRange.insert(artifact.id)

                if !artifact.isDiscovered {
                    artifacts[index].isDiscovered = true
                    artifacts[index].scanCount = 1
                    totalArtifactsDiscovered += 1

                    // Trigger modal only in manual mode, every 5 artifacts, if no modal is currently showing
                    if gameMode == .manual && discoveredArtifactModalData == nil && totalArtifactsDiscovered % 5 == 0 {
                        discoveredArtifactModalData = artifacts[index]
                        currentArchaeologyFact = archaeologyFacts.randomElement()
                    }
                } else if !artifactsInRange.contains(artifact.id) {
                    artifacts[index].scanCount += 1
                }
            }

            // Award coins when artifact becomes identified
            if artifacts[index].isIdentified && !rewardedArtifacts.contains(artifact.id) {
                rewardedArtifacts.insert(artifact.id)
                // Award coins based on difficulty: shallow = 10 coins, deep = scansRequired * 10
                let coinReward = artifact.isDeep ? artifact.scansRequired * 10 : 10
                coins += coinReward
            }
        }

        artifactsInRange = currentlyInRange
    }

    func purchaseUpgrade(_ upgradeType: UpgradeType) {
        guard let index = upgrades.firstIndex(where: { $0.id == upgradeType }) else { return }
        let upgrade = upgrades[index]

        // Check if max level reached
        if !upgrade.canUpgrade {
            return
        }

        // Check if user has enough coins
        if coins >= upgrade.price {
            coins -= upgrade.price
            upgrades[index].level += 1
            applyUpgrade(upgradeType)
        }
    }

    private func applyUpgrade(_ upgradeType: UpgradeType) {
        switch upgradeType {
        case .gprUpgrade:
            // Detection radius increased (applied in getter)
            break
        case .speedBoost:
            // Speed increased (applied in getter)
            break
        case .extraBattery:
            // Battery capacity increased (applied immediately)
            let currentPercentage = rover.batteryLevel / rover.maxBattery
            rover.batteryLevel = currentPercentage * getMaxBattery()
            break
        case .terrainScanner:
            // Visual effect only
            break
        case .deepDrill:
            // Scanning speed increased (applied in scan logic)
            break
        case .armorPlating:
            // Protection (visual/gameplay effect)
            break
        case .solarPanel:
            // Battery drain reduced (applied in update)
            break
        }
    }

    // Computed properties for upgrade effects (scale by level)
    var effectiveGPRRadius: CGFloat {
        let baseRadius = gprDetectionRadius
        let level = getUpgradeLevel(.gprUpgrade)
        return baseRadius * (1.0 + CGFloat(level) * 0.5)
    }

    var effectiveMaxSpeed: CGFloat {
        let baseSpeed = rover.maxSpeed
        let level = getUpgradeLevel(.speedBoost)
        return baseSpeed * (1.0 + CGFloat(level) * 0.25)
    }

    func getMaxBattery() -> CGFloat {
        let baseCapacity = rover.maxBattery
        let level = getUpgradeLevel(.extraBattery)
        return baseCapacity * (1.0 + CGFloat(level) * 0.5)
    }

    var effectiveBatteryDrain: CGFloat {
        let baseDrain = rover.batteryDrainRate
        let level = getUpgradeLevel(.solarPanel)
        let reduction = CGFloat(level) * 0.2  // 20% reduction per level
        return baseDrain * max(0.2, 1.0 - reduction)  // Min 20% drain rate
    }

    var effectiveScanWaitDuration: Int {
        let level = getUpgradeLevel(.deepDrill)
        let reduction = Double(level) * 0.2  // 20% faster per level
        return Int(Double(scanWaitDuration) * max(0.2, 1.0 - reduction))  // Min 20% of base time
    }

    private func getUpgradeLevel(_ upgradeType: UpgradeType) -> Int {
        return upgrades.first(where: { $0.id == upgradeType })?.level ?? 0
    }

    func repairRover() {
        let repairCost = 30
        if coins >= repairCost {
            coins -= repairCost
            damage = 0
            needsRepair = false
        }
    }

    func triviaRepairRover() {
        damage = 0
        needsRepair = false
        showingTrivia = false
    }

    func towRoverCoins() {
        guard coins >= 20 else { return }
        coins -= 20
        rescueRover()
    }

    func towRoverTrivia() {
        rescueRover()
    }

    private func rescueRover() {
        guard let base = homeBase else { return }
        rover.position = base.position
        rover.batteryLevel = getMaxBattery() * 0.4
        rover.velocity = .zero
        batteryDepleted = false
        showingTrivia = false
    }

    var canAffordRepair: Bool {
        coins >= 30
    }

    let triviaQuestions: [TriviaQuestion] = [
        TriviaQuestion(
            question: "What ancient Egyptian writing system used pictures and symbols?",
            options: ["Cuneiform", "Hieroglyphics", "Linear B", "Phoenician alphabet"],
            correctAnswerIndex: 1,
            hint: "This writing system was used in temples and tombs and included pictures of animals, people, and objects.",
            funFact: "Hieroglyphics were used for over 3,500 years and remained undeciphered until the Rosetta Stone was found in 1799."
        ),
        TriviaQuestion(
            question: "The ancient city of Pompeii was buried by the eruption of which volcano in 79 AD?",
            options: ["Mount Etna", "Mount Stromboli", "Mount Vesuvius", "Mount Olympus"],
            correctAnswerIndex: 2,
            hint: "This volcano overlooks the Bay of Naples in southern Italy and is still considered active today.",
            funFact: "Pompeii was buried under 4–6 meters of volcanic ash and was not rediscovered until 1748."
        ),
        TriviaQuestion(
            question: "What is the primary hand tool archaeologists use to carefully remove dirt from artifacts?",
            options: ["Hammer and chisel", "Trowel and brush", "Shovel and pickaxe", "Forceps and scalpel"],
            correctAnswerIndex: 1,
            hint: "Think small and precise — one part is used for scraping soil, the other for delicate sweeping.",
            funFact: "The Marshalltown trowel, made since 1890, remains the most popular excavation trowel among field archaeologists."
        ),
        TriviaQuestion(
            question: "What civilization built Machu Picchu around 1450 CE?",
            options: ["The Aztec", "The Maya", "The Inca", "The Olmec"],
            correctAnswerIndex: 2,
            hint: "This South American empire stretched along the Andes mountains and had its capital at Cusco, Peru.",
            funFact: "Machu Picchu sat at about 2,430 meters above sea level and was never found by Spanish conquistadors."
        ),
        TriviaQuestion(
            question: "In what modern country is the ancient Sumerian city of Ur located?",
            options: ["Egypt", "Iran", "Turkey", "Iraq"],
            correctAnswerIndex: 3,
            hint: "This country lies between the Tigris and Euphrates rivers — the heart of ancient Mesopotamia.",
            funFact: "Ur was one of the world's earliest cities and is believed by many to be the birthplace of Abraham."
        ),
        TriviaQuestion(
            question: "What dating method uses the decay of radioactive carbon atoms to determine the age of organic material?",
            options: ["Potassium-argon dating", "Thermoluminescence", "Radiocarbon (Carbon-14) dating", "Dendrochronology"],
            correctAnswerIndex: 2,
            hint: "This method only works on things that were once alive, like wood, bone, or charcoal.",
            funFact: "Carbon-14 dating was developed by Willard Libby in the 1940s and can date materials up to about 50,000 years old."
        ),
        TriviaQuestion(
            question: "The Rosetta Stone was the key to deciphering which ancient script?",
            options: ["Cuneiform", "Linear A", "Egyptian Hieroglyphics", "Mayan glyphs"],
            correctAnswerIndex: 2,
            hint: "The stone was found in Egypt and contained the same decree written in three different scripts.",
            funFact: "Jean-François Champollion cracked the hieroglyphic code in 1822 using the Rosetta Stone, which was discovered in 1799."
        ),
        TriviaQuestion(
            question: "In archaeology, what is a 'midden'?",
            options: ["A burial mound", "A stone tool", "A refuse or trash heap", "A ceremonial chamber"],
            correctAnswerIndex: 2,
            hint: "Ancient people left these behind after eating meals or discarding worn-out items.",
            funFact: "Middens are treasure troves for archaeologists, revealing ancient diets, trade networks, and daily life."
        ),
        TriviaQuestion(
            question: "King Tutankhamun's nearly intact tomb was discovered in the Valley of the Kings in which year?",
            options: ["1899", "1912", "1922", "1934"],
            correctAnswerIndex: 2,
            hint: "It was discovered by Howard Carter during the 1920s, a decade famous for Egyptian archaeology.",
            funFact: "Howard Carter found the tomb in 1922. It contained over 5,000 artifacts, including Tutankhamun's famous golden death mask."
        ),
        TriviaQuestion(
            question: "What ancient structure in Wiltshire, England is believed to have been built as early as 3000 BCE?",
            options: ["Avebury", "Stonehenge", "Silbury Hill", "Maiden Castle"],
            correctAnswerIndex: 1,
            hint: "This famous circle of standing stones is one of the most recognized prehistoric monuments in the world.",
            funFact: "Stonehenge's massive sarsen stones were transported from Marlborough Downs, about 25 miles away."
        ),
        TriviaQuestion(
            question: "What is 'stratigraphy' in the context of archaeology?",
            options: [
                "The study of ancient texts",
                "Mapping artifact locations using GPS",
                "Dating sites by the layering order of soil and deposits",
                "Using sonar to detect buried structures"
            ],
            correctAnswerIndex: 2,
            hint: "Think of it like a layer cake — older things are generally found deeper underground.",
            funFact: "Stratigraphic layers follow the law of superposition — deeper layers are generally older, helping archaeologists build timelines."
        ),
        TriviaQuestion(
            question: "The ancient city of Troy, made famous by Homer's Iliad, is located in modern-day which country?",
            options: ["Greece", "Turkey", "Bulgaria", "Lebanon"],
            correctAnswerIndex: 1,
            hint: "The site, called Hisarlik, sits near the northwestern coast of a country that bridges Europe and Asia.",
            funFact: "Heinrich Schliemann excavated the site at Hisarlik in the 1870s and identified it as ancient Troy."
        )
    ]

    deinit {
        MainActor.assumeIsolated {
            stopGameLoop()
        }
    }
}

