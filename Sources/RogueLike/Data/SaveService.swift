import Foundation

public struct GameSaveData: Codable {
    public var currentLevelIndex: Int
    public var player: Player
    public var statistics: GameStatistics
    public var timestamp: Date
    
    public init(currentLevelIndex: Int, player: Player, statistics: GameStatistics) {
        self.currentLevelIndex = currentLevelIndex
        self.player = player
        self.statistics = statistics
        self.timestamp = Date()
    }
}

public struct HighScoreEntry: Codable, Comparable {
    public let playerName: String
    public let score: Int
    public let dungeonLevel: Int
    public let enemiesKilled: Int
    public let goldCollected: Int
    public let accuracy: Double
    public let stepsTaken: Int
    public let timestamp: Date
    
    public init(
        playerName: String,
        score: Int,
        dungeonLevel: Int,
        enemiesKilled: Int,
        goldCollected: Int,
        accuracy: Double,
        stepsTaken: Int
    ) {
        self.playerName = playerName
        self.score = score
        self.dungeonLevel = dungeonLevel
        self.enemiesKilled = enemiesKilled
        self.goldCollected = goldCollected
        self.accuracy = accuracy
        self.stepsTaken = stepsTaken
        self.timestamp = Date()
    }
    
    public static func < (lhs: HighScoreEntry, rhs: HighScoreEntry) -> Bool {
        lhs.score > rhs.score
    }
}

public final class SaveService {
    private let fileManager = FileManager.default
    private let saveDirectoryName = "RogueLike"
    private let saveFileName = "savegame.json"
    private let highScoresFileName = "highscores.json"
    private let maxHighScores = 10
    
    private var saveDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(saveDirectoryName)
    }
    
    private var saveFileURL: URL? {
        saveDirectory?.appendingPathComponent(saveFileName)
    }
    
    private var highScoresURL: URL? {
        saveDirectory?.appendingPathComponent(highScoresFileName)
    }
    
    public init() {
        createSaveDirectoryIfNeeded()
    }
    
    private func createSaveDirectoryIfNeeded() {
        guard let saveDir = saveDirectory else { return }
        if !fileManager.fileExists(atPath: saveDir.path) {
            try? fileManager.createDirectory(at: saveDir, withIntermediateDirectories: true)
        }
    }
    
    public func saveGame(engine: GameEngine) throws {
        guard let url = saveFileURL else {
            throw SaveError.directoryNotFound
        }
        
        let saveData = GameSaveData(
            currentLevelIndex: engine.currentLevel,
            player: engine.player,
            statistics: engine.statistics
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(saveData)
        try data.write(to: url)
    }
    
    public func loadGame() throws -> GameSaveData {
        guard let url = saveFileURL else {
            throw SaveError.directoryNotFound
        }
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw SaveError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(GameSaveData.self, from: data)
    }
    
    public func restoreGame(from saveData: GameSaveData) -> GameEngine {
        let engine = GameEngine()
        return engine
    }
    
    public func deleteSave() throws {
        guard let url = saveFileURL else {
            throw SaveError.directoryNotFound
        }
        
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    public func hasSavedGame() -> Bool {
        guard let url = saveFileURL else { return false }
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func saveHighScore(playerName: String, engine: GameEngine) throws {
        let score = calculateScore(engine: engine)
        let stats = engine.statistics
        
        let entry = HighScoreEntry(
            playerName: playerName,
            score: score,
            dungeonLevel: engine.currentLevel,
            enemiesKilled: stats.enemiesKilled,
            goldCollected: stats.goldCollected,
            accuracy: stats.accuracy,
            stepsTaken: stats.stepsTaken
        )
        
        var scores = loadHighScores()
        scores.append(entry)
        scores.sort()
        scores = Array(scores.prefix(maxHighScores))
        
        try saveHighScores(scores)
    }
    
    public func loadHighScores() -> [HighScoreEntry] {
        guard let url = highScoresURL,
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return (try? decoder.decode([HighScoreEntry].self, from: data)) ?? []
    }
    
    private func saveHighScores(_ scores: [HighScoreEntry]) throws {
        guard let url = highScoresURL else {
            throw SaveError.directoryNotFound
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(scores)
        try data.write(to: url)
    }
    
    public func clearHighScores() throws {
        guard let url = highScoresURL else {
            throw SaveError.directoryNotFound
        }
        
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    private func calculateScore(engine: GameEngine) -> Int {
        let stats = engine.statistics
        var score = 0
        score += stats.goldCollected
        score += stats.enemiesKilled * 50
        score += engine.currentLevel * 100
        score += engine.player.stats.level * 100
        score += stats.foodEaten * 10
        score += stats.elixirsDrunk * 15
        score += stats.scrollsRead * 20
        return score
    }
}

public enum SaveError: Error, LocalizedError {
    case directoryNotFound
    case fileNotFound
    case encodingFailed
    case decodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Save directory not found"
        case .fileNotFound:
            return "Save file not found"
        case .encodingFailed:
            return "Failed to encode game data"
        case .decodingFailed:
            return "Failed to decode save data"
        }
    }
}
