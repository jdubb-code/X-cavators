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
    @Published var artifacts: [Artifact] = []
    @Published var hazards: [Hazard] = []
    @Published var gridWaypoints: [CGPoint] = []
    @Published var currentWaypointIndex: Int = 0

    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var artifactsInRange: Set<UUID> = []

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

    let gprDetectionRadius: CGFloat = 60
    let numberOfArtifacts = 15
    let numberOfRocks = 4
    let numberOfPuddles = 3
    let numberOfMudPatches = 3
    let gridSpacing: CGFloat = 50
    let waypointTolerance: CGFloat = 25

    let artifactNames = [
        "Ancient Pottery", "Stone Tool", "Bronze Coin", "Clay Tablet",
        "Arrowhead", "Bone Fragment", "Ceramic Bowl", "Metal Spearhead",
        "Carved Statue", "Gold Ring", "Shell Necklace", "Stone Axe",
        "Copper Bracelet", "Obsidian Blade", "Decorative Tile",
        "Glass Bead", "Iron Nail", "Wooden Carving", "Jade Amulet",
        "Silver Pendant", "Flint Tool", "Mosaic Piece", "Woven Basket"
    ]

    init(gameMode: GameMode) {
        self.gameMode = gameMode
        self.rover = Rover(position: CGPoint(x: 400, y: 400))
    }

    func startGame(size: CGSize) {
        gameSize = size
        rover.position = CGPoint(x: size.width / 2, y: size.height / 2)
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
        let centerExclusion: CGFloat = 150

        for _ in 0..<numberOfRocks {
            var position: CGPoint
            repeat {
                let x = CGFloat.random(in: margin...(gameSize.width - margin))
                let y = CGFloat.random(in: margin...(gameSize.height - margin))
                position = CGPoint(x: x, y: y)
            } while position.distance(to: CGPoint(x: gameSize.width / 2, y: gameSize.height / 2)) < centerExclusion

            let radius = CGFloat.random(in: 20...35)
            let hazard = Hazard(position: position, radius: radius, type: .rock)
            hazards.append(hazard)
        }

        for _ in 0..<numberOfPuddles {
            var position: CGPoint
            repeat {
                let x = CGFloat.random(in: margin...(gameSize.width - margin))
                let y = CGFloat.random(in: margin...(gameSize.height - margin))
                position = CGPoint(x: x, y: y)
            } while position.distance(to: CGPoint(x: gameSize.width / 2, y: gameSize.height / 2)) < centerExclusion

            let radius = CGFloat.random(in: 25...40)
            let hazard = Hazard(position: position, radius: radius, type: .puddle)
            hazards.append(hazard)
        }

        for _ in 0..<numberOfMudPatches {
            var position: CGPoint
            repeat {
                let x = CGFloat.random(in: margin...(gameSize.width - margin))
                let y = CGFloat.random(in: margin...(gameSize.height - margin))
                position = CGPoint(x: x, y: y)
            } while position.distance(to: CGPoint(x: gameSize.width / 2, y: gameSize.height / 2)) < centerExclusion

            let radius = CGFloat.random(in: 40...60)
            let hazard = Hazard(position: position, radius: radius, type: .mud)
            hazards.append(hazard)
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
                let x = CGFloat.random(in: margin...(gameSize.width - margin))
                let y = CGFloat.random(in: margin...(gameSize.height - margin))
                position = CGPoint(x: x, y: y)
                attempts += 1
            } while isPositionTooCloseToHazard(position) && attempts < maxAttempts

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

    private func isPositionTooCloseToHazard(_ position: CGPoint, bufferZone: CGFloat = 80) -> Bool {
        for hazard in hazards {
            let dx = position.x - hazard.position.x
            let dy = position.y - hazard.position.y
            let distance = sqrt(dx * dx + dy * dy)

            // Buffer = hazard radius + buffer zone
            let minimumDistance = hazard.radius + bufferZone

            if distance < minimumDistance {
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
        rover.position = CGPoint(x: gameSize.width / 2, y: gameSize.height / 2)
        rover.velocity = .zero
        joystickInput = .zero

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
    }

    private func generateGridWaypoints() {
        gridWaypoints.removeAll()
        let margin = gridSpacing

        // Horizontal pass: scan left to right on each row
        var y = margin
        while y < gameSize.height - margin {
            var x = margin
            while x < gameSize.width - margin {
                gridWaypoints.append(CGPoint(x: x, y: y))
                x += gridSpacing
            }
            y += gridSpacing
        }

        // Vertical pass: scan top to bottom in each column
        var x = margin
        while x < gameSize.width - margin {
            var y = margin
            while y < gameSize.height - margin {
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

                    if scanWaitFrames > scanWaitDuration {
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

        // Priority 3: Handle backup phase when stuck
        if isBackingUp {
            backupFrameCount += 1

            if backupFrameCount < backupDuration {
                // Back away from nearest hazard
                if let hazard = findNearestHazard() {
                    let awayX = rover.position.x - hazard.position.x
                    let awayY = rover.position.y - hazard.position.y
                    let dist = sqrt(awayX * awayX + awayY * awayY)

                    if dist > 0 {
                        // Move away from hazard at high speed
                        let backupDirection = CGVector(dx: (awayX / dist) * 2.0, dy: (awayY / dist) * 2.0)
                        joystickInput = backupDirection
                        return
                    }
                }
            } else {
                // Finished backing up, now calculate avoidance waypoint
                isBackingUp = false
                backupFrameCount = 0
                let target = gridWaypoints[currentWaypointIndex]
                avoidanceWaypoint = calculateAvoidanceWaypoint(targetWaypoint: target)
            }
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
        if gameMode == .auto {
            updateAutoMode()
        }

        let bounds = CGRect(origin: .zero, size: gameSize)
        let oldPosition = rover.position

        let speedMultiplier = getTerrainSpeedMultiplier()
        rover.update(joystickInput: joystickInput, deltaTime: deltaTime, bounds: bounds, speedMultiplier: speedMultiplier)

        if checkObstacleCollision() {
            rover.revertPosition(to: oldPosition)
            rover.velocity = .zero
        }

        checkArtifactDetection()
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

        // Much larger offset to ensure we're well clear of hazards
        let baseOffset = hazard.radius + rover.size.width + 80

        // Try multiple options: perpendicular directions and diagonal combinations
        let options = [
            CGPoint(x: rover.position.x + perp1.dx * baseOffset, y: rover.position.y + perp1.dy * baseOffset),
            CGPoint(x: rover.position.x + perp2.dx * baseOffset, y: rover.position.y + perp2.dy * baseOffset),
            CGPoint(x: rover.position.x + (perp1.dx + awayDirX) * baseOffset * 0.7, y: rover.position.y + (perp1.dy + awayDirY) * baseOffset * 0.7),
            CGPoint(x: rover.position.x + (perp2.dx + awayDirX) * baseOffset * 0.7, y: rover.position.y + (perp2.dy + awayDirY) * baseOffset * 0.7)
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
                if dist < h.radius + 20 {  // Add small buffer
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

        // Clamp to screen bounds
        let clampedX = max(50, min(gameSize.width - 50, bestOption.x))
        let clampedY = max(50, min(gameSize.height - 50, bestOption.y))

        return CGPoint(x: clampedX, y: clampedY)
    }

    private func checkForDeepArtifactNeedingScans() -> UUID? {
        for artifact in artifacts {
            if artifact.isDiscovered &&
               !artifact.isIdentified &&
               artifact.isInRange(of: rover, detectionRadius: gprDetectionRadius) {
                return artifact.id
            }
        }
        return nil
    }

    private func checkArtifactDetection() {
        var currentlyInRange: Set<UUID> = []

        for index in artifacts.indices {
            let artifact = artifacts[index]
            let inRange = artifact.isInRange(of: rover, detectionRadius: gprDetectionRadius)

            if inRange {
                currentlyInRange.insert(artifact.id)

                if !artifact.isDiscovered {
                    artifacts[index].isDiscovered = true
                    artifacts[index].scanCount = 1
                } else if !artifactsInRange.contains(artifact.id) {
                    artifacts[index].scanCount += 1
                }
            }
        }

        artifactsInRange = currentlyInRange
    }

    @MainActor deinit {
        stopGameLoop()
    }
}

