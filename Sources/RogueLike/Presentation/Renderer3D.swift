import Foundation

public struct Camera {
    public var x: Double
    public var y: Double
    public var angle: Double
    
    public init(x: Double, y: Double, angle: Double = 0.0) {
        self.x = x
        self.y = y
        self.angle = angle
    }
    
    public mutating func turnLeft() {
        angle -= .pi / 16
        if angle < 0 { angle += 2 * .pi }
    }
    
    public mutating func turnRight() {
        angle += .pi / 16
        if angle >= 2 * .pi { angle -= 2 * .pi }
    }
    
    public mutating func moveForward(_ distance: Double) {
        x += cos(angle) * distance
        y += sin(angle) * distance
    }
    
    public mutating func moveBackward(_ distance: Double) {
        x -= cos(angle) * distance
        y -= sin(angle) * distance
    }
}

public struct RayCastResult {
    public let distance: Double
    public let hitWall: Bool
    public let isVertical: Bool
    public let tileType: TileType?
}

public final class Renderer3D {
    private let screenWidth: Int
    private let screenHeight: Int
    private let fov: Double
    private let renderDistance: Double
    
    public init(screenWidth: Int = 80, screenHeight: Int = 24, fov: Double = .pi / 3) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.fov = fov
        self.renderDistance = 20.0
    }
    
    public func render3DView(camera: Camera, level: Level, curses: CursesUI) {
        for x in 0..<screenWidth {
            let rayAngle = camera.angle - fov / 2 + (Double(x) / Double(screenWidth)) * fov
            let result = castRay(camera: camera, angle: rayAngle, level: level)
            
            let correctedDistance = result.distance * cos(rayAngle - camera.angle)
            let wallHeight = Int(Double(screenHeight) / correctedDistance)
            
            let drawStart = max(0, (screenHeight - wallHeight) / 2)
            let drawEnd = min(screenHeight - 1, (screenHeight + wallHeight) / 2)
            
            for y in 0..<screenHeight {
                curses.moveCursor(row: y, col: x)
                
                if y < drawStart {
                    curses.setColor(ColorPair.corridor)
                    curses.addChar(".")
                } else if y >= drawStart && y < drawEnd {
                    if result.isVertical {
                        curses.setColor(ColorPair.wall)
                    } else {
                        curses.setColor(ColorPair.floor)
                    }
                    curses.addChar("#")
                } else {
                    curses.setColor(ColorPair.fog)
                    curses.addChar(" ")
                }
            }
        }
    }
    
    public func castRay(camera: Camera, angle: Double, level: Level) -> RayCastResult {
        let rayDirX = cos(angle)
        let rayDirY = sin(angle)
        
        var mapX = Int(camera.x)
        var mapY = Int(camera.y)
        
        let deltaDistX = abs(1 / rayDirX)
        let deltaDistY = abs(1 / rayDirY)
        
        var stepX: Int
        var stepY: Int
        var sideDistX: Double
        var sideDistY: Double
        
        if rayDirX < 0 {
            stepX = -1
            sideDistX = (camera.x - Double(mapX)) * deltaDistX
        } else {
            stepX = 1
            sideDistX = (Double(mapX) + 1.0 - camera.x) * deltaDistX
        }
        
        if rayDirY < 0 {
            stepY = -1
            sideDistY = (camera.y - Double(mapY)) * deltaDistY
        } else {
            stepY = 1
            sideDistY = (Double(mapY) + 1.0 - camera.y) * deltaDistY
        }
        
        var isVertical = false
        var hit = false
        var distance: Double = 0
        
        for _ in 0..<Int(renderDistance) {
            if sideDistX < sideDistY {
                sideDistX += deltaDistX
                mapX += stepX
                isVertical = true
            } else {
                sideDistY += deltaDistY
                mapY += stepY
                isVertical = false
            }
            
            if mapX < 0 || mapX >= level.width || mapY < 0 || mapY >= level.height {
                break
            }
            
            let tile = level.tileAt(Position(x: mapX, y: mapY))
            if tile?.type == .wall || tile?.type == .door {
                hit = true
                if isVertical {
                    distance = sideDistX - deltaDistX
                } else {
                    distance = sideDistY - deltaDistY
                }
                break
            }
        }
        
        return RayCastResult(
            distance: max(0.1, distance),
            hitWall: hit,
            isVertical: isVertical,
            tileType: level.tileAt(Position(x: mapX, y: mapY))?.type
        )
    }
    
    public func renderMinimap(camera: Camera, level: Level, player: Player, curses: CursesUI, cursesWidth: Int) {
        let mapWidth = 21
        let mapHeight = 15
        let mapX = cursesWidth - mapWidth - 2
        let mapY = 0
        
        for dy in 0..<mapHeight {
            for dx in 0..<mapWidth {
                let worldX = Int(camera.x) + dx - mapWidth / 2
                let worldY = Int(camera.y) + dy - mapHeight / 2
                
                curses.moveCursor(row: mapY + dy, col: mapX + dx)
                
                if worldX == Int(camera.x) && worldY == Int(camera.y) {
                    curses.setColor(ColorPair.player)
                    curses.addChar("@")
                } else if worldX == player.position.x && worldY == player.position.y {
                    curses.setColor(ColorPair.player)
                    curses.addChar("@")
                } else if let enemy = level.enemyAt(Position(x: worldX, y: worldY)), level.tileAt(Position(x: worldX, y: worldY))?.isVisible ?? false {
                    curses.setColor(ColorPair.enemy)
                    curses.addChar(Character(enemy.displayChar))
                } else if let item = level.itemAt(Position(x: worldX, y: worldY)), level.tileAt(Position(x: worldX, y: worldY))?.isVisible ?? false {
                    curses.setColor(ColorPair.item)
                    curses.addChar(Character(item.displayChar))
                } else if let tile = level.tileAt(Position(x: worldX, y: worldY)) {
                    if tile.isVisible {
                        curses.setColor(tile.type == .wall ? ColorPair.wall : ColorPair.floor)
                        curses.addChar(Character(tile.displayChar))
                    } else if tile.isExplored {
                        curses.setColor(ColorPair.fog)
                        let ch = tile.displayChar.lowercased()
                        if let firstChar = ch.first {
                            curses.addChar(firstChar)
                        }
                    } else {
                        curses.addChar(" ")
                    }
                } else {
                    curses.addChar(" ")
                }
            }
        }
        
        let dirX = Int(cos(camera.angle) * 3)
        let dirY = Int(sin(camera.angle) * 3)
        let targetX = mapX + mapWidth / 2 + dirX
        let targetY = mapY + mapHeight / 2 + dirY
        
        if targetX >= mapX && targetX < mapX + mapWidth && targetY >= mapY && targetY < mapY + mapHeight {
            curses.moveCursor(row: targetY, col: targetX)
            curses.setColor(ColorPair.player)
            curses.addChar("*")
        }
    }
    
    public func renderCompass(camera: Camera, curses: CursesUI, cursesWidth: Int) {
        let compassY = 0
        let compassX = 2
        
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let angleDegrees = (camera.angle * 180 / .pi).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = angleDegrees < 0 ? angleDegrees + 360 : angleDegrees
        let directionIndex = Int((normalizedAngle + 22.5) / 45) % 8
        let facing = directions[directionIndex]
        
        curses.moveCursor(row: compassY, col: compassX)
        curses.addString("[\(facing)]")
    }
}

