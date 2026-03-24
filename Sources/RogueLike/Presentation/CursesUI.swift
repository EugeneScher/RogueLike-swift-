import Foundation
import CCurses

public enum CursesColor: Int16 {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
    case defaultColor = -1
}

public struct ColorPair {
    public static let player: Int16 = 1
    public static let enemy: Int16 = 2
    public static let item: Int16 = 3
    public static let wall: Int16 = 4
    public static let floor: Int16 = 5
    public static let corridor: Int16 = 6
    public static let exit: Int16 = 7
    public static let fog: Int16 = 8
}

public final class CursesUI {
    private var initialized = false
    
    public init() {}
    
    public func initialize() -> Bool {
        guard !initialized else { return true }
        
        cc_init()
        initialized = true
        
        if cc_has_colors() {
            cc_start_color()
            cc_use_default_colors()
            
            cc_init_pair(ColorPair.player, CursesColor.yellow.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.enemy, CursesColor.red.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.item, CursesColor.cyan.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.wall, CursesColor.white.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.floor, CursesColor.black.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.corridor, CursesColor.blue.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.exit, CursesColor.green.rawValue, CursesColor.black.rawValue)
            cc_init_pair(ColorPair.fog, CursesColor.black.rawValue, CursesColor.black.rawValue)
        }
        
        return true
    }
    
    public func shutdown() {
        guard initialized else { return }
        cc_shutdown()
        initialized = false
    }
    
    public func clearScreen() {
        cc_clear()
    }
    
    public func refresh() {
        cc_refresh()
    }
    
    public func setNonBlocking(_ nonBlocking: Bool) {
        cc_set_blocking(!nonBlocking)
    }
    
    public func moveCursor(row: Int, col: Int) {
        cc_move(Int32(row), Int32(col))
    }
    
    public func addChar(_ char: Character) {
        if let scalar = char.asciiValue {
            cc_addch(CChar(scalar))
        }
    }
    
    public func addString(_ str: String) {
        cc_addstr(str)
    }
    
    public func printAt(row: Int, col: Int, _ str: String) {
        moveCursor(row: row, col: col)
        addString(str)
    }
    
    public func getKey() -> Int32 {
        return cc_getch()
    }
    
    public func setColor(_ pair: Int16) {
        cc_color_set(pair)
    }
    
    public func resetColor() {
        cc_color_set(0)
    }
    
    public func attrOn(_ attrs: Int32) {
        cc_attr_on(attrs)
    }
    
    public func attrOff(_ attrs: Int32) {
        cc_attr_off(attrs)
    }
    
    public var cols: Int {
        Int(cc_cols())
    }
    
    public var lines: Int {
        Int(cc_lines())
    }
    
    public func setCursorVisibility(_ visible: Bool) {
        cc_curs_set(visible ? 1 : 0)
    }
}

public final class CursesGameUI: GameUI {
    private let curses: CursesUI
    private let engine: GameEngine
    private let statusHeight = 4
    private let messageHeight = 1
    private var messages: [String] = []
    
    public init(curses: CursesUI, engine: GameEngine) {
        self.curses = curses
        self.engine = engine
    }
    
    public func displayMessage(_ message: String) {
        messages.append(message)
        if messages.count > 5 {
            messages.removeFirst()
        }
    }
    
    public func clearScreen() {
        curses.clearScreen()
        curses.refresh()
    }
    
    public func setNonBlocking(_ nonBlocking: Bool) {
        curses.setNonBlocking(nonBlocking)
    }
    
    public func displayMainMenu() {
        curses.clearScreen()
        curses.setNonBlocking(false)
        
        let centerX = max(0, curses.cols / 2 - 20)
        
        curses.moveCursor(row: 2, col: centerX)
        curses.setColor(ColorPair.player)
        curses.addString("+================================+")
        curses.moveCursor(row: 3, col: centerX)
        curses.addString("|       R O G U E L I K E        |")
        curses.moveCursor(row: 4, col: centerX)
        curses.addString("|    A Classic Dungeon Crawler   |")
        curses.moveCursor(row: 5, col: centerX)
        curses.addString("+================================+")
        curses.resetColor()
        
        curses.moveCursor(row: 8, col: centerX + 12)
        curses.addString("1. New Game")
        curses.moveCursor(row: 9, col: centerX + 12)
        curses.addString("2. High Scores")
        curses.moveCursor(row: 10, col: centerX + 12)
        curses.addString("3. Controls")
        curses.moveCursor(row: 11, col: centerX + 12)
        curses.addString("q. Quit")
        
        curses.moveCursor(row: 14, col: centerX + 12)
        curses.addString("Press number to select...")
        
        curses.refresh()
    }
    
