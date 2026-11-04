import SwiftUI
import UIKit

private let cols = 9
private let rows = 12
private let mineCost = 200
private let buildFundFillSpeed: Float = 24
private let tankReward = 80
private let robotReward = 80
private let mineDamage: Float = 200
private let mineSpreadDamage: Float = 100
private let mineSpreadRadius: Float = 1.55
private let autoWaveDelay: Float = 10
private let screenSaverDelay: TimeInterval = 30
private let lockPausesGame = false
private let wavesPerStage = 30
private let stageCount = 30
private let mineMaxLevel = 5
private let towerMaxLevel = 10
private let upgradeMaxLevel = 7
private let baseMaxLevel = 10
private let laserRampSeconds: Float = 2.4
private let auraReach: Float = 2.2
private let empReach: Float = 1.4
private let bossEmpSlow: Float = 0.4
private let bossPaceCap: Float = 2.2
private func bossHealth(_ stage: Int) -> Float {
    let creep = Float(10 + wavesPerStage * 6) * (1 + Float(max(1, stage) - 1) * 0.25)
    return creep * 6.5
}
private func towerMaxHealth(_ level: Int) -> Float { 100 + Float(max(0, level - 1)) * 50 }
private let robotBoardReach: Float = 1.5
private let robotDrainPerSecond: Float = 20
private let tankCounterPause: Float = 0.65
private let tankPace: Float = 0.35
private let robotPace: Float = 0.4

private struct StageMap {
    let routes: [[(Int, Int)]]
    let home: (Int, Int)

    init(_ routes: [[(Int, Int)]]) {
        self.routes = routes
        self.home = routes[0].last!
    }

    func contains(column: Int, row: Int) -> Bool {
        routes.contains { route in route.contains { $0.0 == column && $0.1 == row } }
    }
}

enum WeaponKind: CaseIterable, Hashable {
    case basic, shotgun, laser, bomb, emp, poison

    var label: String { GameCopy.current.weaponLabel(self) }
}

enum EnemyKind {
    case normal, dog, robot, tank, ufo
}

private func levelColor(_ level: Int) -> Color {
    switch min(max(level, 1), baseMaxLevel) {
    case 1: return Color(hex: 0xF8FAFC)
    case 2: return Color(hex: 0x4ADE80)
    case 3: return Color(hex: 0x38BDF8)
    case 4: return Color(hex: 0xC084FC)
    case 5: return Color(hex: 0xFBBF24)
    case 6: return Color(hex: 0xF472B6)
    case 7: return Color(hex: 0xF43F5E)
    case 8: return Color(hex: 0xFB923C)
    case 9: return Color(hex: 0x2DD4BF)
    default: return Color(hex: 0xFDE047)
    }
}

private func upgradeSeconds(_ level: Int) -> Float {
    let seconds = 2.25 * pow(2, Float(level - 1))
    return level >= 7 ? seconds / 2 : seconds
}

private func towerCost(_ kind: WeaponKind) -> Int {
    switch kind {
    case .basic: return 25
    case .shotgun: return 40
    case .laser: return 50
    case .bomb: return 70
    case .emp: return 40
    case .poison: return 35
    }
}

private func towerUpgradeCost(_ kind: WeaponKind, _ level: Int) -> Int {
    Int((Float(towerCost(kind)) * (0.6 + 0.2 * Float(max(0, level - 1)))).rounded())
}

private func investedCost(_ kind: WeaponKind, _ level: Int) -> Int {
    var total = towerCost(kind)
    if level > 1 {
        for step in 1..<level { total += towerUpgradeCost(kind, step) }
    }
    return total
}

private func powerOf(_ kind: WeaponKind, _ level: Int) -> Float {
    let steps = Float(max(0, level - 1))
    switch kind {
    case .basic: return 1 + steps
    case .shotgun: return 1 + steps * 0.3
    case .laser: return 1 + steps * 0.3
    case .bomb: return 1.6 + steps * 0.35
    case .emp: return 1 + steps * 0.3
    case .poison: return 1 + steps * 0.3
    }
}
private func minePower(_ level: Int) -> Float { 1 + Float(max(0, level - 1)) * 0.5 }
private let startingMineStock = 20
private func startingGold(_ stage: Int) -> Int {
    150 + (max(1, stage) - 1) * 30
}
private func mineUpgradeCost(_ level: Int) -> Int { (20 + level * 15) * 4 }
private func mineHitDamage(_ level: Int) -> Float { mineDamage * minePower(level) }
private func mineSplashDamage(_ level: Int) -> Float { mineSpreadDamage * minePower(level) }
private func mineSplashRadius(_ level: Int) -> Float { mineSpreadRadius + Float(level - 1) * 0.1 }

private func reachOf(_ kind: WeaponKind, _ level: Int) -> Float {
    let base: Float
    switch kind {
    case .basic: base = 2.6
    case .shotgun: base = 2.15
    case .laser: base = 3.15
    case .bomb: base = 2.8
    case .emp: base = empReach
    case .poison: base = auraReach
    }
    return base * (1 + Float(max(0, level - 1)) * 0.08)
}

private func fireCooldown(_ kind: WeaponKind, _ level: Int) -> Float {
    let base: Float
    switch kind {
    case .basic: base = 0.24
    case .shotgun: base = 0.62
    case .laser: base = 0
    case .bomb: base = 1.2
    case .emp: return max(0.42, 0.72 - Float(level - 1) * 0.01) * 3
    case .poison: base = 0.72
    }
    return base * (1 - Float(level - 1) * 0.025)
}

private func empStun(_ level: Int) -> Float { 0.42 + Float(level - 1) * 0.02 }
private let poisonDuration: Float = 2.2
private let poisonSlow: Float = 0.58

private func tankBudget(stage: Int, wave: Int) -> Int {
    max(1, wave / 8)
}

private func creepKind(stage: Int, index: Int) -> EnemyKind {
    switch stage {
    case 1: return .normal
    case 2: return .dog
    case 3: return index % 3 == 0 ? .tank : .normal
    case 4: return index % 3 == 0 ? .robot : .normal
    case 5: return index % 3 == 0 ? .dog : .normal
    case 6: return index % 2 == 0 ? .normal : .tank
    case 7: return index % 2 == 0 ? .normal : .robot
    case 8: return index % 2 == 0 ? .dog : .tank
    case 9:
        switch index % 5 {
        case 0: return .normal
        case 1, 2: return .dog
        default: return .tank
        }
    case 10:
        switch index % 4 {
        case 0: return .normal
        case 1: return .dog
        default: return .robot
        }
    case 11: return index % 2 == 0 ? .tank : .robot
    case 12: return index % 2 == 0 ? .normal : .dog
    case 13: return index % 4 == 0 ? .normal : .tank
    case 14: return index % 3 == 0 ? .normal : .robot
    case 15:
        switch index % 3 {
        case 0: return .dog
        case 1: return .tank
        default: return .robot
        }
    default:
        let basicEvery = stage >= 25 ? 5 : (stage >= 20 ? 4 : 3)
        if index % basicEvery == 0 { return .normal }
        switch (stage + index) % 3 {
        case 0: return .dog
        case 1: return .tank
        default: return .robot
        }
    }
}

private func buildPath(_ points: [(Int, Int)]) -> [(Int, Int)] {
    var built = [points[0]]
    for index in 1..<points.count {
        let target = points[index]
        var column = built.last!.0
        var row = built.last!.1
        let stepColumn = min(1, max(-1, target.0 - column))
        let stepRow = min(1, max(-1, target.1 - row))
        while column != target.0 || row != target.1 {
            if column != target.0 { column += stepColumn } else { row += stepRow }
            built.append((column, row))
        }
    }
    return built
}

private func joinedPath(_ sections: [[(Int, Int)]]) -> [(Int, Int)] {
    sections.flatMap(buildPath)
}

private let stageMaps: [StageMap] = [
    StageMap([buildPath([(0, 1), (6, 1), (6, 3), (1, 3), (1, 5), (6, 5), (6, 7), (1, 7), (1, 9), (8, 9), (8, 11)])]),
    StageMap([buildPath([(0, 0), (8, 0), (8, 2), (0, 2), (0, 4), (8, 4), (8, 7), (2, 7), (2, 10), (8, 10)])]),
    StageMap([buildPath([(0, 0), (8, 0), (8, 11), (0, 11), (0, 3), (5, 3), (5, 9), (2, 9), (2, 5), (4, 5), (4, 6)])]),
    StageMap([buildPath([(0, 1), (8, 1), (0, 3), (8, 5), (0, 7), (8, 9), (8, 11)])]),
    StageMap([
        buildPath([(0, 1), (3, 1), (3, 5), (6, 5), (6, 9), (4, 9), (4, 6)]),
        buildPath([(8, 1), (5, 1), (5, 3), (1, 3), (1, 8), (4, 8), (4, 6)]),
    ]),
    StageMap([
        joinedPath([[(0, 2), (8, 2)], [(0, 6), (8, 6)], [(0, 10), (8, 10)]]),
        joinedPath([[(0, 2), (8, 2)], [(0, 4), (8, 4)], [(0, 10), (8, 10)]]),
        joinedPath([[(0, 2), (8, 2)], [(0, 8), (8, 8)], [(0, 10), (8, 10)]]),
    ]),
    StageMap([buildPath([(0, 11), (0, 0), (8, 0), (8, 11), (2, 11), (2, 3), (5, 3), (5, 8)])]),
    StageMap([
        buildPath([(0, 0), (3, 0), (3, 4), (1, 4), (1, 9), (4, 9), (4, 6)]),
        buildPath([(8, 0), (5, 0), (5, 4), (8, 4), (8, 9), (4, 9), (4, 6)]),
    ]),
    StageMap([buildPath([(0, 5), (8, 5), (8, 0), (1, 0), (1, 11), (6, 11), (6, 7), (3, 7)])]),
    StageMap([buildPath([(0, 1), (8, 1), (8, 11), (0, 11), (0, 3), (5, 3), (5, 9), (2, 9), (2, 5), (4, 5), (4, 6)])]),
    StageMap([buildPath([(0, 0), (8, 2), (0, 4), (8, 6), (0, 8), (8, 10), (8, 11)])]),
    StageMap([
        joinedPath([[(0, 1), (8, 1)], [(0, 5), (8, 5)], [(0, 9), (8, 9), (8, 11)]]),
        joinedPath([[(0, 3), (8, 3)], [(0, 7), (8, 7)], [(0, 9), (8, 9), (8, 11)]]),
    ]),
    StageMap([buildPath([(0, 6), (2, 6), (2, 1), (6, 1), (6, 10), (1, 10), (1, 4), (4, 4), (4, 6)])]),
    StageMap([
        buildPath([(0, 0), (0, 10), (3, 10), (3, 2), (6, 2), (6, 8), (4, 8), (4, 6)]),
        buildPath([(8, 0), (8, 10), (5, 10), (5, 2), (2, 2), (2, 8), (4, 8), (4, 6)]),
    ]),
    StageMap([buildPath([(0, 11), (8, 11), (8, 0), (0, 0), (0, 9), (5, 9), (5, 2), (2, 2), (2, 7), (4, 7), (4, 6)])]),
    StageMap([buildPath([(0, 2), (6, 2), (6, 4), (1, 4), (1, 6), (6, 6), (6, 8), (1, 8), (1, 10), (8, 10)])]),
    StageMap([buildPath([(0, 0), (8, 3), (0, 6), (8, 9), (4, 11), (4, 6)])]),
    StageMap([
        joinedPath([[(0, 1), (8, 1)], [(0, 10), (4, 10), (4, 6)]]),
        joinedPath([[(0, 4), (8, 4)], [(0, 8), (4, 8), (4, 6)]]),
        joinedPath([[(0, 7), (8, 7)], [(0, 6), (4, 6)]]),
    ]),
    StageMap([buildPath([(0, 5), (3, 5), (3, 0), (8, 0), (8, 11), (0, 11), (0, 2), (5, 2), (5, 8), (4, 8), (4, 6)])]),
    StageMap([buildPath([(0, 1), (8, 1), (8, 5), (2, 5), (2, 9), (6, 9), (6, 3), (4, 3), (4, 6)])]),
    StageMap([
        buildPath([(0, 0), (3, 3), (1, 5), (3, 7), (1, 9), (4, 9), (4, 6)]),
        buildPath([(8, 0), (5, 3), (8, 5), (5, 7), (8, 9), (4, 9), (4, 6)]),
    ]),
    StageMap([buildPath([(0, 11), (0, 1), (2, 1), (2, 10), (4, 10), (4, 2), (6, 2), (6, 8), (8, 8)])]),
    StageMap([buildPath([(0, 0), (8, 0), (8, 2), (0, 2), (0, 4), (8, 4), (8, 6), (0, 6), (0, 8), (8, 8), (8, 11)])]),
    StageMap([
        joinedPath([[(0, 2), (8, 2)], [(0, 9), (8, 9), (8, 11)]]),
        joinedPath([[(0, 5), (8, 5)], [(0, 9), (8, 9), (8, 11)]]),
        joinedPath([[(0, 7), (8, 7)], [(0, 9), (8, 9), (8, 11)]]),
    ]),
    StageMap([buildPath([(0, 6), (8, 6), (8, 0), (1, 0), (1, 11), (6, 11), (6, 2), (3, 2), (3, 9), (4, 9), (4, 6)])]),
    StageMap([buildPath([(0, 0), (8, 4), (0, 8), (3, 11), (8, 7), (3, 3), (4, 6)])]),
    StageMap([
        buildPath([(0, 1), (2, 1), (2, 10), (4, 10), (4, 6)]),
        buildPath([(8, 1), (6, 1), (6, 10), (4, 10), (4, 6)]),
        buildPath([(0, 6), (4, 6)]),
    ]),
    StageMap([buildPath([(0, 11), (8, 11), (8, 0), (0, 0), (0, 9), (6, 9), (6, 2), (1, 2), (1, 7), (5, 7), (5, 4), (4, 4), (4, 6)])]),
    StageMap([buildPath([(0, 0), (8, 0), (0, 2), (8, 4), (0, 6), (8, 8), (0, 10), (8, 11)])]),
    StageMap([
        joinedPath([[(0, 1), (8, 1)], [(0, 5), (8, 5)], [(0, 9), (4, 9), (4, 6)]]),
        joinedPath([[(0, 3), (8, 3)], [(0, 7), (8, 7)], [(0, 11), (4, 11), (4, 6)]]),
        buildPath([(0, 0), (8, 4), (0, 8), (4, 11), (4, 6)]),
    ]),
]

