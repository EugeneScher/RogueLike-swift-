import Foundation

public enum ItemType: String, Codable, CaseIterable {
    case treasure
    case food
    case elixir
    case scroll
    case weapon
    case armor
    case key
}

public enum ItemSubtype: String, Codable {
    case gold
    
    case food
    
    case elixirStrength
    case elixirAgility
    case elixirHealth
    
    case scrollStrength
    case scrollAgility
    case scrollHealth
    
    case dagger
    case shortSword
    case longSword
    case twoHandedSword
    
    case leatherArmor
    case chainMail
    case plateMail
    
    case keyRed
    case keyBlue
    case keyYellow
    case keyGreen
}

public enum KeyColor: String, Codable {
    case red
    case blue
    case yellow
    case green
    
    public var displayName: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .green: return "Green"
        }
    }
}

public struct Item: Codable, Hashable {
    public let id: UUID
    public var position: Position
    public let type: ItemType
    public let subtype: ItemSubtype
    public var healthValue: Int
    public var maxHealthValue: Int
    public var strength: Int
    public var agility: Int
    public var defense: Int
    public var cost: Int
    public var isCursed: Bool
    public var duration: Int
    
    public init(
        id: UUID = UUID(),
        position: Position,
        type: ItemType,
        subtype: ItemSubtype,
        healthValue: Int = 0,
        maxHealthValue: Int = 0,
        strength: Int = 0,
        agility: Int = 0,
        defense: Int = 0,
        cost: Int = 0,
        isCursed: Bool = false,
        duration: Int = 0
    ) {
        self.id = id
        self.position = position
        self.type = type
        self.subtype = subtype
        self.healthValue = healthValue
        self.maxHealthValue = maxHealthValue
        self.strength = strength
        self.agility = agility
        self.defense = defense
        self.cost = cost
        self.isCursed = isCursed
        self.duration = duration
    }
    
    public var displayChar: String {
        switch type {
        case .treasure: return "$"
        case .food: return "%"
        case .elixir: return "!"
        case .scroll: return "?"
        case .weapon: return "/"
        case .armor: return "]"
        case .key: return "*"
        }
    }
    
    public var name: String {
        switch subtype {
        case .gold: return "Gold"
        case .food: return "Food"
        case .elixirStrength: return "Strength Elixir"
        case .elixirAgility: return "Agility Elixir"
        case .elixirHealth: return "Health Elixir"
        case .scrollStrength: return "Strength Scroll"
        case .scrollAgility: return "Agility Scroll"
        case .scrollHealth: return "Health Scroll"
        case .dagger: return "Dagger"
        case .shortSword: return "Short Sword"
        case .longSword: return "Long Sword"
        case .twoHandedSword: return "Two-Handed Sword"
        case .leatherArmor: return "Leather Armor"
        case .chainMail: return "Chain Mail"
        case .plateMail: return "Plate Mail"
        case .keyRed: return "Red Key"
        case .keyBlue: return "Blue Key"
        case .keyYellow: return "Yellow Key"
        case .keyGreen: return "Green Key"
        }
    }
}
