import Foundation

public protocol GameUI {
    func displayMessage(_ message: String)
    func displayLevel(_ level: Level)
    func displayPlayer(_ player: Player)
    func displayInventory(_ backpack: Backpack)
    func displayEquipment(weapon: Item?, armor: Item?)
    func displayHighScores(_ scores: [HighScoreEntry])
    func displayHelp()
    func displayMainMenu()
    func showGameOver(playerWon: Bool)
    func getPlayerInput() -> String?
    func clearScreen()
    func setNonBlocking(_ nonBlocking: Bool)
}

public final class ConsoleGameUI: GameUI {
    private let engine: GameEngine
    private let saveService: SaveService
    
    public init(engine: GameEngine, saveService: SaveService) {
        self.engine = engine
        self.saveService = saveService
    }
    
    public func clearScreen() {
        print("\u{001B}[2J")
    }
    
    public func displayMessage(_ message: String) {
        print(message)
    }
    
    public func displayMainMenu() {
        print("""
        ╔════════════════════════════════╗
        ║       R O G U E L I K E       ║
        ║    A Classic Dungeon Crawler   ║
        ╚════════════════════════════════╝
        
        1. New Game
        2. High Scores
        3. Controls
        q. Quit
        
        Press number to select...
        """)
    }
    
    public func displayLevel(_ level: Level) {
        var output = ""
        
        for y in 0..<level.height {
            for x in 0..<level.width {
                let pos = Position(x: x, y: y)
                
                if pos == engine.player.position {
                    output += "@"
                    continue
                }
                
                if let enemy = level.enemyAt(pos), level.tileAt(pos)?.isVisible ?? false {
                    output += enemy.displayChar
                    continue
                }
                
                if let item = level.itemAt(pos), level.tileAt(pos)?.isVisible ?? false {
                    output += item.displayChar
                    continue
                }
                
                let tile = level.tileAt(pos)
                if tile?.isVisible ?? false {
                    output += tile?.displayChar ?? "?"
                } else if tile?.isExplored ?? false {
                    let ch = tile?.displayChar ?? "."
                    output += String(ch.lowercased())
                } else {
                    output += " "
                }
            }
            output += "\n"
        }
        
        print(output)
    }
    
    public func displayPlayer(_ player: Player) {
        print(String(repeating: "─", count: 50))
        print("Level: \(player.stats.level)  Dungeon: \(engine.currentLevel)/\(engine.maxLevels)")
        print("HP: \(player.stats.health)/\(player.stats.maxHealth)  Str: \(player.stats.strength)  Exp: \(player.stats.experience)/\(player.stats.experienceToLevel)")
        print("Gold: \(player.stats.gold)  Agility: \(player.stats.agility)  Wisdom: \(player.stats.wisdom)")
        
        if let weapon = player.weapon {
            print("Weapon: \(weapon.name) (+\(weapon.strength) str)")
        }
        if let armor = player.armor {
            print("Armor: \(armor.name) (+\(armor.defense) def)")
        }
        print(String(repeating: "─", count: 50))
    }
    
    public func displayInventory(_ backpack: Backpack) {
        print("═══ INVENTORY ═══")
        if backpack.items.isEmpty {
            print("(empty)")
        } else {
            for (i, item) in backpack.items.enumerated() {
                let cursedStr = item.isCursed ? " [CURSED]" : ""
                print("\(i + 1). \(item.name)\(cursedStr)")
                if item.maxHealthValue > 0 { print("   HP: +\(item.maxHealthValue)") }
                if item.strength > 0 { print("   Str: +\(item.strength)") }
                if item.agility > 0 { print("   Agi: +\(item.agility)") }
                if item.defense > 0 { print("   Def: +\(item.defense)") }
            }
        }
        print("═════════════════")
    }
    
    public func displayEquipment(weapon: Item?, armor: Item?) {
        print("═══ EQUIPMENT ═══")
        print("Weapon: \(weapon?.name ?? "(none)")")
        print("Armor: \(armor?.name ?? "(none)")")
        print("════════════════")
    }
    
    public func displayHighScores(_ scores: [HighScoreEntry]) {
        print("═══ HIGH SCORES ═══")
        if scores.isEmpty {
            print("(no scores yet)")
        } else {
            for (i, entry) in scores.enumerated() {
                print("\(i + 1). \(entry.playerName): \(entry.score) gold (Floor \(entry.dungeonLevel), \(entry.enemiesKilled) kills)")
            }
        }
        print("═══════════════════")
    }
    
    public func displayHelp() {
        print("""
        ═══ COMMANDS ═══
        w/a/s/d - Move
        g - Get item
        i - Show inventory
        e - Show equipment
        u <num> - Use item
        w <num> - Wield/equip item
        t - Take off weapon
        T - Take off armor
        > - Descend stairs
        q - Quit game
        ? - Show help
        ═══════════════
        """)
    }
    
    public func showGameOver(playerWon: Bool) {
        if playerWon {
            print("""
            ╔═══════════════════════════════╗
            ║  CONGRATULATIONS! YOU WON!    ║
            ║  You escaped the dungeon!      ║
            ╚═══════════════════════════════╝
            """)
        } else {
            print("""
            ╔═══════════════════════════════╗
            ║  GAME OVER                    ║
            ║  You have perished...         ║
            ╚═══════════════════════════════╝
            """)
        }
    }
    
    public func setNonBlocking(_ nonBlocking: Bool) {
    }
    