final class Enemy {
    let id: Int
    var along: Float
    var hp: Float
    let maxHp: Float
    var alive = true
    var boss: Bool
    let route: [(Int, Int)]
    let bossStyle: Int
    let splitLevel: Int
    var splitTriggered = false
    let lifeDamage: Int
    let reward: Int
    let kind: EnemyKind
    var specialCooldown: Float = 0
    var counterAttackLeft: Float = 0
    var counterAttackTotal: Float = 0
    weak var targetTower: Tower?
    var stun: Float = 0
    var poisonLeft: Float = 0
    var poisonRate: Float = 0
    var steppedIndex = -1
    init(id: Int, along: Float, hp: Float, maxHp: Float? = nil, boss: Bool = false, route: [(Int, Int)], bossStyle: Int = 0, splitLevel: Int = 0, lifeDamage: Int = 1, reward: Int = 12, kind: EnemyKind = .normal) {
        self.id = id
        self.along = along
        self.hp = hp
        self.maxHp = maxHp ?? hp
        self.boss = boss
        self.route = route
        self.bossStyle = bossStyle
        self.splitLevel = splitLevel
        self.lifeDamage = lifeDamage
        self.reward = reward
        self.kind = kind
    }
}

final class Mine {
    let column: Int
    let row: Int
    var levels: [Int]
    var count: Int { levels.count }
    init(column: Int, row: Int, levels: [Int]) {
        self.column = column
        self.row = row
        self.levels = levels
    }
}

final class Tower {
    var column: Int
    var row: Int
    let kind: WeaponKind
    var level: Int
    var cooldown: Float
    var laserTargetId = -1
    var laserCharge: Float = 0
    var beamOn = false
    var aimX: Float = 0
    var aimY: Float = 0
    var upgradeLeft: Float = 0
    var upgradeTotal: Float = 0
    var upgradeRefund = 0
    var health: Float = 100
    var repairLeft: Float = 0
    var repairTotal: Float = 0
    init(column: Int, row: Int, kind: WeaponKind, level: Int, cooldown: Float) {
        self.column = column
        self.row = row
        self.kind = kind
        self.level = level
        self.cooldown = cooldown
    }
}

enum FxKind { case line, blast }

final class Fx {
    let kind: FxKind
    let x1: Float
    let y1: Float
    let x2: Float
    let y2: Float
    var life: Float
    let maxLife: Float
    let color: Color
    let stroke: Float
    let inner: Float
    let outer: Float
    init(kind: FxKind, x1: Float, y1: Float, x2: Float, y2: Float, life: Float, maxLife: Float, color: Color, stroke: Float, inner: Float, outer: Float) {
        self.kind = kind
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.life = life
        self.maxLife = maxLife
        self.color = color
        self.stroke = stroke
        self.inner = inner
        self.outer = outer
    }
}

@MainActor
@Observable
final class DefenseGame {
    var gold = startingGold(1)
    var buildGauge: Float = 0
    var speed: Float = 1

    func cycleSpeed() {
        switch speed {
        case 1: speed = 2
        case 2: speed = 4
        case 4: speed = 0.5
        default: speed = 1
        }
    }

    var speedLabel: String {
        switch speed {
        case 0.5: return "½×"
        case 2: return "2×"
        case 4: return "4×"
        default: return "1×"
        }
    }

    func canBuildTower(_ kind: WeaponKind) -> Bool {
        let cost = Float(towerCost(kind))
        return buildGauge >= cost && Float(gold) >= cost
    }
    var canBuildTower: Bool { canBuildTower(placeKind) }
    var mineStock = startingMineStock
    var mineLevel = 1
    var mineUpgradeLeft: Float = 0
    var mineUpgradeTotal: Float = 0
    var lives = 10
    var stage = 1
    var wave = 0
    var running = true
    var paused = false
    var screensaver = false
    var won = false
    var awaitingBriefing = true
    var idleTime: Float = 0
    var placeKind = WeaponKind.basic
    var selectedColumn = -1
    var selectedRow = -1
    var selectedPathColumn = -1
    var selectedPathRow = -1
    var towers: [Tower] = []
    var mines: [Mine] = []
    var enemies: [Enemy] = []
    var effects: [Fx] = []
    var frame = 0
    private var nextEnemyId = 1
    private var pendingEnemies: [Enemy] = []

    private var currentMap: StageMap { stageMaps[min(stage - 1, stageMaps.count - 1)] }
    var home: (Int, Int) { currentMap.home }
    var entrances: [(Int, Int)] { currentMap.routes.map { $0[0] } }

    func isPathCell(column: Int, row: Int) -> Bool {
        currentMap.contains(column: column, row: row)
    }

    private func routeForNextEnemy() -> [(Int, Int)] {
        currentMap.routes[(nextEnemyId - 1) % currentMap.routes.count]
    }

    var isPathSelected: Bool { selectedPathColumn >= 0 && selectedPathRow >= 0 }

    var canUseMineButton: Bool {
        guard running else { return false }
        if isPathSelected { return mineStock > 0 || gold >= mineCost }
        return gold >= mineCost
    }

    var hasProgress: Bool { stage > 1 || wave > 0 || !towers.isEmpty || !mines.isEmpty }

