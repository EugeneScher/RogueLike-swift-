import Foundation

public enum DifficultyLevel: Int, Codable {
    case veryEasy = -2
    case easy = -1
    case normal = 0
    case hard = 1
    case veryHard = 2
    
    public var name: String {
        switch self {
        case .veryEasy: return "Very Easy"
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }
    
    public var enemyMultiplier: Double {
        switch self {
        case .veryEasy: return 0.5
        case .easy: return 0.75
        case .normal: return 1.0
        case .hard: return 1.25
        case .veryHard: return 1.5
        }
    }
    
    public var itemMultiplier: Double {
        switch self {
        case .veryEasy: return 1.5
        case .easy: return 1.25
        case .normal: return 1.0
        case .hard: return 0.75
        case .veryHard: return 0.5
        }
    }
}

public final class DifficultyManager {
    public private(set) var currentDifficulty: DifficultyLevel
    public private(set) var difficultyScore: Int
    
    private var healthHistory: [Int]
    private var combatHistory: [(dealt: Int, taken: Int)]
    private var deathsCount: Int
    private var levelCompletions: Int
    private var recentDamageTaken: Int
    private var recentDamageDealt: Int
    
    private let maxHistorySize = 20
    
    public init() {
        self.currentDifficulty = .normal
        self.difficultyScore = 0
        self.healthHistory = []
        self.combatHistory = []
        self.deathsCount = 0
        self.levelCompletions = 0
        self.recentDamageTaken = 0
        self.recentDamageDealt = 0
    }
    
    public func recordHealthChange(old: Int, new: Int) {
        if new < old {
            let damage = old - new
            recentDamageTaken += damage
        }
    }
    
    public func recordCombatResult(dealt: Int, taken: Int) {
        combatHistory.append((dealt: dealt, taken: taken))
        recentDamageDealt += dealt
        recentDamageTaken += taken
        
        if combatHistory.count > maxHistorySize {
            combatHistory.removeFirst()
        }
    }
    
    public func recordDeath() {
        deathsCount += 1
        difficultyScore -= 15
    }
    
    public func recordLevelCompletion() {
        levelCompletions += 1
        difficultyScore += 5
    }
    
    public func evaluateDifficulty() -> DifficultyLevel {
        var adjustment = 0
        
        if deathsCount >= 3 {
            adjustment -= 1
        }
        
        if combatHistory.count >= 5 {
            var totalDealt = 0
            var totalTaken = 0
            for combat in combatHistory.suffix(5) {
                totalDealt += combat.dealt
                totalTaken += combat.taken
            }
            
            if totalTaken > totalDealt * 2 {
                adjustment -= 1
            } else if totalDealt > totalTaken * 2 {
                adjustment += 1
            }
        }
        
        if recentDamageTaken > recentDamageDealt * 3 && recentDamageTaken > 30 {
            adjustment -= 1
        }
        
        let newScore = difficultyScore + adjustment
        difficultyScore = max(-20, min(20, newScore))
        
        let newDifficulty: DifficultyLevel
        switch difficultyScore {
        case ..<(-15): newDifficulty = .veryEasy
        case -15..<(-5): newDifficulty = .easy
        case -5...5: newDifficulty = .normal
        case 6..<15: newDifficulty = .hard
        default: newDifficulty = .veryHard
        }
        
        if newDifficulty != currentDifficulty {
            currentDifficulty = newDifficulty
        }
        
        recentDamageTaken = 0
        recentDamageDealt = 0
        
        return currentDifficulty
    }
    
    public func calculateEnemyCount(base: Int, level: Int) -> Int {
        let difficulty = evaluateDifficulty()
        let scaledLevel = max(1, level)
        let baseEnemies = base + scaledLevel / 3
        
        let adjusted = Int(Double(baseEnemies) * difficulty.enemyMultiplier)
        return max(1, min(adjusted, baseEnemies + 3))
    }
    
    public func shouldSpawnExtraHealthItem() -> Bool {
        if recentDamageTaken > 20 {
            return Double.random(in: 0...1) < 0.3
        }
        return Double.random(in: 0...1) < 0.1
    }
    
    public func shouldSpawnExtraFood() -> Bool {
        if let lastHealth = healthHistory.last, lastHealth < 6 {
            return Double.random(in: 0...1) < 0.25
        }
        return Double.random(in: 0...1) < 0.08
    }
    
    public func adjustItemChance(forType type: ItemType) -> Double {
        let difficulty = evaluateDifficulty()
        
        switch type {
        case .food, .elixir:
            if recentDamageTaken > 15 {
                return 0.15 * difficulty.itemMultiplier
            }
            return 0.08 * difficulty.itemMultiplier
            
        case .scroll:
            if recentDamageDealt > recentDamageTaken * 2 {
                return 0.15 * difficulty.itemMultiplier
            }
            return 0.1 * difficulty.itemMultiplier
            
        case .weapon, .armor:
            return 0.08 * difficulty.itemMultiplier
            
        case .treasure:
            return 0.12 * difficulty.itemMultiplier
            
        case .key:
            return 0.02
        }
    }
    
    public func getEnemyTypeBias() -> [EnemyType] {
        let difficulty = evaluateDifficulty()
        
        switch difficulty {
        case .veryEasy, .easy:
            return [.zombie, .ghost, .mimic]
        case .normal:
            return [.zombie, .vampire, .ghost, .snakeMage, .mimic]
        case .hard, .veryHard:
            return [.vampire, .ogre, .snakeMage]
        }
    }
    
    public func reset() {
        currentDifficulty = .normal
        difficultyScore = 0
        healthHistory.removeAll()
        combatHistory.removeAll()
        deathsCount = 0
        levelCompletions = 0
        recentDamageTaken = 0
        recentDamageDealt = 0
    }
}
