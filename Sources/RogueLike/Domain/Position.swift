import Foundation

// MARK: - Position
public struct Position: Hashable, Codable, Equatable {
    public var x: Int
    public var y: Int
    
    public static let zero = Position(x: 0, y: 0)
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    public func manhattanDistance(to other: Position) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }
    
    public func adjacent() -> [Position] {
        [
            Position(x: x - 1, y: y),
            Position(x: x + 1, y: y),
            Position(x: x, y: y - 1),
            Position(x: x, y: y + 1)
        ]
    }
    
    public static func + (lhs: Position, rhs: Position) -> Position {
        Position(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func - (lhs: Position, rhs: Position) -> Position {
        Position(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