    func toSaveJson() -> String {
        let towerArray: [[String: Any]] = towers.map { tower in
            [
                "column": tower.column,
                "row": tower.row,
                "kind": saveName(tower.kind),
                "level": tower.level,
                "cooldown": Double(tower.cooldown),
                "upgradeLeft": Double(tower.upgradeLeft),
                "upgradeTotal": Double(tower.upgradeTotal),
                "upgradeRefund": tower.upgradeRefund,
                "health": Double(tower.health),
                "repairLeft": Double(tower.repairLeft),
                "repairTotal": Double(tower.repairTotal),
            ]
        }
        let mineArray: [[String: Any]] = mines.map { mine in
            ["column": mine.column, "row": mine.row, "levels": mine.levels]
        }
        let enemyArray: [[String: Any]] = enemies.compactMap { enemy in
            guard enemy.alive else { return nil }
            let routeIndex = currentMap.routes.firstIndex { route in
                route.count == enemy.route.count && zip(route, enemy.route).allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 }
            } ?? 0
            return [
                "id": enemy.id,
                "along": Double(enemy.along),
                "hp": Double(enemy.hp),
                "maxHp": Double(enemy.maxHp),
                "boss": enemy.boss,
                "route": routeIndex,
                "bossStyle": enemy.bossStyle,
                "splitLevel": enemy.splitLevel,
                "lifeDamage": enemy.lifeDamage,
                "reward": enemy.reward,
                "kind": saveName(enemy.kind),
                "splitTriggered": enemy.splitTriggered,
                "stun": Double(enemy.stun),
                "poisonLeft": Double(enemy.poisonLeft),
                "poisonRate": Double(enemy.poisonRate),
                "steppedIndex": enemy.steppedIndex,
                "specialCooldown": Double(enemy.specialCooldown),
            ]
        }
        let root: [String: Any] = [
            "gold": gold,
            "mineStock": mineStock,
            "mineLevel": mineLevel,
            "mineUpgradeLeft": Double(mineUpgradeLeft),
            "mineUpgradeTotal": Double(mineUpgradeTotal),
            "lives": lives,
            "stage": stage,
            "wave": wave,
            "awaitingBriefing": awaitingBriefing,
            "idleTime": Double(idleTime),
            "placeKind": saveName(placeKind),
            "nextEnemyId": nextEnemyId,
            "towers": towerArray,
            "mines": mineArray,
            "enemies": enemyArray,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    func restoreFromSaveJson(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stageValue = jsonInt(root["stage"]),
              let waveValue = jsonInt(root["wave"]),
              let goldValue = jsonInt(root["gold"]),
              let stockValue = jsonInt(root["mineStock"]),
              let mineLevelValue = jsonInt(root["mineLevel"]),
              let mineLeft = jsonFloat(root["mineUpgradeLeft"]),
              let mineTotal = jsonFloat(root["mineUpgradeTotal"]),
              let livesValue = jsonInt(root["lives"]),
              let waiting = jsonBool(root["awaitingBriefing"]),
              let idle = jsonFloat(root["idleTime"]),
              let kindName = root["placeKind"] as? String,
              let kind = weaponKind(named: kindName),
              let nextId = jsonInt(root["nextEnemyId"]),
              let towerArray = root["towers"] as? [Any],
              let mineArray = root["mines"] as? [Any],
              let enemyArray = root["enemies"] as? [Any] else { return false }
        stage = min(max(stageValue, 1), stageCount)
        wave = min(max(waveValue, 0), wavesPerStage)
        gold = goldValue
        mineStock = stockValue
        mineLevel = min(max(mineLevelValue, 1), mineMaxLevel)
        mineUpgradeLeft = mineLeft
        mineUpgradeTotal = mineTotal
        lives = livesValue
        awaitingBriefing = waiting
        idleTime = idle
        placeKind = kind
        nextEnemyId = nextId
        towers = []
        for raw in towerArray {
            guard let item = raw as? [String: Any] else { return false }
            guard let column = jsonInt(item["column"]),
                  let row = jsonInt(item["row"]),
                  let name = item["kind"] as? String,
                  let towerKind = weaponKind(named: name),
                  let level = jsonInt(item["level"]),
                  let cooldown = jsonFloat(item["cooldown"]),
                  let upgradeLeft = jsonFloat(item["upgradeLeft"]),
                  let upgradeTotal = jsonFloat(item["upgradeTotal"]),
                  let upgradeRefund = jsonInt(item["upgradeRefund"]),
                  let health = jsonFloat(item["health"]),
                  let repairLeft = jsonFloat(item["repairLeft"]),
                  let repairTotal = jsonFloat(item["repairTotal"]) else { return false }
            let tower = Tower(column: column, row: row, kind: towerKind, level: level, cooldown: cooldown)
            tower.upgradeLeft = upgradeLeft
            tower.upgradeTotal = upgradeTotal
            tower.upgradeRefund = upgradeRefund
            tower.health = health
            tower.repairLeft = repairLeft
            tower.repairTotal = repairTotal
            towers.append(tower)
        }
        mines = []
        for raw in mineArray {
            guard let item = raw as? [String: Any] else { return false }
            guard let column = jsonInt(item["column"]),
                  let row = jsonInt(item["row"]),
                  let levels = item["levels"] as? [Any] else { return false }
            var parsed: [Int] = []
            for level in levels {
                guard let value = jsonInt(level) else { return false }
                parsed.append(value)
            }
            mines.append(Mine(column: column, row: row, levels: parsed))
        }
        enemies = []
        let routes = currentMap.routes
        guard !routes.isEmpty else { return false }
        for raw in enemyArray {
            guard let item = raw as? [String: Any] else { return false }
            guard let id = jsonInt(item["id"]),
                  let along = jsonFloat(item["along"]),
                  let hp = jsonFloat(item["hp"]),
                  let maxHp = jsonFloat(item["maxHp"]),
                  let boss = jsonBool(item["boss"]),
                  let routeIndex = jsonInt(item["route"]),
                  let bossStyle = jsonInt(item["bossStyle"]),
                  let splitLevel = jsonInt(item["splitLevel"]),
                  let lifeDamage = jsonInt(item["lifeDamage"]),
                  let reward = jsonInt(item["reward"]),
                  let name = item["kind"] as? String,
                  let kind = enemyKind(named: name),
                  let splitTriggered = jsonBool(item["splitTriggered"]),
                  let stun = jsonFloat(item["stun"]),
                  let poisonLeft = jsonFloat(item["poisonLeft"]),
                  let poisonRate = jsonFloat(item["poisonRate"]),
                  let steppedIndex = jsonInt(item["steppedIndex"]),
                  let specialCooldown = jsonFloat(item["specialCooldown"]) else { return false }
            let clamped = min(max(routeIndex, 0), routes.count - 1)
            let enemy = Enemy(
                id: id, along: along, hp: hp, maxHp: maxHp, boss: boss, route: routes[clamped],
                bossStyle: bossStyle, splitLevel: splitLevel, lifeDamage: lifeDamage, reward: reward, kind: kind
            )
            enemy.splitTriggered = splitTriggered
            enemy.stun = stun
            enemy.poisonLeft = poisonLeft
            enemy.poisonRate = poisonRate
            enemy.steppedIndex = steppedIndex
            enemy.specialCooldown = specialCooldown
            enemies.append(enemy)
        }
        running = true
        won = false
        paused = !awaitingBriefing
        selectedColumn = -1
        selectedRow = -1
        selectedPathColumn = -1
        selectedPathRow = -1
        buildGauge = max(0, Float(gold))
        return true
    }

    func beginBriefedStage() {
        awaitingBriefing = false
        idleTime = 0
        frame += 1
    }

    func selectedTower() -> Tower? {
        towers.first { $0.column == selectedColumn && $0.row == selectedRow }
    }

    func onBoardTap(column: Int, row: Int) {
        guard running, column >= 0, column < cols, row >= 0, row < rows else { return }
        if let tower = towers.first(where: { $0.column == column && $0.row == row }) {
            beginTowerUpgrade(tower)
            return
        }
        if isPathCell(column: column, row: row) {
            selectedColumn = -1
            selectedRow = -1
            if selectedPathColumn == column && selectedPathRow == row {
                selectedPathColumn = -1
                selectedPathRow = -1
            } else {
                selectedPathColumn = column
                selectedPathRow = row
            }
            return
        }
        selectedPathColumn = -1
        selectedPathRow = -1
        place(column: column, row: row)
    }

    func buyOrPlaceMine() {
        guard running else { return }
        if isPathSelected {
            placeMine(column: selectedPathColumn, row: selectedPathRow)
            return
        }
        guard gold >= mineCost else { return }
        gold -= mineCost
        mineStock += 1
        GameAudio.shared.play(.mine)
    }

    private func placeMine(column: Int, row: Int) {
        guard isPathCell(column: column, row: row) else { return }
        if mineStock > 0 {
            mineStock -= 1
        } else if gold >= mineCost {
            gold -= mineCost
        } else {
            return
        }
        if let mine = mines.first(where: { $0.column == column && $0.row == row }) {
            mine.levels.append(mineLevel)
        } else {
            mines.append(Mine(column: column, row: row, levels: [mineLevel]))
        }
        GameAudio.shared.play(.mine)
    }

    func upgradeMine() {
        guard running, mineLevel < mineMaxLevel, mineUpgradeLeft <= 0 else { return }
        let cost = mineUpgradeCost(mineLevel)
        guard gold >= cost else { return }
        gold -= cost
        mineUpgradeTotal = upgradeSeconds(mineLevel)
        mineUpgradeLeft = mineUpgradeTotal
        GameAudio.shared.play(.upgradeStart)
    }

    var cancelUpgradeRefund: Int {
        if let tower = selectedTower(), tower.upgradeLeft > 0, tower.upgradeRefund > 0 { return tower.upgradeRefund }
        if mineUpgradeLeft > 0 { return mineUpgradeCost(mineLevel) }
        return 0
    }

    func cancelUpgrade() {
        guard running else { return }
        if let tower = selectedTower(), tower.upgradeLeft > 0, tower.upgradeRefund > 0 {
            gold += tower.upgradeRefund
            tower.upgradeRefund = 0
            tower.upgradeLeft = 0
            tower.upgradeTotal = 0
            GameAudio.shared.play(.recall)
            return
        }
        if mineUpgradeLeft > 0 {
            gold += mineUpgradeCost(mineLevel)
            mineUpgradeLeft = 0
            mineUpgradeTotal = 0
            GameAudio.shared.play(.recall)
        }
    }

    func spentOn(_ tower: Tower) -> Int {
        var total = investedCost(tower.kind, tower.level)
        if tower.upgradeLeft > 0 { total += tower.upgradeRefund }
        return total
    }

    func recallRefund() -> Int {
        if let tower = selectedTower() { return spentOn(tower) * 80 / 100 }
        guard isPathSelected, let mine = mines.first(where: { $0.column == selectedPathColumn && $0.row == selectedPathRow }), mine.count > 0 else { return 0 }
        return mineCost * mine.count * 80 / 100
    }

    func recallSelected() {
        guard running else { return }
        if let tower = selectedTower() {
            gold += spentOn(tower) * 80 / 100
            towers.removeAll { $0.column == tower.column && $0.row == tower.row }
            selectedColumn = -1
            selectedRow = -1
            GameAudio.shared.play(.recall)
            return
        }
        guard isPathSelected else { return }
        guard let index = mines.firstIndex(where: { $0.column == selectedPathColumn && $0.row == selectedPathRow }), mines[index].count > 0 else { return }
        gold += mineCost * mines[index].count * 80 / 100
        mines.remove(at: index)
        selectedPathColumn = -1
        selectedPathRow = -1
        GameAudio.shared.play(.recall)
    }

    func place(column: Int, row: Int) {
        guard running, canBuildTower else { return }
        guard column >= 0, column < cols, row >= 0, row < rows else { return }
        if isPathCell(column: column, row: row) { return }
        if towers.contains(where: { $0.column == column && $0.row == row }) { return }
        let cost = towerCost(placeKind)
        gold -= cost
        buildGauge = max(0, min(buildGauge - Float(cost), Float(gold)))
        towers.append(Tower(column: column, row: row, kind: placeKind, level: 1, cooldown: 0))
        selectedColumn = column
        selectedRow = row
        GameAudio.shared.play(.place)
    }

    func beginTowerUpgrade(_ tower: Tower) {
        guard running else { return }
        selectedPathColumn = -1
        selectedPathRow = -1
        selectedColumn = tower.column
        selectedRow = tower.row
        if tower.health < towerMaxHealth(tower.level) {
            guard tower.repairLeft <= 0 else { return }
            let maxHealth = towerMaxHealth(tower.level)
            tower.repairTotal = max(1, 3 * (maxHealth - tower.health) / maxHealth)
            tower.repairLeft = tower.repairTotal
            GameAudio.shared.play(.upgradeStart)
            return
        }
        guard tower.level < upgradeMaxLevel, tower.upgradeLeft <= 0 else { return }
        let cost = towerUpgradeCost(tower.kind, tower.level)
        guard gold >= cost else { return }
        gold -= cost
        tower.upgradeRefund = cost
        tower.upgradeTotal = upgradeSeconds(tower.level)
        tower.upgradeLeft = tower.upgradeTotal
        GameAudio.shared.play(.upgradeStart)
    }

    func moveOrMerge(fromColumn: Int, fromRow: Int, toColumn: Int, toRow: Int) {
        guard running else { return }
        guard let moving = towers.first(where: { $0.column == fromColumn && $0.row == fromRow }) else { return }
        if fromColumn == toColumn && fromRow == toRow { return }
        guard toColumn >= 0, toColumn < cols, toRow >= 0, toRow < rows else { return }
        if isPathCell(column: toColumn, row: toRow) { return }
        if let target = towers.first(where: { $0.column == toColumn && $0.row == toRow }) {
            guard target.kind == moving.kind else { return }
            guard moving.level == target.level, moving.level >= upgradeMaxLevel, moving.level < towerMaxLevel else { return }
            guard moving.upgradeLeft <= 0, target.upgradeLeft <= 0 else { return }
            let newLevel = moving.level + 1
            let fair = investedCost(moving.kind, newLevel)
            let paid = spentOn(moving) + spentOn(target)
            let delta = fair - paid
            if delta > 0 {
                guard gold >= delta else { return }
                gold -= delta
            } else if delta < 0 {
                gold += -delta
            }
            target.laserTargetId = -1
            target.laserCharge = 0
            target.beamOn = false
            target.upgradeRefund = 0
            target.upgradeTotal = upgradeSeconds(target.level)
            target.upgradeLeft = target.upgradeTotal
            towers.removeAll { $0.column == fromColumn && $0.row == fromRow }
            selectedColumn = target.column
            selectedRow = target.row
            selectedPathColumn = -1
            selectedPathRow = -1
            GameAudio.shared.play(.upgradeStart)
            return
        }
        moving.column = toColumn
        moving.row = toRow
        selectedColumn = toColumn
        selectedRow = toRow
        selectedPathColumn = -1
        selectedPathRow = -1
    }

    func launchWave() {
        guard running, !won, !awaitingBriefing, wave < wavesPerStage else { return }
        guard !enemies.contains(where: { $0.alive }) else { return }
        wave += 1
        idleTime = 0
        if wave == wavesPerStage {
            launchBoss()
            GameAudio.shared.play(.boss)
            return
        }
        let full = 5 + wave
        let count = stage == 3 ? max(3, full / 2) : full
        let baseHp = Float(10 + wave * 6) * (1 + Float(stage - 1) * 0.25)
        var tanksLeft = tankBudget(stage: stage, wave: wave)
        for index in 0..<count {
            var kind = creepKind(stage: stage, index: index)
            if kind == .tank && stage != 3 {
                if tanksLeft > 0 {
                    tanksLeft -= 1
                } else if stage == 6 || stage == 9 || stage == 13 || stage >= 16 {
                    kind = .normal
                }
            }
            let hp: Float
            switch kind {
            case .dog: hp = baseHp * 0.5
            case .tank: hp = baseHp * 2
            case .robot: hp = baseHp * 4
            default: hp = baseHp
            }
            enemies.append(Enemy(id: nextEnemyId, along: -Float(index) * 0.95, hp: hp, route: routeForNextEnemy(), reward: kind == .tank ? tankReward : (kind == .robot ? robotReward : 12), kind: kind))
            nextEnemyId += 1
        }
        if enemies.contains(where: { $0.kind == .dog }) {
            GameAudio.shared.play(.dog)
        }
        if wave.isMultiple(of: 5) {
            let hp = max(20, baseHp * 0.35) * 4
            enemies.append(Enemy(
                id: nextEnemyId, along: 0, hp: hp, route: routeForNextEnemy(),
                lifeDamage: 0, reward: 500 + stage * 100, kind: .ufo
            ))
            nextEnemyId += 1
            GameAudio.shared.play(.ufo)
        }
        GameAudio.shared.play(.wave)
    }

    private func launchBoss() {
        let hp = bossHealth(stage)
        let totalReward = 150 + stage * 30
        if stage.isMultiple(of: 5) {
            for index in 0..<5 {
                let memberHp = hp * 0.3
                enemies.append(Enemy(
                    id: nextEnemyId, along: -Float(index) * 1.15, hp: memberHp,
                    boss: true, route: routeForNextEnemy(), bossStyle: 1 + index % 2,
                    lifeDamage: 1, reward: totalReward / 5
                ))
                nextEnemyId += 1
            }
        } else {
            let splitter = stage.isMultiple(of: 3)
            enemies.append(Enemy(
                id: nextEnemyId, along: 0, hp: hp, boss: true, route: routeForNextEnemy(),
                bossStyle: splitter ? 3 : stage % 3, lifeDamage: 5, reward: totalReward
            ))
            nextEnemyId += 1
        }
    }

    private func updateBuildGauge(_ dt: Float) {
        let target = max(0, Float(gold))
        if buildGauge < target {
            buildGauge = min(target, buildGauge + dt * buildFundFillSpeed)
        } else {
            buildGauge = target
        }
    }

    func update(dt: Float) {
        guard running, !awaitingBriefing, !paused else { return }
        updateBuildGauge(dt)
        let speed = 0.95 + Float(max(0, wave - 1)) * 0.03 + Float(max(0, stage - 1)) * 0.22
        for enemy in enemies where enemy.alive {
            enemy.specialCooldown = max(0, enemy.specialCooldown - dt)
            if enemy.kind == .robot {
                tickRobot(enemy, dt)
            } else if enemy.counterAttackLeft > 0 {
                enemy.counterAttackLeft = max(0, enemy.counterAttackLeft - dt)
                if enemy.counterAttackLeft <= 0 {
                    enemy.targetTower = nil
                }
            }
            if enemy.stun > 0 {
                enemy.stun = max(0, enemy.stun - dt)
            }
            let stunned = enemy.stun > 0
            let stopped = (stunned && !enemy.boss) || enemy.counterAttackLeft > 0
            if !stopped {
                let poisonFactor: Float = enemy.poisonLeft > 0 ? poisonSlow : 1
                let kindFactor: Float
                switch enemy.kind {
                case .dog: kindFactor = 2
                case .ufo: kindFactor = 2.5
                case .tank: kindFactor = tankPace
                case .robot: kindFactor = robotPace
                default: kindFactor = 1
                }
                var pace = speed * (enemy.boss ? 0.45 : 1) * poisonFactor * kindFactor
                if enemy.boss && stunned { pace *= bossEmpSlow }
                if enemy.boss { pace = min(pace, bossPaceCap) }
                enemy.along += dt * pace
            }
            if enemy.poisonLeft > 0 {
                let step = min(enemy.poisonLeft, dt)
                hurt(enemy, enemy.poisonRate * step)
                enemy.poisonLeft -= step
            }
        }
        detonateMines()
        for enemy in enemies where enemy.alive {
            if enemy.along >= Float(enemy.route.count - 1) {
                enemy.alive = false
                lives -= enemy.lifeDamage
            }
        }
        for effect in effects { effect.life -= dt }
        effects.removeAll { $0.life <= 0 }
        tickUpgrades(dt)
        for tower in towers {
            if tower.health <= 0 || tower.repairLeft > 0 {
                tower.beamOn = false
                tower.laserTargetId = -1
                tower.laserCharge = 0
                continue
            }
            if tower.upgradeLeft > 0 {
                tower.beamOn = false
                tower.laserTargetId = -1
                tower.laserCharge = 0
                continue
            }
            if tower.kind == .laser {
                fireLaser(tower, dt)
                continue
            }
            tower.beamOn = false
            tower.cooldown -= dt
            if tower.cooldown > 0 { continue }
            let fired: Bool
            switch tower.kind {
            case .basic: fired = fireBasic(tower)
            case .shotgun: fired = fireShotgun(tower)
            case .bomb: fired = fireBomb(tower)
            case .emp: fired = fireEmp(tower)
            case .poison: fired = firePoison(tower)
            case .laser: fired = false
            }
            if fired { tower.cooldown = fireCooldown(tower.kind, tower.level) }
        }
        if !pendingEnemies.isEmpty {
            enemies.append(contentsOf: pendingEnemies)
            pendingEnemies.removeAll()
        }
        enemies.removeAll { !$0.alive }
        if lives <= 0 {
            running = false
            GameAudio.shared.play(.lose)
            frame += 1
            return
        }
        if enemies.isEmpty {
            if wave >= wavesPerStage {
                recallAllUnits()
                if stage >= stageCount {
                    won = true
                    running = false
                    GameAudio.shared.play(.win)
                    frame += 1
                    return
                }
                stage += 1
                gold = startingGold(stage)
                mineStock = startingMineStock
                wave = 0
                idleTime = 0
                awaitingBriefing = true
            }
            if awaitingBriefing {
                frame += 1
                return
            }
            idleTime += dt
            if idleTime >= autoWaveDelay { launchWave() }
        } else {
            idleTime = 0
        }
        frame += 1
    }

    func tileOf(_ enemy: Enemy) -> (Float, Float)? {
        if enemy.kind == .robot, enemy.counterAttackLeft > 0, let tower = enemy.targetTower {
            return (Float(tower.column), Float(tower.row))
        }
        return tileOf(enemy.along, route: enemy.route)
    }

    private func tileOf(_ along: Float, route: [(Int, Int)]) -> (Float, Float)? {
        guard along >= 0, along < Float(route.count - 1) else { return nil }
        let index = min(Int(along), route.count - 2)
        let fraction = along - Float(index)
        let from = route[index]
        let to = route[index + 1]
        if abs(to.0 - from.0) + abs(to.1 - from.1) > 1 {
            return fraction < 0.5 ? (Float(from.0), Float(from.1)) : (Float(to.0), Float(to.1))
        }
        return (
            Float(from.0) + Float(to.0 - from.0) * fraction,
            Float(from.1) + Float(to.1 - from.1) * fraction
        )
    }

    private func fireBasic(_ tower: Tower) -> Bool {
        fireBasic(column: tower.column, row: tower.row, level: tower.level, source: tower)
    }

    private func fireBasic(column: Int, row: Int, level: Int, source: Tower? = nil) -> Bool {
        guard let target = nearestBasic(column: column, row: row, level: level), let position = tileOf(target) else { return false }
        hurt(target, 5 * powerOf(.basic, level), source: source)
        effects.append(Fx(
            kind: .line,
            x1: Float(column) + 0.5, y1: Float(row) + 0.5,
            x2: position.0 + 0.5, y2: position.1 + 0.5,
            life: 0.12, maxLife: 0.12, color: levelColor(level),
            stroke: 3.5, inner: 0, outer: 0
        ))
        return true
    }

    private func nearestBasic(column: Int, row: Int, level: Int) -> Enemy? {
        var best: Enemy?
        var bestDistance = reachOf(.basic, level)
        let originX = Float(column) + 0.5
        let originY = Float(row) + 0.5
        for enemy in enemies where enemy.alive {
            guard let position = tileOf(enemy) else { continue }
            let distance = hypotf(position.0 + 0.5 - originX, position.1 + 0.5 - originY)
            if distance <= bestDistance {
                bestDistance = distance
                best = enemy
            }
        }
        return best
    }

    private func fireEmp(_ tower: Tower) -> Bool {
        let originX = Float(tower.column) + 0.5
        let originY = Float(tower.row) + 0.5
        let inner: Float = 1
        let outer = reachOf(.emp, tower.level)
        let damage = 4 * powerOf(.emp, tower.level)
        var hit = false
        for enemy in enemies where enemy.alive {
            let distance = distanceTo(tower, enemy)
            let dealt: Float
            if distance <= inner { dealt = damage }
            else if distance <= outer { dealt = damage * 0.5 }
            else { continue }
            hurt(enemy, dealt, source: tower)
            enemy.stun = max(enemy.stun, empStun(tower.level))
            hit = true
        }
        guard hit else { return false }
        effects.append(Fx(
            kind: .blast, x1: originX, y1: originY, x2: originX, y2: originY,
            life: 0.22, maxLife: 0.22, color: Color(hex: 0x22D3EE),
            stroke: 2, inner: inner, outer: outer
        ))
        return true
    }

    private func firePoison(_ tower: Tower) -> Bool {
        let originX = Float(tower.column) + 0.5
        let originY = Float(tower.row) + 0.5
        let total = 5 * powerOf(.poison, tower.level)
        let reach = reachOf(.poison, tower.level)
        var hit = false
        for enemy in enemies where enemy.alive {
            guard distanceTo(tower, enemy) <= reach else { continue }
            enemy.poisonLeft = poisonDuration
            enemy.poisonRate = total / poisonDuration
            hit = true
        }
        guard hit else { return false }
        effects.append(Fx(
            kind: .blast, x1: originX, y1: originY, x2: originX, y2: originY,
            life: 0.2, maxLife: 0.2, color: levelColor(tower.level),
            stroke: 2, inner: 0.35, outer: reach
        ))
        return true
    }

    private func fireShotgun(_ tower: Tower) -> Bool {
        guard let target = nearest(tower), let position = tileOf(target) else { return false }
        let originX = Float(tower.column) + 0.5
        let originY = Float(tower.row) + 0.5
        let aimX = position.0 + 0.5 - originX
        let aimY = position.1 + 0.5 - originY
        let damage = 3.4 * powerOf(.shotgun, tower.level)
        let dotLimit = 0.82 - Float(tower.level - 1) * 0.03
        for enemy in enemiesInCone(tower, aimX, aimY, dotLimit) {
            hurt(enemy, damage, source: tower)
        }
        let angle = atan2(aimY, aimX)
        let length = reachOf(tower.kind, tower.level) * 0.92
        let color = levelColor(tower.level)
        for delta in [-0.42, -0.2, 0, 0.2, 0.42] as [Float] {
            effects.append(Fx(
                kind: .line, x1: originX, y1: originY,
                x2: originX + cos(angle + delta) * length,
                y2: originY + sin(angle + delta) * length,
                life: 0.1, maxLife: 0.1, color: color, stroke: 2.5, inner: 0, outer: 0
            ))
        }
        return true
    }

    private func fireLaser(_ tower: Tower, _ dt: Float) {
        let range = reachOf(tower.kind, tower.level)
        let locked = enemies.first { $0.alive && $0.id == tower.laserTargetId }
        let keep = locked != nil && distanceTo(tower, locked!) <= range
        let riding = enemies.first { $0.alive && $0.kind == .robot && $0.counterAttackLeft > 0 && $0.targetTower === tower }
        let target = riding ?? (keep ? locked : nearest(tower))
        guard let target else {
            tower.laserTargetId = -1
            tower.laserCharge = 0
            tower.beamOn = false
            return
        }
        if target.id != tower.laserTargetId {
            tower.laserTargetId = target.id
            tower.laserCharge = 0
        }
        guard let position = tileOf(target) else {
            tower.beamOn = false
            return
        }
        tower.laserCharge = min(1, tower.laserCharge + dt / laserRampSeconds)
        hurt(target, (3 + tower.laserCharge * 14) * powerOf(.laser, tower.level) * dt, source: tower)
        tower.beamOn = true
        tower.aimX = position.0 + 0.5
        tower.aimY = position.1 + 0.5
    }

    private func fireBomb(_ tower: Tower) -> Bool {
        guard let target = nearest(tower), let position = tileOf(target) else { return false }
        let x = position.0 + 0.5
        let y = position.1 + 0.5
        let inner = 1.15 + Float(tower.level - 1) * 0.08
        let outer = 2.1 + Float(tower.level - 1) * 0.12
        let damage = 10 * powerOf(.bomb, tower.level)
        for enemy in enemies where enemy.alive {
            guard let at = tileOf(enemy) else { continue }
            let distance = hypotf(at.0 + 0.5 - x, at.1 + 0.5 - y)
            if distance <= inner { hurt(enemy, damage, source: tower) }
            else if distance <= outer { hurt(enemy, damage * 0.5, source: tower) }
        }
        effects.append(Fx(
            kind: .blast, x1: x, y1: y, x2: x, y2: y,
            life: 0.28, maxLife: 0.28, color: levelColor(tower.level),
            stroke: 3, inner: inner, outer: outer
        ))
        return true
    }

    private func tickUpgrades(_ dt: Float) {
        for tower in towers {
            if tower.repairLeft > 0 {
                tower.repairLeft = max(0, tower.repairLeft - dt)
                if tower.repairLeft <= 0 {
                    tower.repairTotal = 0
                    tower.health = towerMaxHealth(tower.level)
                }
            }
        }
        for tower in towers where tower.upgradeLeft > 0 {
            tower.upgradeLeft -= dt
            if tower.upgradeLeft > 0 { continue }
            tower.upgradeLeft = 0
            tower.upgradeTotal = 0
            tower.upgradeRefund = 0
            if tower.health > 0 {
                tower.health += towerMaxHealth(tower.level + 1) - towerMaxHealth(tower.level)
            }
            tower.level += 1
            tower.laserTargetId = -1
            tower.laserCharge = 0
            GameAudio.shared.play(.upgradeDone)
        }
        guard mineUpgradeLeft > 0 else { return }
        mineUpgradeLeft -= dt
        if mineUpgradeLeft > 0 { return }
        mineUpgradeLeft = 0
        mineUpgradeTotal = 0
        mineLevel += 1
        for mine in mines {
            for index in mine.levels.indices where mine.levels[index] < mineMaxLevel {
                mine.levels[index] += 1
            }
        }
        GameAudio.shared.play(.upgradeDone)
    }

    private func recallAllUnits() {
        towers.removeAll()
        mines.removeAll()
        mineStock = 0
        effects.removeAll()
        selectedColumn = -1
        selectedRow = -1
        selectedPathColumn = -1
        selectedPathRow = -1
    }

    private func detonateMines() {
        for enemy in enemies where enemy.alive {
            guard enemy.along >= 0 else { continue }
            let arrived = min(Int(enemy.along), enemy.route.count - 1)
            let start = enemy.steppedIndex < 0 ? 0 : enemy.steppedIndex + 1
            if start > arrived { continue }
            enemy.steppedIndex = arrived
            for index in start...arrived {
                guard enemy.alive else { break }
                let cell = enemy.route[index]
                guard let mine = mines.first(where: { $0.column == cell.0 && $0.row == cell.1 && !$0.levels.isEmpty }) else { continue }
                explode(mine, enemy)
            }
        }
        mines.removeAll { $0.levels.isEmpty }
    }

    private func explode(_ mine: Mine, _ trigger: Enemy) {
        let level = mine.levels.removeFirst()
        let radius = mineSplashRadius(level)
        let x = Float(mine.column) + 0.5
        let y = Float(mine.row) + 0.5
        hurt(trigger, mineHitDamage(level))
        for enemy in enemies where enemy.alive && enemy.id != trigger.id {
            guard let at = tileOf(enemy) else { continue }
            let distance = hypotf(at.0 + 0.5 - x, at.1 + 0.5 - y)
            if distance <= radius { hurt(enemy, mineSplashDamage(level)) }
        }
        effects.append(Fx(
            kind: .blast, x1: x, y1: y, x2: x, y2: y,
            life: 0.28, maxLife: 0.28, color: levelColor(level),
            stroke: 3, inner: 0.42, outer: radius
        ))
        GameAudio.shared.play(.boom)
    }

    private func hurt(_ enemy: Enemy, _ damage: Float, source: Tower? = nil) {
        guard enemy.alive, damage > 0 else { return }
        enemy.hp -= damage
        if enemy.kind == .tank, let source, source.health > 0 {
            if enemy.targetTower == nil || enemy.targetTower === source {
                let startingCounter = enemy.counterAttackLeft <= 0
                enemy.targetTower = source
                enemy.counterAttackTotal = tankCounterPause
                enemy.counterAttackLeft = tankCounterPause
                damageTower(source, amount: damage)
                if startingCounter { GameAudio.shared.play(.tankFire) }
            }
        }
        if enemy.bossStyle == 3, enemy.splitLevel < 2, !enemy.splitTriggered, enemy.hp <= enemy.maxHp * 0.5 {
            enemy.splitTriggered = true
            enemy.alive = false
            let remaining = max(enemy.hp, enemy.maxHp * 0.5)
            let childHp = remaining / 2
            let nextLevel = enemy.splitLevel + 1
            let firstReward = enemy.reward / 2
            let rewards = [firstReward, enemy.reward - firstReward]
            for index in 0..<2 {
                pendingEnemies.append(Enemy(
                    id: nextEnemyId,
                    along: max(0, enemy.along + (index == 0 ? -0.12 : 0.12)),
                    hp: childHp,
                    boss: true,
                    route: enemy.route,
                    bossStyle: 3,
                    splitLevel: nextLevel,
                    lifeDamage: max(1, enemy.lifeDamage / 2),
                    reward: rewards[index]
                ))
                nextEnemyId += 1
            }
            return
        }
        if enemy.hp <= 0 {
            enemy.alive = false
            gold += enemy.reward
            if enemy.kind == .ufo { addGoldBurst(for: enemy) }
        }
    }

    private func addGoldBurst(for enemy: Enemy) {
        guard let position = tileOf(enemy) else { return }
        let centerX = position.0 + 0.5
        let centerY = position.1 + 0.5
        for index in 0..<16 {
            let angle = Float(index) * (.pi * 2 / 16)
            let distance: Float = 0.25 + Float(index % 4) * 0.12
            let x = centerX + cos(angle) * distance
            let y = centerY + sin(angle) * distance
            effects.append(Fx(
                kind: .blast, x1: x, y1: y, x2: x, y2: y,
                life: 0.65, maxLife: 0.65, color: Color(hex: 0xFBBF24),
                stroke: 1, inner: 0.035, outer: 0.09
            ))
        }
        GameAudio.shared.play(.upgradeDone)
    }

    private func tickRobot(_ enemy: Enemy, _ dt: Float) {
        if enemy.counterAttackLeft > 0 {
            if let target = enemy.targetTower, target.health > 0, towers.contains(where: { $0 === target }) {
                damageTower(target, amount: robotDrainPerSecond * dt)
                if target.health <= 0 { releaseRobot(enemy) }
            } else {
                releaseRobot(enemy)
            }
            return
        }
        guard enemy.specialCooldown <= 0, enemy.along >= 0 else { return }
        guard let target = nearestBoardableTower(enemy) else { return }
        enemy.targetTower = target
        enemy.counterAttackLeft = 1
        enemy.counterAttackTotal = 1
        GameAudio.shared.play(.robotRoar)
    }

    private func releaseRobot(_ enemy: Enemy) {
        enemy.targetTower = nil
        enemy.counterAttackLeft = 0
        enemy.counterAttackTotal = 0
        enemy.specialCooldown = 2
    }

    private func nearestBoardableTower(_ enemy: Enemy) -> Tower? {
        guard let position = tileOf(enemy) else { return nil }
        var best: Tower?
        var bestDistance = robotBoardReach
        for tower in towers where tower.health > 0 && tower.upgradeLeft <= 0 && tower.repairLeft <= 0 {
            if robotRiding(tower) { continue }
            let distance = hypotf(
                position.0 + 0.5 - (Float(tower.column) + 0.5),
                position.1 + 0.5 - (Float(tower.row) + 0.5)
            )
            if distance <= bestDistance && distance <= reachOf(tower.kind, tower.level) {
                bestDistance = distance
                best = tower
            }
        }
        return best
    }

    private func robotRiding(_ tower: Tower) -> Bool {
        enemies.contains { $0.alive && $0.kind == .robot && $0.counterAttackLeft > 0 && $0.targetTower === tower }
    }

    private func damageTower(_ tower: Tower, amount: Float) {
        let maxHealth = towerMaxHealth(tower.level)
        tower.health = max(0, tower.health - amount)
        if tower.repairLeft > 0 {
            tower.repairTotal = max(1, 3 * (maxHealth - tower.health) / maxHealth)
            tower.repairLeft = tower.repairTotal
        }
    }

    private func distanceTo(_ tower: Tower, _ enemy: Enemy) -> Float {
        guard let position = tileOf(enemy) else { return .greatestFiniteMagnitude }
        return hypotf(
            position.0 + 0.5 - (Float(tower.column) + 0.5),
            position.1 + 0.5 - (Float(tower.row) + 0.5)
        )
    }

    private func nearest(_ tower: Tower) -> Enemy? {
        var best: Enemy?
        var bestDistance = reachOf(tower.kind, tower.level)
        for enemy in enemies where enemy.alive {
            let distance = distanceTo(tower, enemy)
            if distance <= bestDistance {
                bestDistance = distance
                best = enemy
            }
        }
        return best
    }

    private func enemiesInCone(_ tower: Tower, _ aimX: Float, _ aimY: Float, _ dotLimit: Float) -> [Enemy] {
        let aimLen = hypotf(aimX, aimY)
        let range = reachOf(tower.kind, tower.level)
        var hits: [Enemy] = []
        for enemy in enemies where enemy.alive {
            guard let position = tileOf(enemy) else { continue }
            let dx = position.0 + 0.5 - (Float(tower.column) + 0.5)
            let dy = position.1 + 0.5 - (Float(tower.row) + 0.5)
            let distance = hypotf(dx, dy)
            if distance <= 0.05 {
                hits.append(enemy)
                continue
            }
            guard aimLen >= 0.001, distance <= range else { continue }
            let dot = (dx * aimX + dy * aimY) / (distance * aimLen)
            if dot >= dotLimit { hits.append(enemy) }
        }
        return hits
    }
}

private struct HeartIcon: View {
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: 0xFB7185))
            .frame(width: 16, height: 16)
    }
}

