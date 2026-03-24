import Foundation

public struct Stats: Codable, Hashable {
    public var health: Int
    public var maxHealth: Int
    public var strength: Int
    public var experience: Int
    public var agility: Int
    public var wisdom: Int
    public var level: Int
    public var gold: Int
    
    public init(
        health: Int = 12,
        maxHealth: Int = 12,
        strength: Int = 10,
        experience: Int = 0,
        agility: Int = 10,
        wisdom: Int = 10,
        level: Int = 1,
        gold: Int = 0
    ) {
        self.health = health
        self.maxHealth = maxHealth
        self.strength = strength
        self.experience = experience
        self.agility = agility
        self.wisdom = wisdom
        self.level = level
        self.gold = gold
    }
    
    public var isDead: Bool { health <= 0 }
    
    public var experienceToLevel: Int { level * 25 }
    
    public mutating func heal(by amount: Int) {
        health = min(health + amount, maxHealth)
    }
    
    public mutating func takeDamage(_ damage: Int) {
        health -= damage
    }
    
    public mutating func addExperience(_ amount: Int) {
        experience += amount
        while experience >= experienceToLevel {
            experience -= experienceToLevel
            levelUp()
        }
    }
    
    public mutating func levelUp() {
        level += 1
        maxHealth += 3 + Int.random(in: 0...2)
        health = maxHealth
        strength += 1
        agility += 1
        wisdom += 1
    }
}