public final class GameMode3D {
    private let engine: GameEngine
    private let renderer: Renderer3D
    private var camera: Camera
    private var is3DMode: Bool
    
    public init(engine: GameEngine) {
        self.engine = engine
        self.renderer = Renderer3D()
        self.camera = Camera(x: Double(engine.player.position.x), y: Double(engine.player.position.y), angle: 0)
        self.is3DMode = false
    }
    
    public func toggleMode() {
        is3DMode.toggle()
        if is3DMode {
            camera = Camera(x: Double(engine.player.position.x), y: Double(engine.player.position.y), angle: 0)
        }
    }
    
    public var isActive: Bool {
        is3DMode
    }
    
    public func processInput(_ key: String) -> Bool {
        guard is3DMode else { return false }
        
        switch key {
        case "w":
            let newX = camera.x + cos(camera.angle) * 0.5
            let newY = camera.y + sin(camera.angle) * 0.5
            let newPos = Position(x: Int(newX), y: Int(newY))
            if engine.level.isWalkable(newPos) && engine.level.enemyAt(newPos) == nil {
                camera.x = newX
                camera.y = newY
                engine.movePlayerTo(position: newPos)
            }
            return true
        case "s":
            let newX = camera.x - cos(camera.angle) * 0.5
            let newY = camera.y - sin(camera.angle) * 0.5
            let newPos = Position(x: Int(newX), y: Int(newY))
            if engine.level.isWalkable(newPos) && engine.level.enemyAt(newPos) == nil {
                camera.x = newX
                camera.y = newY
                engine.movePlayerTo(position: newPos)
            }
            return true
        case "a":
            camera.turnLeft()
            return true
        case "d":
            camera.turnRight()
            return true
        default:
            return false
        }
    }
    
    public func render(curses: CursesUI, cursesWidth: Int, cursesHeight: Int) {
        engine.updateVisibility()
        
        renderer.render3DView(camera: camera, level: engine.level, curses: curses)
        renderer.renderMinimap(camera: camera, level: engine.level, player: engine.player, curses: curses, cursesWidth: cursesWidth)
        renderer.renderCompass(camera: camera, curses: curses, cursesWidth: cursesWidth)
        
        let statusY = cursesHeight - 4
        curses.moveCursor(row: statusY, col: 0)
        curses.addString("HP: \(engine.player.stats.health)/\(engine.player.stats.maxHealth)  STR: \(engine.player.effectiveStrength)  Floor: \(engine.currentLevel)/21")
        curses.moveCursor(row: statusY + 1, col: 0)
        curses.addString("Gold: \(engine.player.stats.gold)  Weapon: \(engine.player.weapon?.name ?? "Fists")  Armor: \(engine.player.armor?.name ?? "Clothes")")
    }
}