private struct CoinIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFBBF24))
            Circle().stroke(Color(hex: 0xB45309), lineWidth: 1.4)
            Circle().stroke(Color(hex: 0xFDE68A), lineWidth: 0.7).padding(2.4)
        }
        .frame(width: 15, height: 15)
    }
}

private struct DynamiteIcon: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(hex: 0xFBBF24))
                .frame(width: 4, height: 4)
            Rectangle()
                .fill(Color(hex: 0x78716C))
                .frame(width: 1.5, height: 3)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(hex: 0xEF4444))
                .frame(width: 8, height: 9)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(hex: 0xFDE68A))
                        .frame(height: 2)
                        .padding(.top, 2)
                }
        }
        .frame(width: 16, height: 16)
    }
}

private func hypotf(_ a: Float, _ b: Float) -> Float { sqrt(a * a + b * b) }

private struct NextWaveMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.maxY))
        path.closeSubpath()
        path.addRect(CGRect(
            x: rect.minX + rect.width * 0.84,
            y: rect.minY,
            width: rect.width * 0.14,
            height: rect.height
        ))
        return path
    }
}

private enum GameScreen: Equatable {
    case title, briefing, playing, credits
}

struct DefenseScreen: View {
    @State private var seed = 0
    @State private var game = DefenseGame()
    @State private var dragFromColumn = -1
    @State private var dragFromRow = -1
    @State private var dragLocation = CGPoint.zero
    @State private var dragActive = false
    @State private var screen = GameScreen.title
    @State private var language = AppLanguage.load()
    @State private var showSettings = false
    @State private var effectsEnabled = GameAudio.shared.effectsEnabled
    @State private var musicEnabled = GameAudio.shared.musicEnabled
    @State private var tipIndex = 0
    @State private var tipEpoch = 0
    @State private var pendingSave: SavedGame?
    @State private var lastInput = Date()
    @State private var showSaver = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let _ = GameCopy.use(language)
        Group {
            switch screen {
            case .title: titleScreen
            case .briefing: briefingScreen
            case .playing: gameScreen
            case .credits: creditsScreen
            }
        }
        .background(Color(hex: 0x12151C))
        .overlay { if showSaver { screenSaver } }
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in noteActivity() })
        .sheet(isPresented: $showSettings) { settingsScreen }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            GameAudio.shared.startMusic()
        }
        .onChange(of: scenePhase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = phase == .active
            if phase == .inactive || phase == .background { persistGame() }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            if !showSaver && now.timeIntervalSince(lastInput) >= screenSaverDelay {
                showSaver = true
                game.screensaver = lockPausesGame
            }
        }
        .alert(
            SaveText.title(language),
            isPresented: Binding(get: { pendingSave != nil }, set: { if !$0 { pendingSave = nil } }),
            presenting: pendingSave
        ) { saved in
            Button(SaveText.resume(language)) { resumeSaved(saved) }
            Button(SaveText.newGame(language)) { startFresh() }
        } message: { saved in
            Text(SaveText.message(language, stage: saved.stage, wave: saved.wave))
        }
    }

    private func noteActivity() {
        lastInput = Date()
    }

    private func unlockSaver() {
        lastInput = Date()
        showSaver = false
        game.screensaver = false
    }

    private var screenSaver: some View {
        LockOverlay(language: language) { unlockSaver() }
    }

    private func persistGame() {
        guard screen == .playing || screen == .briefing else { return }
        if !game.running || game.won {
            SavedGameStore.clear()
        } else if game.hasProgress {
            SavedGameStore.save(stage: game.stage, wave: game.wave, state: game.toSaveJson())
        }
    }

    private func startFresh() {
        SavedGameStore.clear()
        pendingSave = nil
        game = DefenseGame()
        seed += 1
        screen = .briefing
    }

    private func resumeSaved(_ saved: SavedGame) {
        let restored = DefenseGame()
        pendingSave = nil
        guard restored.restoreFromSaveJson(saved.state) else {
            startFresh()
            return
        }
        game = restored
        seed += 1
        screen = restored.awaitingBriefing ? .briefing : .playing
    }

    private var gameScreen: some View {
        let _ = game.frame
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(GameCopy.current.stageWord)
                        .font(.system(size: 12, weight: .bold))
                    Text("\(game.stage)")
                        .font(.system(size: 28, weight: .black))
                }
                .lineLimit(1)
                .fixedSize()
                Spacer(minLength: 6)
                HStack(spacing: 8) {
                    headerStat(value: game.lives, label: GameCopy.current.lives) { HeartIcon() }
                    headerStat(value: game.gold, label: GameCopy.current.gold) { CoinIcon() }
                    mineUpgradeArrow
                }
                .fixedSize()
                Button {
                    game.cycleSpeed()
                    game.frame += 1
                } label: {
                    Text(game.speedLabel)
                        .font(.system(size: 14, weight: .black))
                        .frame(width: 32, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Speed \(game.speedLabel)")
                Button {
                    game.paused.toggle()
                    game.frame += 1
                } label: {
                    Image(systemName: game.paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16, weight: .black))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(game.paused ? "Play" : "Pause")
                Button {
                    game.launchWave()
                    game.frame += 1
                } label: {
                    let ready = game.running && !game.won && game.wave < wavesPerStage && !game.enemies.contains { $0.alive }
                    NextWaveMark()
                        .fill(ready ? Color.white : Color.white.opacity(0.35))
                        .frame(width: 16, height: 16)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(GameCopy.current.waveWord)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            board
                .overlay { bossWarning }
                .overlay {
                    if game.paused {
                        Color.black.opacity(0.4)
                    }
                }
            AdMobBannerView()
                .frame(width: 320, height: 50)
                .frame(maxWidth: .infinity)
            HStack(spacing: 6) {
                ForEach(WeaponKind.allCases, id: \.self) { kind in
                    gaugeWeaponButton(kind)
                }
            }
            HStack(spacing: 8) {
                Button(GameCopy.current.mine) {
                    game.buyOrPlaceMine()
                    game.frame += 1
                }
                .buttonStyle(.borderedProminent)
                .tint(game.isPathSelected ? Color(hex: 0xF97316) : Color.accentColor)
                .disabled(!game.canUseMineButton)
                .frame(maxWidth: .infinity)

                recallButton

                cancelUpgradeButton

                Button(GameCopy.current.retry) {
                    startFresh()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.55)
        }
        .padding(12)
        .background(Color(hex: 0x12151C))
        .task(id: showSettings) {
            let active = game
            while !Task.isCancelled && active.running && screen == .playing && !showSettings {
                try? await Task.sleep(nanoseconds: 16_000_000)
                if !active.screensaver {
                    if active.speed >= 1 {
                        for _ in 0..<Int(active.speed) { active.update(dt: 0.016) }
                    } else {
                        active.update(dt: 0.016 * active.speed)
                    }
                }
                if !active.running || active.won { SavedGameStore.clear() }
                if active.won {
                    screen = .credits
                    break
                }
                if active.awaitingBriefing {
                    screen = .briefing
                    break
                }
            }
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "ver \(version)"
    }

    private var titleScreen: some View {
        ZStack(alignment: .topTrailing) {
            tacticalBackground
                .ignoresSafeArea()
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if let saved = SavedGameStore.load() {
                        pendingSave = saved
                    } else {
                        startFresh()
                    }
                }
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                Text("GILMOK")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(.white)
                Text(GameCopy.current.routeDefense)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0x94A3B8))
                Text(versionText)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Text(GameCopy.current.pressAnywhere)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)
            .allowsHitTesting(false)
            settingsGear
                .padding(.top, 8)
                .zIndex(1)
        }
    }

    private var settingsGear: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 22))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.08), in: Circle())
            .contentShape(Circle())
            .highPriorityGesture(TapGesture().onEnded { showSettings = true })
    }

    private var briefingScreen: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    game.beginBriefedStage()
                    screen = .playing
                }
            VStack(alignment: .leading, spacing: 14) {
                Text(GameCopy.current.missionBriefing)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0xFBBF24))
                    .allowsHitTesting(false)
                HStack {
                    Text(GameCopy.current.stageLine(game.stage))
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(game.stage)/\(stageCount)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x94A3B8))
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white)
                }
                .allowsHitTesting(false)
                briefingTip
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(GameCopy.current.briefings[min(game.stage - 1, stageCount - 1)])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(5)
                    .allowsHitTesting(false)
                Spacer(minLength: 4)
                Text(GameCopy.current.pressAnywhere)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .allowsHitTesting(false)
            }
            .padding(20)
            settingsGear
                .padding(.top, 58)
                .zIndex(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: 0x12151C))
        .task(id: "\(language.rawValue)-\(tipEpoch)") {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            let count = BriefingTips.lines(language).count
            if count > 0 {
                tipIndex = (tipIndex + 1) % count
            }
            tipEpoch += 1
        }
    }

    private var briefingTip: some View {
        let tips = BriefingTips.lines(language)
        let index = tips.isEmpty ? 0 : tipIndex % tips.count
        return VStack(spacing: 16) {
            Text(BriefingTips.label(language))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Color(hex: 0xFBBF24))
            tipExample(index)
            Text(tips.isEmpty ? "" : tips[index])
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .frame(maxWidth: .infinity)
            HStack(spacing: 6) {
                ForEach(tips.indices, id: \.self) { dot in
                    Circle()
                        .fill(dot == index ? Color(hex: 0xFBBF24) : Color.white.opacity(0.28))
                        .frame(width: dot == index ? 8 : 6, height: dot == index ? 8 : 6)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0x1B212C), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    let count = tips.count
                    guard count > 0 else { return }
                    if value.translation.width <= -40 {
                        tipIndex = (tipIndex + 1) % count
                    } else if value.translation.width >= 40 {
                        tipIndex = (tipIndex - 1 + count) % count
                    }
                    tipEpoch += 1
                }
        )
        .onTapGesture { tipEpoch += 1 }
    }

    private func tipExample(_ index: Int) -> some View {
        Canvas { context, size in
            func tile(_ column: Int, _ row: Int, _ columns: Int, _ rows: Int, _ path: Bool) -> CGPoint {
                let gap: CGFloat = 8
                let width = (size.width - gap * CGFloat(columns + 1)) / CGFloat(columns)
                let height = (size.height - gap * CGFloat(rows + 1)) / CGFloat(rows)
                let left = gap + CGFloat(column) * (width + gap)
                let top = gap + CGFloat(row) * (height + gap)
                let rect = CGRect(x: left, y: top, width: width, height: height)
                context.fill(Path(rect), with: .color(path ? Color(hex: 0x3A4658) : Color.white.opacity(0.07)))
                return CGPoint(x: left + width / 2, y: top + height / 2)
            }
            func tower(_ at: CGPoint, _ radius: CGFloat, _ color: Color, _ level: String) {
                var circle = Path()
                circle.addEllipse(in: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2))
                context.fill(circle, with: .color(color))
                context.draw(
                    Text(level).font(.system(size: radius * 0.85, weight: .black)).foregroundStyle(Color(hex: 0x1C1408)),
                    at: at
                )
            }
            func arrow(_ from: CGPoint, _ to: CGPoint) {
                var line = Path()
                line.move(to: from)
                line.addLine(to: to)
                context.stroke(line, with: .color(Color(hex: 0xFBBF24)), lineWidth: 4)
                let angle = atan2(to.y - from.y, to.x - from.x)
                var head = Path()
                head.move(to: to)
                head.addLine(to: CGPoint(x: to.x - cos(angle - 0.45) * 14, y: to.y - sin(angle - 0.45) * 14))
                head.addLine(to: CGPoint(x: to.x - cos(angle + 0.45) * 14, y: to.y - sin(angle + 0.45) * 14))
                head.closeSubpath()
                context.fill(head, with: .color(Color(hex: 0xFBBF24)))
            }
            switch index {
            case 0:
                let from = tile(0, 0, 4, 1, false)
                _ = tile(1, 0, 4, 1, false)
                let to = tile(2, 0, 4, 1, false)
                _ = tile(3, 0, 4, 1, false)
                let radius = size.height * 0.22
                tower(from, radius, Color(hex: 0xF8FAFC), "1")
                var ghost = Path()
                ghost.addEllipse(in: CGRect(x: to.x - radius, y: to.y - radius, width: radius * 2, height: radius * 2))
                context.stroke(ghost, with: .color(Color.white.opacity(0.45)), lineWidth: 3)
                arrow(CGPoint(x: from.x + radius + 8, y: from.y), CGPoint(x: to.x - radius - 10, y: to.y))
            case 1:
                let left = tile(0, 0, 3, 1, false)
                let mid = tile(1, 0, 3, 1, false)
                let right = tile(2, 0, 3, 1, false)
                let radius = size.height * 0.22
                tower(left, radius, Color(hex: 0xF43F5E), "7")
                tower(mid, radius, Color(hex: 0xF43F5E), "7")
                arrow(CGPoint(x: mid.x + radius + 6, y: mid.y), CGPoint(x: right.x - radius - 8, y: right.y))
                tower(right, radius, Color(hex: 0xFB923C), "8")
            case 2:
                let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
                var body = Path()
                body.addEllipse(in: CGRect(x: center.x - 78 - 18, y: center.y + 8 - 18, width: 36, height: 36))
                context.fill(body, with: .color(Color(hex: 0xEF4444)))
                var fuse = Path()
                fuse.addEllipse(in: CGRect(x: center.x - 78 - 6, y: center.y - 22 - 6, width: 12, height: 12))
                context.fill(fuse, with: .color(Color(hex: 0xFBBF24)))
                context.draw(Text("20").font(.system(size: 28, weight: .black)).foregroundStyle(.white), at: CGPoint(x: center.x - 18, y: center.y))
                var up = Path()
                up.move(to: CGPoint(x: center.x + 48, y: center.y - 16))
                up.addLine(to: CGPoint(x: center.x + 68, y: center.y + 16))
                up.addLine(to: CGPoint(x: center.x + 28, y: center.y + 16))
                up.closeSubpath()
                context.fill(up, with: .color(Color(hex: 0xFBBF24)))
                context.draw(Text("1").font(.system(size: 20, weight: .black)).foregroundStyle(.white), at: CGPoint(x: center.x + 92, y: center.y))
                let track = CGRect(x: center.x - 90, y: size.height * 0.72, width: 180, height: 10)
                context.fill(Path(roundedRect: track, cornerRadius: 5), with: .color(Color.white.opacity(0.28)))
                context.fill(Path(roundedRect: CGRect(x: track.minX, y: track.minY, width: 90, height: 10), cornerRadius: 5), with: .color(Color(hex: 0xFBBF24)))
            case 3:
                let at = tile(0, 0, 1, 1, false)
                let radius = size.height * 0.24
                var glow = Path()
                glow.addEllipse(in: CGRect(x: at.x - radius - 18, y: at.y - radius - 18, width: (radius + 18) * 2, height: (radius + 18) * 2))
                context.fill(glow, with: .color(Color(hex: 0xFBBF24).opacity(0.18)))
                tower(at, radius, Color(hex: 0x38BDF8), "3")
            case 4:
                let above = tile(1, 0, 3, 2, false)
                _ = tile(0, 0, 3, 2, false)
                _ = tile(2, 0, 3, 2, false)
                let path = tile(1, 1, 3, 2, true)
                _ = tile(0, 1, 3, 2, true)
                _ = tile(2, 1, 3, 2, true)
                tower(above, size.height * 0.12, Color(hex: 0xF8FAFC), "1")
                var mine = Path()
                mine.addEllipse(in: CGRect(x: path.x - size.height * 0.1, y: path.y - size.height * 0.1, width: size.height * 0.2, height: size.height * 0.2))
                context.fill(mine, with: .color(Color(hex: 0xEF4444)))
            case 5:
                _ = tile(0, 0, 3, 1, true)
                _ = tile(1, 0, 3, 1, true)
                let end = tile(2, 0, 3, 1, true)
                context.draw(Text("10s").font(.system(size: 22, weight: .black)).foregroundStyle(Color(hex: 0xFBBF24)), at: end)
            case 6:
                let at = tile(0, 0, 1, 1, false)
                let radius = size.height * 0.22
                tower(at, radius, Color(hex: 0xF8FAFC), "2")
                let bar = size.width * 0.28
                let left = CGPoint(x: at.x - bar / 2, y: at.y + radius + 16)
                context.fill(Path(CGRect(x: left.x, y: left.y, width: bar, height: 8)), with: .color(.black))
                context.fill(Path(CGRect(x: left.x, y: left.y, width: bar * 0.4, height: 8)), with: .color(Color(hex: 0x4ADE80)))
            default:
                let at = tile(0, 0, 2, 1, false)
                _ = tile(1, 0, 2, 1, false)
                tower(at, size.height * 0.2, Color(hex: 0xF8FAFC), "1")
                let coin = CGPoint(x: size.width * 0.72, y: size.height / 2)
                let coinRadius = size.height * 0.22
                var coinPath = Path()
                coinPath.addEllipse(in: CGRect(x: coin.x - coinRadius, y: coin.y - coinRadius, width: coinRadius * 2, height: coinRadius * 2))
                context.fill(coinPath, with: .color(Color(hex: 0xFBBF24)))
                context.draw(Text("80%").font(.system(size: 16, weight: .black)).foregroundStyle(Color(hex: 0x1C1408)), at: coin)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .background(Color(hex: 0x12151C), in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var creditsScreen: some View {
        ZStack {
            tacticalBackground
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Color(hex: 0x4ADE80))
                Text(GameCopy.current.allComplete)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(.white)
                Text(GameCopy.current.createdBy)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0x94A3B8))
                    .padding(.top, 24)
                Text("JH JANG")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                Spacer()
                Button(GameCopy.current.backToTitle) {
                    game = DefenseGame()
                    seed += 1
                    screen = .title
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0xFBBF24))
                .foregroundStyle(Color(hex: 0x1C1408))
                .font(.system(size: 17, weight: .black))
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .padding(28)
        }
        .ignoresSafeArea()
    }

    private var settingsScreen: some View {
        ZStack {
            Color(hex: 0x12151C).ignoresSafeArea()
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { showSettings = false }
            VStack(alignment: .leading, spacing: 16) {
                Text(GameCopy.current.settings)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
                Picker(GameCopy.current.language, selection: $language) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
                Toggle(GameCopy.current.soundEffects, isOn: $effectsEnabled)
                    .tint(Color(hex: 0xFBBF24))
                Toggle(GameCopy.current.backgroundMusic, isOn: $musicEnabled)
                    .tint(Color(hex: 0xFBBF24))
                Text(GameCopy.current.audioNote)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0x94A3B8))
                Spacer()
                Text(GameCopy.current.pressAnywhere)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .allowsHitTesting(false)
            }
            .padding(24)
            .foregroundStyle(.white)
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in noteActivity() })
        .overlay { if showSaver { screenSaver } }
        .onChange(of: language) { _, newValue in
            newValue.save()
        }
        .onChange(of: effectsEnabled) { _, enabled in
            GameAudio.shared.setEffectsEnabled(enabled)
        }
        .onChange(of: musicEnabled) { _, enabled in
            GameAudio.shared.setMusicEnabled(enabled)
        }
        .presentationDetents([.large])
    }

    private var tacticalBackground: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x0F172A)))
            let step: CGFloat = 32
            for x in stride(from: CGFloat.zero, through: size.width, by: step) {
                var line = Path()
                line.move(to: CGPoint(x: x, y: 0))
                line.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(line, with: .color(Color.white.opacity(0.035)), lineWidth: 1)
            }
            for y in stride(from: CGFloat.zero, through: size.height, by: step) {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(Color.white.opacity(0.035)), lineWidth: 1)
            }
        }
    }

    private var bossIncoming: Bool {
        game.running && game.enemies.isEmpty && game.wave == wavesPerStage - 1
    }

    private var bossWarning: some View {
        let on = (game.frame / 8) % 2 == 0
        return VStack {
            if bossIncoming {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(GameCopy.current.bossIncoming)
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(on ? Color(hex: 0xFEF3C7) : Color(hex: 0xFBBF24))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: 0x7F1D1D).opacity(on ? 0.95 : 0.45), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: 0xFBBF24).opacity(on ? 1 : 0.25), lineWidth: on ? 3 : 1)
                }
                .opacity(on ? 1 : 0.35)
                .padding(.top, 10)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private func headerStat<Icon: View>(value: Int, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 3) {
            icon()
            Text("\(value)")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value)")
    }

    private var mineUpgradeArrow: some View {
        let upgrading = game.mineUpgradeLeft > 0
        let maxed = game.mineLevel >= mineMaxLevel
        let cost = maxed ? 0 : mineUpgradeCost(game.mineLevel)
        let canUpgrade = game.running && !maxed && !upgrading && game.gold >= cost
        let progress = upgrading && game.mineUpgradeTotal > 0 ? CGFloat(1 - game.mineUpgradeLeft / game.mineUpgradeTotal) : 0
        return VStack(spacing: 2) {
            HStack(spacing: 3) {
                DynamiteIcon()
                Text("\(game.mineStock)")
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(canUpgrade || upgrading ? Color(hex: 0xFBBF24) : Color.white.opacity(0.35))
                Text("\(game.mineLevel)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(upgrading ? Color(hex: 0xFBBF24) : .white)
            }
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(upgrading ? 0.35 : 0.12))
                Capsule()
                    .fill(Color(hex: 0xFBBF24))
                    .frame(width: upgrading ? 64 * progress : 0)
            }
            .frame(width: 64, height: 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            game.upgradeMine()
            game.frame += 1
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameCopy.current.mineAccess(maxed: maxed, cost: cost))
        .accessibilityAddTraits(.isButton)
    }

    private func gaugeWeaponButton(_ kind: WeaponKind) -> some View {
        let selected = game.placeKind == kind
        let cost = towerCost(kind)
        let ready = game.canBuildTower(kind)
        let progress = CGFloat(min(1, max(0, game.buildGauge / Float(cost))))
        let fillColor = selected ? Color(hex: 0xFBBF24) : Color.accentColor
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        return Button {
            game.placeKind = kind
            game.frame += 1
        } label: {
            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Color(hex: 0x1B202B)
                        fillColor
                            .opacity(ready ? 1 : 0.55)
                            .frame(width: geo.size.width * progress)
                    }
                }
                VStack(spacing: 0) {
                    Text(kind.label)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("\(cost)")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.8)
                }
                .foregroundStyle(
                    ready
                        ? (selected ? Color(hex: 0x1C1408) : .white)
                        : Color.white.opacity(0.35)
                )
                .frame(maxWidth: .infinity)
            }
            .frame(height: 40)
            .clipShape(shape)
            .overlay(
                shape.stroke(selected ? Color(hex: 0xFBBF24).opacity(ready ? 1 : 0.5) : Color.white.opacity(0.08), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var cancelUpgradeButton: some View {
        let refund = game.cancelUpgradeRefund
        return Button(refund > 0 ? "✕ +\(refund)" : "✕") {
            game.cancelUpgrade()
            game.frame += 1
        }
        .buttonStyle(.borderedProminent)
        .tint(refund > 0 ? Color(hex: 0xDC2626) : Color.accentColor)
        .disabled(!(game.running && refund > 0))
        .frame(maxWidth: .infinity)
    }

    private var recallButton: some View {
        let refund = game.recallRefund()
        let label = GameCopy.current.recall(refund)
        return Button(label) {
            game.recallSelected()
            game.frame += 1
        }
        .buttonStyle(.borderedProminent)
        .disabled(!(game.running && refund > 0))
        .frame(maxWidth: .infinity)
    }

    private var board: some View {
        GeometryReader { geo in
            let cell = geo.size.width / CGFloat(cols)
            Canvas { context, size in
                func center(_ x: Float, _ y: Float) -> CGPoint {
                    CGPoint(x: CGFloat(x) * cell, y: CGFloat(y) * cell)
                }
                for row in 0..<rows {
                    for column in 0..<cols {
                        let onPath = game.isPathCell(column: column, row: row)
                        let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell - 1, height: cell - 1)
                        context.fill(Path(rect), with: .color(onPath ? Color(hex: 0x3A4658) : Color.white.opacity(0.04)))
                    }
                }
                let base = game.home
                for entrance in game.entrances {
                    fillCircle(&context, center(Float(entrance.0) + 0.5, Float(entrance.1) + 0.5), cell * 0.28, Color(hex: 0x86EFAC))
                }
                let baseAt = center(Float(base.0) + 0.5, Float(base.1) + 0.5)
                fillCircle(&context, baseAt, cell * 0.28, Color(hex: 0xFDA4AF))
                for tower in game.towers {
                    let dragging = dragActive && tower.column == dragFromColumn && tower.row == dragFromRow
                    let at = dragging ? dragLocation : center(Float(tower.column) + 0.5, Float(tower.row) + 0.5)
                    let selected = tower.column == game.selectedColumn && tower.row == game.selectedRow
                    if selected {
                        fillCircle(&context, at, reachOf(tower.kind, tower.level) * Float(cell), levelColor(tower.level).opacity(0.16))
                    }
                    drawWeapon(&context, tower.kind, at, cell * 0.34, levelColor(tower.level))
                    context.draw(
                        Text("\(tower.level)").font(.system(size: cell * 0.34, weight: .bold)).foregroundStyle(.white),
                        at: at
                    )
                    if tower.upgradeTotal > 0 {
                        let radius = cell * 0.5
                        strokeCircle(&context, at, radius, Color.white.opacity(0.25), 3)
                        let progress = CGFloat(1 - tower.upgradeLeft / tower.upgradeTotal)
                        var arc = Path()
                        arc.addArc(
                            center: at,
                            radius: radius,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * progress),
                            clockwise: false
                        )
                        context.stroke(arc, with: .color(Color(hex: 0xFBBF24)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                    if tower.health < towerMaxHealth(tower.level) {
                        let width = cell * 0.72
                        let maxHealth = towerMaxHealth(tower.level)
                        let bar = CGRect(x: at.x - width / 2, y: at.y + cell * 0.38, width: width, height: 4)
                        context.fill(Path(bar), with: .color(.black))
                        context.fill(Path(CGRect(x: bar.minX, y: bar.minY, width: bar.width * CGFloat(tower.health / maxHealth), height: 4)), with: .color(Color(hex: 0x4ADE80)))
                    }
                    if tower.repairTotal > 0 {
                        let radius = cell * 0.55
                        strokeCircle(&context, at, radius, Color.white.opacity(0.22), 3)
                        let progress = CGFloat(1 - tower.repairLeft / tower.repairTotal)
                        var arc = Path()
                        arc.addArc(center: at, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress), clockwise: false)
                        context.stroke(arc, with: .color(Color(hex: 0x4ADE80)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                    if selected {
                        strokeCircle(&context, at, cell * 0.46, Color(hex: 0x22D3EE), 4)
                    }
                    if tower.kind == .laser && tower.beamOn {
                        var beam = Path()
                        beam.move(to: at)
                        beam.addLine(to: center(tower.aimX, tower.aimY))
                        context.stroke(beam, with: .color(levelColor(tower.level)), lineWidth: 2 + 8 * CGFloat(tower.laserCharge))
                    }
                }
                if game.isPathSelected {
                    let at = center(Float(game.selectedPathColumn) + 0.5, Float(game.selectedPathRow) + 0.5)
                    strokeCircle(&context, at, cell * 0.46, Color(hex: 0xFB923C), 3)
                }
                for mine in game.mines where mine.count > 0 {
                    let at = center(Float(mine.column) + 0.5, Float(mine.row) + 0.5)
                    let radius = cell * 0.3
                    let level = mine.levels.first ?? 1
                    if mine.count > 1 {
                        drawPentagon(&context, CGPoint(x: at.x - 3, y: at.y + 3), radius, levelColor(level).opacity(0.7))
                    }
                    drawPentagon(&context, at, radius, levelColor(level))
                    context.draw(
                        Text("\(mine.count)").font(.system(size: cell * 0.32, weight: .bold)).foregroundStyle(level == 1 ? Color(hex: 0x1C1408) : .white),
                        at: at
                    )
                }
                for enemy in game.enemies {
                    guard let position = game.tileOf(enemy) else { continue }
                    var at = center(position.0 + 0.5, position.1 + 0.5)
                    if enemy.kind == .robot, enemy.counterAttackLeft > 0, let target = enemy.targetTower {
                        let targetAt = center(Float(target.column) + 0.5, Float(target.row) + 0.5)
                        at = targetAt
                        strokeCircle(&context, targetAt, cell * 0.4, Color(hex: 0x22D3EE).opacity(0.75), 3)
                    }
                    if enemy.counterAttackLeft > 0, let target = enemy.targetTower {
                        let targetAt = center(Float(target.column) + 0.5, Float(target.row) + 0.5)
                        if enemy.kind == .tank {
                            var attack = Path()
                            attack.move(to: at)
                            attack.addLine(to: targetAt)
                            context.stroke(attack, with: .color(Color(hex: 0xF97316)), style: StrokeStyle(lineWidth: 3, dash: [5, 3]))
                        }
                    }
                    if enemy.boss {
                        let scale: CGFloat = enemy.bossStyle == 3 ? [0.48, 0.36, 0.26][enemy.splitLevel] : 0.48
                        if enemy.bossStyle == 3 && enemy.splitLevel == 2 {
                            fillCircle(&context, at, cell * scale, Color(hex: 0xFB7185))
                        } else if enemy.bossStyle == 1 {
                            drawRegularPolygon(&context, at, cell * scale, 4, Color(hex: 0xFBBF24))
                            drawRegularPolygon(&context, at, cell * scale * 0.76, 4, Color(hex: 0x7C3AED))
                        } else if enemy.bossStyle == 2 {
                            drawRegularPolygon(&context, at, cell * scale, 6, Color(hex: 0xFBBF24))
                            drawRegularPolygon(&context, at, cell * scale * 0.76, 6, Color(hex: 0xDC2626))
                        } else if enemy.bossStyle == 3 {
                            drawRegularPolygon(&context, at, cell * scale, enemy.splitLevel == 0 ? 6 : 4, Color(hex: 0x22D3EE))
                        } else {
                            fillCircle(&context, at, cell * scale, Color(hex: 0xFBBF24))
                            fillCircle(&context, at, cell * scale * 0.8, Color(hex: 0x6D28D9))
                        }
                    } else {
                        switch enemy.kind {
                        case .normal:
                            fillCircle(&context, at, cell * 0.26, Color(hex: 0xFB7185))
                        case .dog:
                            drawRegularPolygon(&context, at, cell * 0.29, 3, Color(hex: 0xFB923C))
                        case .robot:
                            drawRegularPolygon(&context, at, cell * 0.32, 5, Color(hex: 0x94A3B8))
                        case .tank:
                            let side = cell * 0.56
                            let body = CGRect(x: at.x - side / 2, y: at.y - side / 2, width: side, height: side)
                            context.fill(Path(body), with: .color(Color(hex: 0x65A30D)))
                            context.stroke(Path(body), with: .color(Color(hex: 0x7C2D12)), lineWidth: 1.5)
                        case .ufo:
                            let body = CGRect(x: at.x - cell * 0.38, y: at.y - cell * 0.13, width: cell * 0.76, height: cell * 0.26)
                            context.fill(Path(ellipseIn: body), with: .color(Color(hex: 0xFBBF24)))
                            fillCircle(&context, CGPoint(x: at.x, y: at.y - cell * 0.1), cell * 0.16, Color(hex: 0x38BDF8))
                        }
                    }
                    if enemy.stun > 0 {
                        strokeCircle(&context, at, cell * (enemy.boss ? 0.56 : 0.36), Color(hex: 0x67E8F9), 2)
                    }
                    if enemy.poisonLeft > 0 {
                        strokeCircle(&context, at, cell * (enemy.boss ? 0.64 : 0.42), Color(hex: 0x4ADE80), 2)
                    }
                    let ratio = min(1, max(0, enemy.hp / enemy.maxHp))
                    let barWidth = enemy.boss ? cell * 1.15 : cell * 0.6
                    let barHeight: CGFloat = enemy.boss ? 7 : 4
                    let bar = CGRect(x: at.x - barWidth / 2, y: at.y - cell * 0.56, width: barWidth, height: barHeight)
                    context.fill(Path(bar), with: .color(.black))
                    context.fill(Path(CGRect(x: bar.minX, y: bar.minY, width: bar.width * CGFloat(ratio), height: barHeight)), with: .color(enemy.boss ? Color(hex: 0xFBBF24) : Color(hex: 0x4ADE80)))
                }
                for effect in game.effects {
                    let alpha = min(1, max(0, effect.life / effect.maxLife))
                    switch effect.kind {
                    case .line:
                        var line = Path()
                        line.move(to: center(effect.x1, effect.y1))
                        line.addLine(to: center(effect.x2, effect.y2))
                        context.stroke(line, with: .color(effect.color.opacity(Double(alpha))), lineWidth: CGFloat(effect.stroke))
                    case .blast:
                        let at = center(effect.x1, effect.y1)
                        fillCircle(&context, at, effect.outer * Float(cell), effect.color.opacity(0.22 * Double(alpha)))
                        fillCircle(&context, at, effect.inner * Float(cell), effect.color.opacity(0.5 * Double(alpha)))
                    }
                }
            }
            .background(Color(hex: 0x1B212C))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let moved = hypot(value.translation.width, value.translation.height) > 12
                        let column = Int(value.startLocation.x / cell)
                        let row = Int(value.startLocation.y / cell)
                        guard moved, game.towers.contains(where: { $0.column == column && $0.row == row }) else { return }
                        dragFromColumn = column
                        dragFromRow = row
                        dragLocation = value.location
                        dragActive = true
                    }
                    .onEnded { value in
                        let startColumn = Int(value.startLocation.x / cell)
                        let startRow = Int(value.startLocation.y / cell)
                        let endColumn = Int(value.location.x / cell)
                        let endRow = Int(value.location.y / cell)
                        let moved = hypot(value.translation.width, value.translation.height) > 12
                        let startedOnTower = game.towers.contains { $0.column == startColumn && $0.row == startRow }
                        if moved && startedOnTower {
                            game.moveOrMerge(fromColumn: startColumn, fromRow: startRow, toColumn: endColumn, toRow: endRow)
                        } else {
                            game.onBoardTap(column: startColumn, row: startRow)
                        }
                        dragFromColumn = -1
                        dragFromRow = -1
                        dragActive = false
                        game.frame += 1
                    }
            )
        }
        .aspectRatio(CGFloat(cols) / CGFloat(rows), contentMode: .fit)
    }
}

private func fillCircle(_ context: inout GraphicsContext, _ at: CGPoint, _ radius: CGFloat, _ color: Color) {
    context.fill(Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
}

private func fillCircle(_ context: inout GraphicsContext, _ at: CGPoint, _ radius: Float, _ color: Color) {
    fillCircle(&context, at, CGFloat(radius), color)
}

private func strokeCircle(_ context: inout GraphicsContext, _ at: CGPoint, _ radius: CGFloat, _ color: Color, _ width: CGFloat) {
    context.stroke(
        Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2)),
        with: .color(color),
        lineWidth: width
    )
}

private func drawPentagon(_ context: inout GraphicsContext, _ at: CGPoint, _ radius: CGFloat, _ color: Color) {
    drawRegularPolygon(&context, at, radius, 5, color)
}

private func drawRegularPolygon(_ context: inout GraphicsContext, _ at: CGPoint, _ radius: CGFloat, _ sides: Int, _ color: Color) {
    var shape = Path()
    for index in 0..<sides {
        let angle = (CGFloat.pi * 2 / CGFloat(sides)) * CGFloat(index) - CGFloat.pi / 2
        let point = CGPoint(x: at.x + cos(angle) * radius, y: at.y + sin(angle) * radius)
        if index == 0 { shape.move(to: point) } else { shape.addLine(to: point) }
    }
    shape.closeSubpath()
    context.fill(shape, with: .color(color))
    context.stroke(shape, with: .color(Color(hex: 0x7C2D12)), lineWidth: 1.5)
}

private func drawWeapon(_ context: inout GraphicsContext, _ kind: WeaponKind, _ at: CGPoint, _ radius: CGFloat, _ color: Color) {
    switch kind {
    case .basic:
        fillCircle(&context, at, radius, color)
    case .shotgun:
        var shape = Path()
        shape.move(to: CGPoint(x: at.x, y: at.y - radius))
        shape.addLine(to: CGPoint(x: at.x + radius * 0.95, y: at.y + radius * 0.8))
        shape.addLine(to: CGPoint(x: at.x - radius * 0.95, y: at.y + radius * 0.8))
        shape.closeSubpath()
        context.fill(shape, with: .color(color))
    case .laser:
        let rect = CGRect(x: at.x - radius * 0.86, y: at.y - radius * 0.86, width: radius * 1.72, height: radius * 1.72)
        context.fill(Path(rect), with: .color(color))
    case .bomb:
        var shape = Path()
        for index in 0..<6 {
            let angle = (CGFloat.pi / 3) * CGFloat(index) - CGFloat.pi / 2
            let point = CGPoint(x: at.x + cos(angle) * radius, y: at.y + sin(angle) * radius)
            if index == 0 { shape.move(to: point) } else { shape.addLine(to: point) }
        }
        shape.closeSubpath()
        context.fill(shape, with: .color(color))
    case .emp:
        var shape = Path()
        for index in 0..<8 {
            let angle = (CGFloat.pi / 4) * CGFloat(index) - CGFloat.pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.38
            let point = CGPoint(x: at.x + cos(angle) * length, y: at.y + sin(angle) * length)
            if index == 0 { shape.move(to: point) } else { shape.addLine(to: point) }
        }
        shape.closeSubpath()
        context.fill(shape, with: .color(Color(hex: 0x67E8F9)))
        context.stroke(shape, with: .color(color), lineWidth: 1.5)
    case .poison:
        var shape = Path()
        shape.move(to: CGPoint(x: at.x, y: at.y - radius))
        shape.addQuadCurve(
            to: CGPoint(x: at.x, y: at.y + radius * 0.72),
            control: CGPoint(x: at.x + radius * 1.15, y: at.y + radius * 0.15)
        )
        shape.addQuadCurve(
            to: CGPoint(x: at.x, y: at.y - radius),
            control: CGPoint(x: at.x - radius * 1.15, y: at.y + radius * 0.15)
        )
        shape.closeSubpath()
        context.fill(shape, with: .color(color))
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
