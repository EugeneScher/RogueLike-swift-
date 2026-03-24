import Foundation

public struct Player: Codable {
    public var position: Position
    public var stats: Stats
    public var backpack: Backpack
    public var weapon: Item?
    public var armor: Item?
    
    public init(
        position: Position = .zero,
        stats: Stats = Stats(),
        backpack: Backpack = Backpack(),
        weapon: Item? = nil,
        armor: Item? = nil
    ) {
        self.position = position
        self.stats = stats
        self.backpack = backpack
        self.weapon = weapon
        self.armor = armor
    }
    
    public var effectiveStrength: Int {
        stats.strength + (weapon?.strength ?? 0)
    }
    
    public var effectiveDefense: Int {
        armor?.defense ?? 0
    }
    
    public var effectiveAgility: Int {
        stats.agility
    }
    
    public mutating func heal(by amount: Int) {
        stats.heal(by: amount)
    }
    
    public mutating func takeDamage(_ damage: Int) {
        let actualDamage = max(1, damage - effectiveDefense)
        stats.takeDamage(actualDamage)
    }
    
    public mutating func gainExperience(_ amount: Int) {
        stats.addExperience(amount)
    }
    
    public mutating func equipWeapon(_ item: Item) {
        weapon = item
    }
    
    public mutating func equipArmor(_ item: Item) {
        armor = item
    }
    
    public mutating func unequipWeapon() {
        weapon = nil
    }
    
    public mutating func unequipArmor() {
        armor = nil
    }
}
