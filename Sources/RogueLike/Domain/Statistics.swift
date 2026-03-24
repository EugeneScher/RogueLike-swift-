import Foundation

public struct GameStatistics: Codable {
    public var goldCollected: Int
    public var enemiesKilled: Int
    public var foodEaten: Int
    public var elixirsDrunk: Int
    public var scrollsRead: Int
    public var hitsDealt: Int
    public var hitsMissed: Int
    public var stepsTaken: Int
    public var damageDealt: Int
    public var damageTaken: Int
    
    public init() {
        self.goldCollected = 0
        self.enemiesKilled = 0
        self.foodEaten = 0
        self.elixirsDrunk = 0
        self.scrollsRead = 0
        self.hitsDealt = 0
        self.hitsMissed = 0
        self.stepsTaken = 0
        self.damageDealt = 0
        self.damageTaken = 0
    }
    
    public var totalAttacks: Int {
        hitsDealt + hitsMissed
    }
    
    public var accuracy: Double {
        guard totalAttacks > 0 else { return 0 }
        return Double(hitsDealt) / Double(totalAttacks) * 100
    }
    
    public mutating func recordKill() {
        enemiesKilled += 1
    }
    
    public mutating func recordFoodEaten() {
        foodEaten += 1
    }
    
    public mutating func recordElixirDrunk() {
        elixirsDrunk += 1
    }
    
    public mutating func recordScrollRead() {
        scrollsRead += 1
    }
    
    public mutating func recordHit(dealt: Int) {
        hitsDealt += 1
        damageDealt += dealt
    }
    
    public mutating func recordMiss() {
        hitsMissed += 1
    }
    
    public mutating func recordStep() {
        stepsTaken += 1
    }
    
    public mutating func recordDamage(dealt: Int, received: Int) {
        damageDealt += dealt
        damageTaken += received
    }
    
    public mutating func addGold(_ amount: Int) {
        goldCollected += amount
    }
}

public struct GameSession: Codable {
    public var currentLevelIndex: Int
    public var player: Player
    public var level: Level
    public var statistics: GameStatistics
    public var isGameOver: Bool
    public var isVictory: Bool
    
    public init(
        currentLevelIndex: Int,
        player: Player,
        level: Level,
        statistics: GameStatistics
    ) {
        self.currentLevelIndex = currentLevelIndex
        self.player = player
        self.level = level
        self.statistics = statistics
        self.isGameOver = false
        self.isVictory = false
    }
}
