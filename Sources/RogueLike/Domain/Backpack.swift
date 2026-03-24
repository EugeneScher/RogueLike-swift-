import Foundation

public struct Backpack: Codable {
    public static let maxItemsTotal = 20
    
    public var items: [Item]
    public var gold: Int
    
    public init(items: [Item] = [], gold: Int = 0) {
        self.items = items
        self.gold = gold
    }
    
    public var isFull: Bool {
        items.count >= Self.maxItemsTotal
    }
    
    public func count(ofType type: ItemType) -> Int {
        items.filter { $0.type == type }.count
    }
    
    public func items(ofType type: ItemType) -> [Item] {
        items.filter { $0.type == type }
    }
    
    public func items(ofSubtype subtype: ItemSubtype) -> [Item] {
        items.filter { $0.subtype == subtype }
    }
    
    public func canAdd(_ item: Item) -> Bool {
        if item.type == .treasure { return true }
        return !isFull
    }
    
    @discardableResult
    public mutating func add(_ item: Item) -> Bool {
        guard canAdd(item) else { return false }
        
        if item.type == .treasure {
            gold += item.cost
            return true
        }
        
        items.append(item)
        return true
    }
    
    public mutating func addGold(_ amount: Int) {
        gold += amount
    }
    
    @discardableResult
    public mutating func remove(at index: Int) -> Item? {
        guard index >= 0 && index < items.count else { return nil }
        return items.remove(at: index)
    }
    
    @discardableResult
    public mutating func remove(_ item: Item) -> Item? {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            return items.remove(at: index)
        }
        return nil
    }
    
    public func contains(_ item: Item) -> Bool {
        items.contains { $0.id == item.id }
    }
    
    public mutating func clear() {
        items.removeAll()
    }
}