    public func displayLevel(_ level: Level) {
        curses.moveCursor(row: statusHeight, col: 0)
        
        let visibleArea = curses.lines - statusHeight - messageHeight - 2
        let visibleWidth = curses.cols - 2
        
        let startY = max(0, min(engine.player.position.y - visibleArea / 2, level.height - visibleArea))
        let startX = max(0, min(engine.player.position.x - visibleWidth / 2, level.width - visibleWidth))
        
        for y in 0..<visibleArea {
            let levelY = startY + y
            curses.moveCursor(row: statusHeight + 1 + y, col: 0)
            
            for x in 0..<visibleWidth {
                let levelX = startX + x
                let pos = Position(x: levelX, y: levelY)
                
                if pos == engine.player.position {
                    curses.setColor(ColorPair.player)
                    curses.addString("@")
                    curses.resetColor()
                    continue
                }
                
                if let enemy = level.enemyAt(pos), level.tileAt(pos)?.isVisible ?? false {
                    curses.setColor(ColorPair.enemy)
                    curses.addString(enemy.displayChar)
                    curses.resetColor()
                    continue
                }
                
                if let item = level.itemAt(pos), level.tileAt(pos)?.isVisible ?? false {
                    curses.setColor(ColorPair.item)
                    curses.addString(item.displayChar)
                    curses.resetColor()
                    continue
                }
                
                let tile = level.tileAt(pos)
                if tile?.isVisible ?? false {
                    curses.setColor(tile?.type == .wall ? ColorPair.wall : ColorPair.floor)
                    curses.addString(tile?.displayChar ?? " ")
                    curses.resetColor()
                } else if tile?.isExplored ?? false {
                    curses.setColor(ColorPair.fog)
                    curses.addString((tile?.displayChar ?? ".").lowercased())
                    curses.resetColor()
                } else {
                    curses.addString(" ")
                }
            }
        }
        
        curses.moveCursor(row: statusHeight + visibleArea + 2, col: 0)
        curses.addString(String(repeating: "-", count: min(curses.cols, visibleWidth)))
        
        for (i, msg) in messages.suffix(3).enumerated() {
            curses.moveCursor(row: curses.lines - messageHeight + i, col: 0)
            curses.addString(String(msg.prefix(curses.cols)))
        }
    }
    
    public func displayPlayer(_ player: Player) {
        curses.moveCursor(row: 0, col: 0)
        
        let healthBar = String(repeating: "#", count: player.stats.health) +
                        String(repeating: ".", count: max(0, player.stats.maxHealth - player.stats.health))
        
        curses.addString("HP: [\(healthBar)] \(player.stats.health)/\(player.stats.maxHealth)  ")
        curses.addString("STR: \(player.effectiveStrength)  ")
        curses.addString("AGI: \(player.effectiveAgility)  ")
        curses.addString("LVL: \(player.stats.level)  ")
        curses.addString("EXP: \(player.stats.experience)/\(player.stats.experienceToLevel)")
        
        curses.moveCursor(row: 1, col: 0)
        let weaponStr = player.weapon?.name ?? "Fists"
        let armorStr = player.armor?.name ?? "Clothes"
        curses.addString("Floor: \(engine.currentLevel)/21  Gold: \(player.stats.gold)  Weapon: \(weaponStr)  Armor: \(armorStr)")
        
        curses.moveCursor(row: 2, col: 0)
        curses.addString(String(repeating: "-", count: curses.cols))
    }
    
    public func displayInventory(_ backpack: Backpack) {
        curses.clearScreen()
        curses.moveCursor(row: 0, col: 0)
        curses.addString("=== INVENTORY ===")
        
        if backpack.items.isEmpty {
            curses.moveCursor(row: 2, col: 0)
            curses.addString("(empty)")
        } else {
            for (i, item) in backpack.items.enumerated() {
                curses.moveCursor(row: 2 + i, col: 0)
                curses.addString("\(i + 1). \(item.name)")
                
                if item.maxHealthValue > 0 { curses.addString(" HP+\(item.maxHealthValue)") }
                if item.strength > 0 { curses.addString(" STR+\(item.strength)") }
                if item.agility > 0 { curses.addString(" AGI+\(item.agility)") }
                if item.defense > 0 { curses.addString(" DEF+\(item.defense)") }
            }
        }
        
        curses.refresh()
    }
    
    public func displayEquipment(weapon: Item?, armor: Item?) {
        curses.clearScreen()
        curses.moveCursor(row: 0, col: 0)
        curses.addString("=== EQUIPMENT ===")
        
        curses.moveCursor(row: 2, col: 0)
        curses.addString("Weapon: \(weapon?.name ?? "(none)")")
        if let w = weapon {
            curses.addString(" (STR: +\(w.strength))")
        }
        
        curses.moveCursor(row: 3, col: 0)
        curses.addString("Armor: \(armor?.name ?? "(none)")")
        if let a = armor {
            curses.addString(" (DEF: +\(a.defense))")
        }
        
        curses.refresh()
    }
    
    public func displayHighScores(_ scores: [HighScoreEntry]) {
        curses.clearScreen()
        curses.moveCursor(row: 0, col: 0)
        curses.addString("=== HIGH SCORES ===")
        
        if scores.isEmpty {
            curses.moveCursor(row: 2, col: 0)
            curses.addString("(no scores yet)")
        } else {
            for (i, entry) in scores.enumerated() {
                curses.moveCursor(row: 2 + i, col: 0)
                curses.addString("\(i + 1). \(entry.playerName): \(entry.score) gold (Floor \(entry.dungeonLevel), \(entry.enemiesKilled) kills)")
            }
        }
        
        curses.refresh()
    }
    
