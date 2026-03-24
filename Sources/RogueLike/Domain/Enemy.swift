import Foundation

public enum EnemyType: String, Codable, CaseIterable {
    case zombie
    case vampire
    case ghost
    case ogre
    case snakeMage
    case mimic
}

public enum EnemyBehavior: Codable {
    case patrol
    case chase
    case teleport
    case restAfterAttack
    case diagonal
}

public struct Enemy: Codable, Hashable {
    public let id: UUID
    public var position: Position
    public let type: EnemyType
    public var health: Int
    public let maxHealth: Int
    public var strength: Int
    public var experience: Int
    public var agility: Int
    public var hostility: Int
    public let level: Int
    public var isHostile: Bool
    public var isResting: Bool
    public var isInvisible: Bool
    public var patrolDirection: Int
    public var teleportTimer: Int
    public var sleepTurns: Int
    public var moveCount: Int
    
    // Vampire properties
    public var firstHitMiss: Bool
    public var maxHpDrain: Int
    
    // Ogre properties
    public var hasAttackedThisTurn: Bool
    
    // Snake-Mage properties
    public var sleepChanceOnHit: Double
    
    public init(
        id: UUID = UUID(),
        position: Position,
        type: EnemyType,
        health: Int,
        strength: Int,
        experience: Int,
        agility: Int,
        hostility: Int,
        level: Int = 1
    ) {
        self.id = id
        self.position = position
        self.type = type
        self.health = health
        self.maxHealth = health
        self.strength = strength
        self.experience = experience
        self.agility = agility
        self.hostility = hostility
        self.level = level
        self.isHostile = false
        self.isResting = false
        self.isInvisible = false
        self.patrolDirection = 0
        self.teleportTimer = 0
        self.sleepTurns = 0
        self.moveCount = 0
        self.firstHitMiss = false
        self.maxHpDrain = 0
        self.hasAttackedThisTurn = false
        self.sleepChanceOnHit = 0.0
    }
    
    public var displayChar: String {
        switch type {
        case .zombie: return "z"
        case .vampire: return "v"
        case .ghost: return "g"
        case .ogre: return "O"
        case .snakeMage: return "s"
        case .mimic: return "m"
        }
    }
    
    public var behavior: EnemyBehavior {
        switch type {
        case .zombie: return .patrol
        case .vampire: return .patrol
        case .ghost: return .teleport
        case .ogre: return .restAfterAttack
        case .snakeMage: return .diagonal
        case .mimic: return .patrol
        }
    }
    
    public var treasureDropBase: Int {
        switch type {
        case .zombie: return 5
        case .vampire: return 15
        case .ghost: return 3
        case .ogre: return 25
        case .snakeMage: return 20
        case .mimic: return 30
        }
    }
    
    public var description: String {
        switch type {
        case .zombie: return "Zombie"
        case .vampire: return "Vampire"
        case .ghost: return "Ghost"
        case .ogre: return "Ogre"
        case .snakeMage: return "Snake Mage"
        case .mimic: return "Mimic"
        }
    }
    
    public mutating func takeDamage(_ amount: Int) {
        health = max(0, health - amount)
        if health <= 0 {
            isHostile = false
        }
    }
    
    public mutating func heal(_ amount: Int) {
        health = min(maxHealth, health + amount)
    }
    
    public mutating func rest() {
        isResting = true
    }
    
    public mutating func wakeUp() {
        isResting = false
    }
    
    public static func createZombie(at pos: Position, level: Int) -> Enemy {
        Enemy(
            position: pos,
            type: .zombie,
            health: 15 + level * 3,
            strength: 5 + level,
            experience: 10 + level * 2,
            agility: 3 + level / 2,
            hostility: 5 + level,
            level: level
        )
    }
    
    public static func createVampire(at pos: Position, level: Int) -> Enemy {
        var enemy = Enemy(
            position: pos,
            type: .vampire,
            health: 12 + level * 2,
            strength: 6 + level,
            experience: 20 + level * 3,
            agility: 10 + level,
            hostility: 8 + level,
            level: level
        )
        enemy.firstHitMiss = true
        enemy.maxHpDrain = 2 + level / 2
        return enemy
    }
    
    public static func createGhost(at pos: Position, level: Int) -> Enemy {
        var enemy = Enemy(
            position: pos,
            type: .ghost,
            health: 6 + level,
            strength: 3 + level / 2,
            experience: 15 + level * 2,
            agility: 12 + level,
            hostility: 3 + level / 2,
            level: level
        )
        enemy.isInvisible = true
        enemy.teleportTimer = 3 + level / 2
        return enemy
    }
    
    public static func createOgre(at pos: Position, level: Int) -> Enemy {
        var enemy = Enemy(
            position: pos,
            type: .ogre,
            health: 25 + level * 5,
            strength: 12 + level * 2,
            experience: 30 + level * 5,
            agility: 2 + level / 3,
            hostility: 5 + level,
            level: level
        )
        enemy.hasAttackedThisTurn = false
        return enemy
    }
    
    public static func createSnakeMage(at pos: Position, level: Int) -> Enemy {
        var enemy = Enemy(
            position: pos,
            type: .snakeMage,
            health: 8 + level * 2,
            strength: 4 + level,
            experience: 25 + level * 4,
            agility: 14 + level,
            hostility: 10 + level * 2,
            level: level
        )
        enemy.sleepChanceOnHit = 0.15 + Double(level) * 0.02
        return enemy
    }
    
    public static func createMimic(at pos: Position, level: Int) -> Enemy {
        Enemy(
            position: pos,
            type: .mimic,
            health: 15 + level * 3,
            strength: 3 + level,
            experience: 35 + level * 5,
            agility: 12 + level,
            hostility: 3 + level / 2,
            level: level
        )
    }
    
    public static func createRandom(at pos: Position, level: Int) -> Enemy {
        let roll = Int.random(in: 1...100)
        let scaledLevel = max(1, level)
        
        if roll <= 20 {
            return createZombie(at: pos, level: scaledLevel)
        } else if roll <= 35 {
            return createVampire(at: pos, level: scaledLevel)
        } else if roll <= 50 {
            return createGhost(at: pos, level: scaledLevel)
        } else if roll <= 70 {
            return createOgre(at: pos, level: scaledLevel)
        } else if roll <= 90 {
            return createSnakeMage(at: pos, level: scaledLevel)
        } else {
            return createMimic(at: pos, level: scaledLevel)
        }
    }
}
