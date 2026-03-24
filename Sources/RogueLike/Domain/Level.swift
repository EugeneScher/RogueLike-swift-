import Foundation

public enum TileType: Int, Codable {
    case wall = 0
    case floor = 1
    case corridor = 2
    case stairs = 3
    case door = 4
}

public struct Tile: Codable {
    public var type: TileType
    public var isExplored: Bool
    public var isVisible: Bool
    public var isLocked: Bool
    public var keyColor: KeyColor?
    
    public init(
        type: TileType,
        isExplored: Bool = false,
        isVisible: Bool = false,
        isLocked: Bool = false,
        keyColor: KeyColor? = nil
    ) {
        self.type = type
        self.isExplored = isExplored
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.keyColor = keyColor
    }
    
    public var isWalkable: Bool {
        if type == .wall { return false }
        if type == .door && isLocked { return false }
        return true
    }
    
    public var displayChar: String {
        switch type {
        case .wall: return "#"
        case .floor, .corridor: return "."
        case .stairs: return ">"
        case .door: return isLocked ? "+" : "'"
        }
    }
    
    public mutating func unlock() {
        if type == .door {
            isLocked = false
        }
    }
}

public struct Room: Codable {
    public let id: UUID
    public let origin: Position
    public let width: Int
    public let height: Int
    public var gridX: Int
    public var gridY: Int
    public var isStart: Bool
    public var isEnd: Bool
    
    public init(
        id: UUID = UUID(),
        origin: Position,
        width: Int,
        height: Int,
        gridX: Int,
        gridY: Int,
        isStart: Bool = false,
        isEnd: Bool = false
    ) {
        self.id = id
        self.origin = origin
        self.width = width
        self.height = height
        self.gridX = gridX
        self.gridY = gridY
        self.isStart = isStart
        self.isEnd = isEnd
    }
    
    public var center: Position {
        Position(x: origin.x + width / 2, y: origin.y + height / 2)
    }
    
    public func contains(_ pos: Position) -> Bool {
        pos.x >= origin.x && pos.x < origin.x + width &&
        pos.y >= origin.y && pos.y < origin.y + height
    }
    
    public func randomFloorPosition() -> Position {
        Position(
            x: Int.random(in: (origin.x + 1)..<(origin.x + width - 1)),
            y: Int.random(in: (origin.y + 1)..<(origin.y + height - 1))
        )
    }
}

public struct Corridor: Codable {
    public let id: UUID
    public let fromRoom: UUID
    public let toRoom: UUID
    public let path: [Position]
    
    public init(id: UUID = UUID(), fromRoom: UUID, toRoom: UUID, path: [Position]) {
        self.id = id
        self.fromRoom = fromRoom
        self.toRoom = toRoom
        self.path = path
    }
}

public struct Door: Codable {
    public let id: UUID
    public let position: Position
    public var isLocked: Bool
    public let keyColor: KeyColor?
    
    public init(
        id: UUID = UUID(),
        position: Position,
        isLocked: Bool = false,
        keyColor: KeyColor? = nil
    ) {
        self.id = id
        self.position = position
        self.isLocked = isLocked
        self.keyColor = keyColor
    }
}

public struct Level: Codable {
    public let id: UUID
    public let index: Int
    public var rooms: [Room]
    public var corridors: [Corridor]
    public var tiles: [[Tile]]
    public var enemies: [Enemy]
    public var items: [Item]
    public var doors: [Door]
    public var startRoomId: UUID?
    public var endRoomId: UUID?
    public let width: Int
    public let height: Int
    
    public init(
        id: UUID = UUID(),
        index: Int,
        width: Int = 67,
        height: Int = 18
    ) {
        self.id = id
        self.index = index
        self.width = width
        self.height = height
        self.rooms = []
        self.corridors = []
        self.tiles = Array(repeating: Array(repeating: Tile(type: .wall), count: width), count: height)
        self.enemies = []
        self.items = []
        self.doors = []
    }
    
