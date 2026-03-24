import Foundation

// MARK: - Direction
public enum Direction: CaseIterable {
    case north
    case south
    case east
    case west
    
    public var delta: Position {
        switch self {
        case .north: return Position(x: 0, y: -1)
        case .south: return Position(x: 0, y: 1)
        case .east: return Position(x: 1, y: 0)
        case .west: return Position(x: -1, y: 0)
        }
    }
    
    public var char: String {
        switch self {
        case .north: return "w"
        case .south: return "s"
        case .east: return "d"
        case .west: return "a"
        }
    }
    
    public static func fromChar(_ char: String) -> Direction? {
        switch char.lowercased() {
        case "w": return .north
        case "s": return .south
        case "d": return .east
        case "a": return .west
        default: return nil
        }
    }
}