    public func getPlayerInput() -> String? {
        print("\n> ", terminator: "")
        return readLine()
    }
}

public final class GamePresenter {
    private let ui: GameUI
    private let engine: GameEngine
    private let saveService: SaveService
    
    public init(ui: GameUI, engine: GameEngine, saveService: SaveService) {
        self.ui = ui
        self.engine = engine
        self.saveService = saveService
        
        engine.onEvent = { [weak self] event in
            self?.handleEvent(event)
        }
    }
    
    private func handleEvent(_ event: GameEvent) {
        switch event {
        case .playerMoved:
            break
        case .playerAttacked(let enemy):
            ui.displayMessage("You hit the \(enemy.type.rawValue) for damage!")
        case .playerDamaged(let dmg):
            ui.displayMessage("You took \(dmg) damage!")
        case .playerHealed(let amt):
            ui.displayMessage("You healed \(amt) HP.")
        case .playerDied:
            ui.showGameOver(playerWon: false)
        case .enemyKilled(let enemy, _):
            ui.displayMessage("You killed the \(enemy.type.rawValue)! Gained \(enemy.experience) XP.")
        case .itemPickedUp(let item):
            ui.displayMessage("Picked up \(item.name).")
        case .itemUsed(let item):
            ui.displayMessage("Used \(item.name).")
        case .levelChanged(let level):
            ui.displayMessage("You descend to level \(level)...")
        case .gameWon:
            ui.showGameOver(playerWon: true)
        }
    }
    
    public func processInput(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()
        let parts = trimmed.split(separator: " ").map(String.init)
        guard let command = parts.first else { return true }
        
        switch command {
        case "w":
            if parts.count > 1, let num = Int(parts[1]) {
                engine.execute(.equipItem(num - 1))
            } else {
                engine.execute(.move(.north))
            }
        case "s":
            engine.execute(.move(.south))
        case "a":
            engine.execute(.move(.west))
        case "d":
            engine.execute(.move(.east))
        case "g":
            engine.execute(.pickup)
        case "i":
            ui.displayInventory(engine.player.backpack)
        case "e", "E":
            ui.displayEquipment(weapon: engine.player.weapon, armor: engine.player.armor)
        case "h", "H":
            if parts.count > 1, let num = Int(parts[1]) {
                engine.execute(.equipItem(num - 1))
            } else {
                ui.displayInventory(engine.player.backpack)
            }
        case "u", "U":
            if parts.count > 1, let num = Int(parts[1]) {
                engine.execute(.useItem(num - 1))
            } else {
                ui.displayInventory(engine.player.backpack)
            }
        case "j", "J":
            if let foodIndex = engine.player.backpack.items.firstIndex(where: { $0.type == .food }) {
                engine.execute(.useItem(foodIndex))
            } else {
                ui.displayMessage("No food in inventory.")
            }
        case "k", "K":
            if let elixirIndex = engine.player.backpack.items.firstIndex(where: { $0.type == .elixir }) {
                engine.execute(.useItem(elixirIndex))
            } else {
                ui.displayMessage("No elixir in inventory.")
            }
        case "r", "R":
            if let scrollIndex = engine.player.backpack.items.firstIndex(where: { $0.type == .scroll }) {
                engine.execute(.useItem(scrollIndex))
            } else {
                ui.displayMessage("No scroll in inventory.")
            }
        case "t":
            if parts.count > 1 && parts[1] == "a" {
                engine.execute(.unequipArmor)
            } else {
                engine.execute(.unequipWeapon)
            }
        case "T":
            engine.execute(.unequipArmor)
        case ">":
            engine.descend()
        case "q", "quit":
            return false
        case "?":
            ui.displayHelp()
        default:
            ui.displayMessage("Unknown command. Press ? for help.")
        }
        
        return !engine.isGameOver
    }
    
    public func render() {
        ui.displayLevel(engine.level)
        ui.displayPlayer(engine.player)
    }
    
    public func runGameLoop() {
        var running = true
        
        while running {
            ui.setNonBlocking(false)
            ui.displayMainMenu()
            
            guard let input = ui.getPlayerInput() else { continue }
            if input.isEmpty { continue }
            
            switch input {
            case "1":
                engine.reset()
                playGame()
            case "2":
                showHighScores()
            case "3":
                ui.clearScreen()
                ui.displayHelp()
                _ = ui.getPlayerInput()
            case "q", "Q":
                running = false
            default:
                continue
            }
        }
        
        print("\nThanks for playing!")
    }
    
    private func showHighScores() {
        ui.clearScreen()
        ui.displayHighScores(saveService.loadHighScores())
        _ = ui.getPlayerInput()
    }
    
    private func playGame() {
        ui.setNonBlocking(true)
        
        while !engine.isGameOver {
            render()
            
            guard let input = ui.getPlayerInput() else { continue }
            if input.isEmpty { continue }
            
            if !processInput(input) {
                break
            }
        }
        
        ui.setNonBlocking(false)
        showGameEnd()
    }
    
    private func showGameEnd() {
        ui.showGameOver(playerWon: engine.isVictory)
        
        if engine.isVictory {
            print("Score: \(engine.statistics.goldCollected + engine.player.stats.level * 100)")
        } else {
            print("Floor reached: \(engine.currentLevel)   Gold: \(engine.statistics.goldCollected)")
        }
        
        try? saveService.saveHighScore(playerName: "Player", engine: engine)
        _ = ui.getPlayerInput()
    }
}