    public mutating func generateTiles() {
        tiles = Array(repeating: Array(repeating: Tile(type: .wall), count: width), count: height)
        
        for room in rooms {
            for x in room.origin.x..<(room.origin.x + room.width) {
                for y in room.origin.y..<(room.origin.y + room.height) {
                    if x >= 0 && x < width && y >= 0 && y < height {
                        let isWall = x == room.origin.x || x == room.origin.x + room.width - 1 ||
                                     y == room.origin.y || y == room.origin.y + room.height - 1
                        tiles[y][x] = Tile(type: isWall ? .wall : (room.isEnd ? .stairs : .floor))
                    }
                }
            }
        }
        
        for corridor in corridors {
            for pos in corridor.path {
                if pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height {
                    if tiles[pos.y][pos.x].type == .wall {
                        tiles[pos.y][pos.x] = Tile(type: .corridor)
                    }
                }
            }
        }
        
        for door in doors {
            if door.position.x >= 0 && door.position.x < width &&
               door.position.y >= 0 && door.position.y < height {
                tiles[door.position.y][door.position.x] = Tile(
                    type: .door,
                    isLocked: door.isLocked,
                    keyColor: door.keyColor
                )
            }
        }
    }
    
    public mutating func unlockDoor(at pos: Position, withColor color: KeyColor) {
        for i in doors.indices {
            if doors[i].position == pos && doors[i].keyColor == color {
                doors[i].isLocked = false
                if pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height {
                    tiles[pos.y][pos.x].unlock()
                }
                break
            }
        }
    }
    
    public mutating func updateVisibility(playerPosition: Position, viewRadius: Int = 8) {
        for y in 0..<height {
            for x in 0..<width {
                tiles[y][x].isVisible = false
            }
        }
        
        tiles[playerPosition.y][playerPosition.x].isVisible = true
        tiles[playerPosition.y][playerPosition.x].isExplored = true
        
        for angle in stride(from: 0.0, to: 360.0, by: 1.0) {
            let rad = angle * .pi / 180.0
            let dx = cos(rad)
            let dy = sin(rad)
            
            var x = Double(playerPosition.x) + 0.5
            var y = Double(playerPosition.y) + 0.5
            
            for _ in 0..<viewRadius {
                x += dx
                y += dy
                
                let px = Int(floor(x))
                let py = Int(floor(y))
                
                if px < 0 || px >= width || py < 0 || py >= height { break }
                
                tiles[py][px].isVisible = true
                tiles[py][px].isExplored = true
                
                if tiles[py][px].type == .wall || tiles[py][px].type == .door {
                    break
                }
            }
        }
        
        for dy in -viewRadius...viewRadius {
            for dx in -viewRadius...viewRadius {
                let targetX = playerPosition.x + dx
                let targetY = playerPosition.y + dy
                let distance = sqrt(Double(dx * dx + dy * dy))
                
                if distance > Double(viewRadius) { continue }
                if targetX < 0 || targetX >= width || targetY < 0 || targetY >= height { continue }
                
                let line = bresenhamLine(from: playerPosition, to: Position(x: targetX, y: targetY))
                for pos in line {
                    if pos.x < 0 || pos.x >= width || pos.y < 0 || pos.y >= height { break }
                    
                    tiles[pos.y][pos.x].isVisible = true
                    tiles[pos.y][pos.x].isExplored = true
                    
                    if tiles[pos.y][pos.x].type == .wall {
                        break
                    }
                }
            }
        }
    }
    
    public func bresenhamLine(from start: Position, to end: Position) -> [Position] {
        var points: [Position] = []
        
        var x0 = start.x
        var y0 = start.y
        let x1 = end.x
        let y1 = end.y
        
        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        
        while true {
            points.append(Position(x: x0, y: y0))
            
            if x0 == x1 && y0 == y1 { break }
            
            let e2 = 2 * err
            
            if e2 > -dy {
                err -= dy
                x0 += sx
            }
            
            if e2 < dx {
                err += dx
                y0 += sy
            }
        }
        
        return points
    }
    
    public func tileAt(_ pos: Position) -> Tile? {
        guard pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height else { return nil }
        return tiles[pos.y][pos.x]
    }
    
    public func isWalkable(_ pos: Position) -> Bool {
        tileAt(pos)?.isWalkable ?? false
    }
    
    public func roomAt(_ pos: Position) -> Room? {
        rooms.first { $0.contains(pos) }
    }
    
    public func roomById(_ id: UUID) -> Room? {
        rooms.first { $0.id == id }
    }
    
    public func enemyAt(_ pos: Position) -> Enemy? {
        enemies.first { $0.position == pos }
    }
    
    public func itemAt(_ pos: Position) -> Item? {
        items.first { $0.position == pos }
    }
    
    public mutating func removeEnemy(_ enemy: Enemy) {
        enemies.removeAll { $0.id == enemy.id }
    }
    
    public mutating func removeItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
    }
}