    public func displayHelp() {
        curses.clearScreen()
        
        let centerX = curses.cols / 2 - 20
        
        curses.moveCursor(row: 1, col: centerX)
        curses.setColor(ColorPair.player)
        curses.addString("+====================================+")
        curses.moveCursor(row: 2, col: centerX)
        curses.addString("|            CONTROLS                |")
        curses.moveCursor(row: 3, col: centerX)
        curses.addString("+====================================+")
        curses.resetColor()
        
        curses.moveCursor(row: 5, col: centerX + 5)
        curses.addString("MOVEMENT: W/A/S/D or Arrow keys")
        
        curses.moveCursor(row: 7, col: centerX + 5)
        curses.addString("COMBAT:")
        curses.moveCursor(row: 8, col: centerX + 8)
        curses.addString("Move into enemy to ATTACK")
        
        curses.moveCursor(row: 10, col: centerX + 5)
        curses.setColor(ColorPair.enemy)
        curses.addString("ENEMIES:")
        curses.moveCursor(row: 11, col: centerX + 8)
        curses.addString("z=Zombie, v=Vampire, g=Ghost")
        curses.moveCursor(row: 12, col: centerX + 8)
        curses.addString("O=Ogre, s=Snake Mage, m=Mimic")
        curses.resetColor()
        
        curses.moveCursor(row: 14, col: centerX + 5)
        curses.addString("ITEMS:")
        curses.moveCursor(row: 15, col: centerX + 8)
        curses.addString("G - Pick up")
        curses.moveCursor(row: 16, col: centerX + 8)
        curses.addString("I - Inventory")
        curses.moveCursor(row: 17, col: centerX + 8)
        curses.addString("E - Equipment")
        curses.moveCursor(row: 18, col: centerX + 8)
        curses.addString("U <n> - Use item by number")
        curses.moveCursor(row: 19, col: centerX + 8)
        curses.addString("H <n> - Wield weapon")
        curses.moveCursor(row: 20, col: centerX + 8)
        curses.addString("J - Eat food")
        curses.moveCursor(row: 21, col: centerX + 8)
        curses.addString("K - Drink elixir")
        curses.moveCursor(row: 22, col: centerX + 8)
        curses.addString("R - Read scroll")
        curses.moveCursor(row: 23, col: centerX + 8)
        curses.addString("T - Take off weapon/armor")
        
        curses.moveCursor(row: 25, col: centerX + 5)
        curses.addString("> - Descend stairs")
        curses.moveCursor(row: 26, col: centerX + 5)
        curses.addString("Q - Quit")
        
        curses.moveCursor(row: curses.lines - 2, col: centerX + 5)
        curses.addString("Press any key to go back...")
        curses.refresh()
        _ = curses.getKey()
    }
    
    public func showGameOver(playerWon: Bool) {
        curses.clearScreen()
        curses.moveCursor(row: curses.lines / 2 - 2, col: 0)
        
        if playerWon {
            curses.setColor(ColorPair.exit)
            curses.addString("+====================================+")
            curses.moveCursor(row: curses.lines / 2 - 1, col: 0)
            curses.addString("|    CONGRATULATIONS! YOU WON!       |")
            curses.moveCursor(row: curses.lines / 2, col: 0)
            curses.addString("|      You escaped all 21 floors!     |")
        } else {
            curses.setColor(ColorPair.enemy)
            curses.addString("+====================================+")
            curses.moveCursor(row: curses.lines / 2 - 1, col: 0)
            curses.addString("|            GAME OVER                |")
            curses.moveCursor(row: curses.lines / 2, col: 0)
            curses.addString("|       You have perished...         |")
        }
        
        curses.moveCursor(row: curses.lines / 2 + 1, col: 0)
        curses.addString("+====================================+")
        curses.resetColor()
        curses.refresh()
    }
    
    public func getPlayerInput() -> String? {
        curses.setCursorVisibility(true)
        curses.refresh()
        
        let key = curses.getKey()
        curses.setCursorVisibility(false)
        
        if key == -1 {
            return ""
        }
        
        switch key {
        case 119, 87: return "w"
        case 115, 83: return "s"
        case 97, 65: return "a"
        case 100, 68: return "d"
        case 259: return "w"
        case 258: return "s"
        case 260: return "a"
        case 261: return "d"
        case 103, 71: return "g"
        case 105, 73: return "i"
        case 101, 69: return "e"
        case 106, 74: return "j"
        case 107, 75: return "k"
        case 104, 72: return "h"
        case 62: return ">"
        case 113, 81: return "q"
        case 27: return "q"
        case 63: return "?"
        case 49: return "1"
        case 50: return "2"
        case 51: return "3"
        default:
            if key > 32 && key < 127 {
                return String(Character(UnicodeScalar(UInt8(key))))
            }
            return ""
        }
    }
}
