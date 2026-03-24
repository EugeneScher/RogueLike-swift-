import Foundation

public enum GameEvent: Equatable {
    case playerMoved(Position)
    case playerAttacked(Enemy)
    case playerDamaged(Int)
    case playerHealed(Int)
    case playerDied
    case enemyKilled(Enemy, Int)
    case itemPickedUp(Item)
    case itemUsed(Item)
    case levelChanged(Int)
    case gameWon
}

public enum Command: Equatable {
    case move(Direction)
    case pickup
    case useItem(Int)
    case dropItem(Int)
    case equipItem(Int)
    case unequipWeapon
    case unequipArmor
    case showInventory
    case showEquipment
    case descend
    case quit
}

public final class GameEngine {
    public private(set) var currentLevel: Int
    public private(set) var maxLevels: Int
    public private(set) var player: Player
    public private(set) var level: Level
    public private(set) var isGameOver: Bool
    public private(set) var isVictory: Bool
    public private(set) var statistics: GameStatistics
    public private(set) var difficultyManager: DifficultyManager
    
    public var onEvent: ((GameEvent) -> Void)?
    
    private let maxDungeonLevel = 21
    
    public init() {
        self.currentLevel = 1
        self.maxLevels = maxDungeonLevel
        self.player = Player()
        self.level = Level(index: 1)
        self.isGameOver = false
        self.isVictory = false
        self.statistics = GameStatistics()
        self.difficultyManager = DifficultyManager()
        generateLevel()
    }
    
    public func generateLevel() {
        level = Level(index: currentLevel)
        generateRooms()
        generateCorridors()
        level.generateTiles()
        spawnEntities()
        
        if let startRoom = level.rooms.first(where: { $0.isStart }) {
            player.position = startRoom.center
        }
        
        level.updateVisibility(playerPosition: player.position)
        onEvent?(.levelChanged(currentLevel))
    }
    
    private func generateRooms() {
        let roomWidth = 8
        let roomHeight = 5
        let roomSpacing = 18
        let roomOffsetX = 5
        let roomOffsetY = 2
        
        for gridX in 0..<3 {
            for gridY in 0..<3 {
                let isStart = (gridX == 0 && gridY == 0)
                let isEnd = (gridX == 2 && gridY == 2)
                
                let room = Room(
                    origin: Position(x: roomOffsetX + gridX * roomSpacing, y: roomOffsetY + gridY * 6),
                    width: roomWidth,
                    height: roomHeight,
                    gridX: gridX,
                    gridY: gridY,
                    isStart: isStart,
                    isEnd: isEnd
                )
                level.rooms.append(room)
                
                if isStart { level.startRoomId = room.id }
                if isEnd { level.endRoomId = room.id }
            }
        }
    }
    
    private func generateCorridors() {
        for i in 0..<level.rooms.count {
            let roomA = level.rooms[i]
            
            if roomA.gridX < 2 {
                if let roomB = level.rooms.first(where: { $0.gridX == roomA.gridX + 1 && $0.gridY == roomA.gridY }) {
                    createCorridor(from: roomA, to: roomB)
                }
            }
            
            if roomA.gridY < 2 {
                if let roomB = level.rooms.first(where: { $0.gridX == roomA.gridX && $0.gridY == roomA.gridY + 1 }) {
                    createCorridor(from: roomA, to: roomB)
                }
            }
        }
    }
    
    private func createCorridor(from roomA: Room, to roomB: Room) {
        var path: [Position] = []
        var current = roomA.center
        
        while current.x != roomB.center.x {
            path.append(current)
            current = Position(x: current.x + (current.x < roomB.center.x ? 1 : -1), y: current.y)
        }
        
        while current.y != roomB.center.y {
            path.append(current)
            current = Position(x: current.x, y: current.y + (current.y < roomB.center.y ? 1 : -1))
        }
        
        path.append(current)
        
        let corridor = Corridor(fromRoom: roomA.id, toRoom: roomB.id, path: path)
        level.corridors.append(corridor)
    }
    
    private func spawnEntities() {
        let difficulty = difficultyManager.evaluateDifficulty()
        
        for room in level.rooms {
            if room.isStart { continue }
            
            let baseEnemyCount = Int.random(in: 1...3)
            let enemyCount = difficultyManager.calculateEnemyCount(base: baseEnemyCount, level: currentLevel)
            
            for _ in 0..<enemyCount {
                let pos = room.randomFloorPosition()
                if level.isWalkable(pos) && level.enemyAt(pos) == nil {
                    let enemy = createEnemyBasedOnDifficulty(at: pos)
                    level.enemies.append(enemy)
                }
            }
            
            let itemChance = 0.35 + (difficulty.itemMultiplier - 1.0) * 0.1
            if Double.random(in: 0...1) < itemChance {
                let pos = room.randomFloorPosition()
                if level.isWalkable(pos) && level.itemAt(pos) == nil {
                    level.items.append(createRandomItem(at: pos))
                }
            }
            
            if difficultyManager.shouldSpawnExtraHealthItem() {
                let pos = room.randomFloorPosition()
                if level.isWalkable(pos) && level.itemAt(pos) == nil {
                    level.items.append(createHealthItem(at: pos))
                }
            }
        }
        
        if level.items.filter({ $0.type == .treasure }).isEmpty {
            if let endRoom = level.rooms.first(where: { $0.isEnd }) {
                level.items.append(createTreasure(at: endRoom.randomFloorPosition()))
            }
        }
    }
    
    private func createEnemyBasedOnDifficulty(at pos: Position) -> Enemy {
        let bias = difficultyManager.getEnemyTypeBias()
        let roll = Int.random(in: 1...100)
        
        if roll <= 30 && !bias.isEmpty {
            let biasedType = bias.randomElement()!
            return createSpecificEnemy(type: biasedType, at: pos)
        }
        
        return Enemy.createRandom(at: pos, level: currentLevel)
    }
    
    private func createSpecificEnemy(type: EnemyType, at pos: Position) -> Enemy {
        let scaledLevel = currentLevel
        switch type {
        case .zombie: return Enemy.createZombie(at: pos, level: scaledLevel)
        case .vampire: return Enemy.createVampire(at: pos, level: scaledLevel)
        case .ghost: return Enemy.createGhost(at: pos, level: scaledLevel)
        case .ogre: return Enemy.createOgre(at: pos, level: scaledLevel)
        case .snakeMage: return Enemy.createSnakeMage(at: pos, level: scaledLevel)
        case .mimic: return Enemy.createMimic(at: pos, level: scaledLevel)
        }
    }
    
    private func createHealthItem(at pos: Position) -> Item {
        if Bool.random() {
            return Item(position: pos, type: .food, subtype: .food, cost: 1)
        } else {
            return Item(position: pos, type: .elixir, subtype: .elixirHealth, maxHealthValue: 3 + currentLevel / 2, cost: 15, duration: 30)
        }
    }
    
    private func createRandomItem(at pos: Position) -> Item {
        let roll = Int.random(in: 1...100)
        
        let foodChance = difficultyManager.adjustItemChance(forType: .food) * 100
        let elixirChance = difficultyManager.adjustItemChance(forType: .elixir) * 100
        let treasureChance = difficultyManager.adjustItemChance(forType: .treasure) * 100
        
        if roll <= Int(treasureChance) {
            return createTreasure(at: pos)
        } else if roll <= Int(treasureChance) + Int(foodChance) {
            return Item(position: pos, type: .food, subtype: .food, cost: 1)
        } else if roll <= Int(treasureChance) + Int(foodChance) + Int(elixirChance) {
            return createElixir(at: pos)
        } else if roll <= 85 {
            return createScroll(at: pos)
        } else if roll <= 93 {
            return createWeapon(at: pos)
        } else {
            return createArmor(at: pos)
        }
    }
    
    private func createTreasure(at pos: Position) -> Item {
        let gold = Int.random(in: 5...15) * currentLevel
        return Item(position: pos, type: .treasure, subtype: .gold, cost: gold)
    }
    
    private func createElixir(at pos: Position) -> Item {
        let subtypes: [ItemSubtype] = [.elixirHealth, .elixirStrength, .elixirAgility]
        let subtype = subtypes.randomElement()!
        let value = Int.random(in: 2...6) * currentLevel / 2 + 1
        let dur = 20 + currentLevel * 2
        
        switch subtype {
        case .elixirHealth: return Item(position: pos, type: .elixir, subtype: subtype, maxHealthValue: value, cost: value * 5, duration: dur)
        case .elixirStrength: return Item(position: pos, type: .elixir, subtype: subtype, strength: value, cost: value * 5, duration: dur)
        case .elixirAgility: return Item(position: pos, type: .elixir, subtype: subtype, agility: value, cost: value * 5, duration: dur)
        default: return Item(position: pos, type: .elixir, subtype: .elixirHealth, cost: 5)
        }
    }
    
    private func createScroll(at pos: Position) -> Item {
        let subtypes: [ItemSubtype] = [.scrollStrength, .scrollAgility, .scrollHealth]
        let subtype = subtypes.randomElement()!
        let value = Int.random(in: 1...3)
        
        switch subtype {
        case .scrollStrength: return Item(position: pos, type: .scroll, subtype: subtype, strength: value, cost: value * 10)
        case .scrollAgility: return Item(position: pos, type: .scroll, subtype: subtype, agility: value, cost: value * 10)
        case .scrollHealth: return Item(position: pos, type: .scroll, subtype: subtype, maxHealthValue: value, cost: value * 10)
        default: return Item(position: pos, type: .scroll, subtype: .scrollStrength, cost: 10)
        }
    }
    
    private func createWeapon(at pos: Position) -> Item {
        let weapons: [(ItemSubtype, Int, Int)] = [
            (.dagger, 2, 10),
            (.shortSword, 4, 20),
            (.longSword, 7, 50),
            (.twoHandedSword, 12, 100)
        ]
        
        let idx = min(Int.random(in: 0...weapons.count - 1 + currentLevel / 5), weapons.count - 1)
        let (subtype, strength, cost) = weapons[idx]
        
        return Item(position: pos, type: .weapon, subtype: subtype, strength: strength, cost: cost)
    }
    
    private func createArmor(at pos: Position) -> Item {
        let armors: [(ItemSubtype, Int, Int)] = [
            (.leatherArmor, 3, 15),
            (.chainMail, 6, 40),
            (.plateMail, 10, 80)
        ]
        
        let idx = min(Int.random(in: 0...armors.count - 1 + currentLevel / 5), armors.count - 1)
        let (subtype, defense, cost) = armors[idx]
        
        return Item(position: pos, type: .armor, subtype: subtype, defense: defense, cost: cost)
    }
    
    public func execute(_ command: Command) {
        guard !isGameOver else { return }
        
        switch command {
        case .move(let dir):
            handleMove(dir)
        case .pickup:
            handlePickup()
        case .useItem(let idx):
            handleUseItem(idx)
        case .dropItem(let idx):
            handleDropItem(idx)
        case .equipItem(let idx):
            handleEquipItem(idx)
        case .unequipWeapon:
            handleUnequipWeapon()
        case .unequipArmor:
            handleUnequipArmor()
        case .showInventory, .showEquipment, .descend, .quit:
            break
        }
        
        if !isGameOver {
            updateEnemies()
        }
    }
    
    private func handleMove(_ direction: Direction) {
        let newPos = player.position + direction.delta
        
        guard level.isWalkable(newPos) else { return }
        
        if let enemy = level.enemyAt(newPos) {
            handleAttack(enemy)
            return
        }
        
        player.position = newPos
        statistics.recordStep()
        level.updateVisibility(playerPosition: player.position)
        onEvent?(.playerMoved(newPos))
        
        if let item = level.itemAt(newPos) {
            onEvent?(.itemPickedUp(item))
        }
    }
    
    private func handleAttack(_ enemy: Enemy) {
        let hitChance = 0.5 + Double(player.effectiveAgility - enemy.agility) * 0.05
        
        var playerDamageDealt = 0
        var playerDamageTaken = 0
        var updatedEnemy = enemy
        
        // VAMPIRE: First hit always misses
        if updatedEnemy.firstHitMiss {
            updatedEnemy.firstHitMiss = false
            onEvent?(.playerAttacked(enemy))
            statistics.recordMiss()
        } else {
            // Normal attack roll
            if Double.random(in: 0...1) < hitChance {
                let damage = max(1, player.effectiveStrength - enemy.agility / 2 + Int.random(in: -1...2))
                playerDamageDealt = damage
                statistics.recordHit(dealt: damage)
                updatedEnemy.health -= damage
                
                // VAMPIRE: Chance to drain max HP on hit
                if updatedEnemy.type == .vampire && Double.random(in: 0...1) < 0.4 {
                    let drainAmount = updatedEnemy.maxHpDrain
                    player.stats.maxHealth = max(1, player.stats.maxHealth - drainAmount)
                    player.stats.health = min(player.stats.health, player.stats.maxHealth)
                    onEvent?(.playerDamaged(0))
                }
                
                // SNAKE-MAGE: Sleep chance on hit
                if updatedEnemy.type == .snakeMage && Double.random(in: 0...1) < updatedEnemy.sleepChanceOnHit {
                    updatedEnemy.sleepTurns = 2
                }
                
                // GHOST: Becomes visible when hit
                if updatedEnemy.type == .ghost {
                    updatedEnemy.isInvisible = false
                }
                
                if updatedEnemy.health <= 0 {
                    level.removeEnemy(enemy)
                    player.gainExperience(enemy.experience)
                    statistics.recordKill()
                    onEvent?(.enemyKilled(enemy, damage))
                    
                    let treasureDropChance = 0.3 + Double(enemy.hostility) * 0.02
                    if Double.random(in: 0...1) < treasureDropChance {
                        let goldBase = enemy.treasureDropBase
                        let gold = Int.random(in: goldBase...(goldBase * 2)) * currentLevel
                        player.stats.gold += gold
                        statistics.addGold(gold)
                    }
                } else {
                    level.enemies.removeAll { $0.id == enemy.id }
                    level.enemies.append(updatedEnemy)
                }
            } else {
                statistics.recordMiss()
            }
        }
        
        // Enemy counter-attack
        // GHOST: Invisible enemies don't attack unless provoked
        let canEnemyAttack = !(updatedEnemy.type == .ghost && updatedEnemy.isInvisible)
        
        if canEnemyAttack && !player.stats.isDead {
            // OGRE: Guaranteed counter-attack
            let enemyHitChance: Double
            if updatedEnemy.type == .ogre {
                enemyHitChance = 1.0 // Guaranteed hit
            } else {
                enemyHitChance = 0.5 + Double(enemy.agility - player.effectiveAgility) * 0.05
            }
            
            if Double.random(in: 0...1) < enemyHitChance {
                let damage = max(1, enemy.strength - player.effectiveDefense)
                playerDamageTaken = damage
                player.takeDamage(damage)
                onEvent?(.playerDamaged(damage))
                
                // OGRE: Rests after attack
                if updatedEnemy.type == .ogre {
                    updatedEnemy.isResting = true
                    updatedEnemy.hasAttackedThisTurn = true
                    level.enemies.removeAll { $0.id == enemy.id }
                    level.enemies.append(updatedEnemy)
                }
                
                if player.stats.isDead {
                    difficultyManager.recordDeath()
                    isGameOver = true
                    onEvent?(.playerDied)
                }
            }
        }
        
        if playerDamageDealt > 0 || playerDamageTaken > 0 {
            difficultyManager.recordCombatResult(dealt: playerDamageDealt, taken: playerDamageTaken)
        }
    }
    
    private func handlePickup() {
        let itemsAtPosition = level.items.filter { $0.position == player.position }
        
        guard !itemsAtPosition.isEmpty else { return }
        
        var pickedUpCount = 0
        for item in itemsAtPosition {
            if item.type == .treasure {
                player.stats.gold += item.cost
                statistics.addGold(item.cost)
                level.removeItem(item)
                onEvent?(.itemPickedUp(item))
                pickedUpCount += 1
            } else if player.backpack.add(item) {
                level.removeItem(item)
                onEvent?(.itemPickedUp(item))
                pickedUpCount += 1
            }
        }
        
        if pickedUpCount == 0 {
            onEvent?(.itemPickedUp(itemsAtPosition.first!))
        }
    }
    
    private func handleUseItem(_ idx: Int) {
        guard idx < player.backpack.items.count else { return }
        let item = player.backpack.items[idx]
        
        if item.type == .food {
            player.stats.heal(by: 2 + currentLevel / 2)
            _ = player.backpack.remove(at: idx)
            statistics.recordFoodEaten()
            onEvent?(.itemUsed(item))
            onEvent?(.playerHealed(2 + currentLevel / 2))
            return
        }
        
        if item.type == .elixir {
            player.stats.maxHealth += item.maxHealthValue
            player.stats.health += item.maxHealthValue
            player.stats.strength += item.strength
            player.stats.agility += item.agility
            
            if item.isCursed {
                player.stats.health = max(1, player.stats.health - item.maxHealthValue)
            }
            
            _ = player.backpack.remove(at: idx)
            statistics.recordElixirDrunk()
            onEvent?(.itemUsed(item))
            onEvent?(.playerHealed(item.maxHealthValue))
            return
        }
        
        if item.type == .scroll {
            player.stats.strength += item.strength
            player.stats.agility += item.agility
            player.stats.maxHealth += item.maxHealthValue
            player.stats.health += item.maxHealthValue
            
            if item.isCursed {
                player.stats.strength = max(1, player.stats.strength - item.strength * 2)
            }
            
            _ = player.backpack.remove(at: idx)
            statistics.recordScrollRead()
            onEvent?(.itemUsed(item))
            return
        }
    }
    
    private func handleDropItem(_ idx: Int) {
        guard idx < player.backpack.items.count else { return }
        guard let item = player.backpack.remove(at: idx) else { return }
        var droppedItem = item
        droppedItem.position = player.position
        level.items.append(droppedItem)
    }
    
    private func handleEquipItem(_ idx: Int) {
        guard idx < player.backpack.items.count else { return }
        let item = player.backpack.items[idx]
        
        if item.type == .weapon {
            if let oldWeapon = player.weapon {
                var old = oldWeapon
                old.position = player.position
                _ = player.backpack.add(old)
            }
            _ = player.backpack.remove(at: idx)
            player.equipWeapon(item)
        } else if item.type == .armor {
            if let oldArmor = player.armor {
                var old = oldArmor
                old.position = player.position
                _ = player.backpack.add(old)
            }
            _ = player.backpack.remove(at: idx)
            player.equipArmor(item)
        }
    }
    
    private func handleUnequipWeapon() {
        guard let weapon = player.weapon else { return }
        var item = weapon
        item.position = player.position
        if player.backpack.add(item) {
            player.unequipWeapon()
        }
    }
    
    private func handleUnequipArmor() {
        guard let armor = player.armor else { return }
        var item = armor
        item.position = player.position
        if player.backpack.add(item) {
            player.unequipArmor()
        }
    }
    
    private func updateEnemies() {
        for i in 0..<level.enemies.count {
            var enemy = level.enemies[i]
            
            // Skip sleeping enemies
            if enemy.sleepTurns > 0 {
                enemy.sleepTurns -= 1
                level.enemies[i] = enemy
                continue
            }
            
            // Skip resting Ogres (they rest after attacking)
            if enemy.isResting {
                enemy.isResting = false
                level.enemies[i] = enemy
                continue
            }
            
            // GHOST: Become visible over time if idle
            if enemy.type == .ghost && enemy.isInvisible {
                enemy.teleportTimer -= 1
                if enemy.teleportTimer <= 0 {
                    enemy.isInvisible = false
                    enemy.teleportTimer = 5 + enemy.level / 2
                }
            }
            
            // Skip invisible ghosts unless they're hostile
            if enemy.type == .ghost && enemy.isInvisible && !enemy.isHostile {
                level.enemies[i] = enemy
                continue
            }
            
            let distance = enemy.position.manhattanDistance(to: player.position)
            
            // Adjacent enemy - attack
            if distance == 1 {
                enemy.isHostile = true
                level.enemies[i] = enemy
                continue // Combat handled in handleAttack
            }
            
            // Within detection range - chase
            if distance <= enemy.hostility {
                enemy.isHostile = true
                
                switch enemy.type {
                case .zombie:
                    // Slow, steady pursuit
                    let dir = moveTowards(enemy.position, target: player.position)
                    let newPos = enemy.position + dir
                    if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                        enemy.position = newPos
                    }
                    
                case .vampire:
                    // Erratic movement
                    if Int.random(in: 0...1) == 0 {
                        let dir = moveTowards(enemy.position, target: player.position)
                        let newPos = enemy.position + dir
                        if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                            enemy.position = newPos
                        }
                    } else {
                        // Side-step occasionally
                        let sideDir = Direction.allCases.randomElement()!
                        let newPos = enemy.position + sideDir.delta
                        if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                            enemy.position = newPos
                        }
                    }
                    
                case .ghost:
                    // GHOST: Teleport ability
                    enemy.teleportTimer -= 1
                    if enemy.teleportTimer <= 0 {
                        if let randomRoom = level.rooms.filter({ !$0.isStart }).randomElement() {
                            let newPos = randomRoom.randomFloorPosition()
                            if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                                enemy.position = newPos
                            }
                        }
                        enemy.teleportTimer = 4 + enemy.level / 2
                    } else {
                        let dir = moveTowards(enemy.position, target: player.position)
                        let newPos = enemy.position + dir
                        if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                            enemy.position = newPos
                        }
                    }
                    
                case .ogre:
                    // OGRE: Moves 2 spaces
                    var moves = 0
                    while moves < 2 {
                        let dir = moveTowards(enemy.position, target: player.position)
                        let newPos = enemy.position + dir
                        if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                            enemy.position = newPos
                            moves += 1
                        } else {
                            break
                        }
                    }
                    
                case .snakeMage:
                    // SNAKE-MAGE: Diagonal movement
                    let dir = moveDiagonalTowards(enemy.position, target: player.position)
                    let newPos = enemy.position + dir
                    if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                        enemy.position = newPos
                    }
                    
                case .mimic:
                    // Mimics are stationary until provoked
                    if enemy.isHostile {
                        let dir = moveTowards(enemy.position, target: player.position)
                        let newPos = enemy.position + dir
                        if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                            enemy.position = newPos
                        }
                    }
                }
                
                level.enemies[i] = enemy
            } else {
                // Patrol mode for non-hostile enemies
                if !enemy.isHostile && enemy.type != .mimic {
                    let patrolDirs: [Position] = [
                        Position(x: 1, y: 0),
                        Position(x: -1, y: 0),
                        Position(x: 0, y: 1),
                        Position(x: 0, y: -1)
                    ]
                    
                    enemy.moveCount += 1
                    if enemy.moveCount >= 3 {
                        enemy.patrolDirection = (enemy.patrolDirection + 1) % 4
                        enemy.moveCount = 0
                    }
                    
                    let dir = patrolDirs[enemy.patrolDirection % patrolDirs.count]
                    let newPos = enemy.position + dir
                    if level.isWalkable(newPos) && level.enemyAt(newPos) == nil {
                        enemy.position = newPos
                        level.enemies[i] = enemy
                    }
                }
            }
        }
    }
    
    private func moveTowards(_ from: Position, target: Position) -> Position {
        var dx = 0
        var dy = 0
        
        if target.x > from.x { dx = 1 }
        else if target.x < from.x { dx = -1 }
        
        if target.y > from.y { dy = 1 }
        else if target.y < from.y { dy = -1 }
        
        return Position(x: dx, y: dy)
    }
    
    private func moveDiagonalTowards(_ from: Position, target: Position) -> Position {
        var dx = 0
        var dy = 0
        
        if target.x > from.x { dx = 1 }
        else if target.x < from.x { dx = -1 }
        
        if target.y > from.y { dy = 1 }
        else if target.y < from.y { dy = -1 }
        
        // Snake-mage prefers diagonal movement
        if dx != 0 && dy != 0 {
            // Already diagonal direction
        } else if dx != 0 {
            // Add diagonal component
            dy = dx
        } else if dy != 0 {
            // Add diagonal component
            dx = dy
        }
        
        return Position(x: dx, y: dy)
    }
    
    public func descend() {
        if level.tileAt(player.position)?.type == .stairs || level.tileAt(player.position)?.type == .floor {
            difficultyManager.recordLevelCompletion()
            _ = difficultyManager.evaluateDifficulty()
            
            if currentLevel >= maxDungeonLevel {
                isGameOver = true
                isVictory = true
                onEvent?(.gameWon)
            } else {
                currentLevel += 1
                generateLevel()
            }
        }
    }
    
    public func reset() {
        currentLevel = 1
        player = Player()
        isGameOver = false
        isVictory = false
        statistics = GameStatistics()
        difficultyManager.reset()
        generateLevel()
    }
    
    public func movePlayerTo(position: Position) {
        player.position = position
        statistics.recordStep()
        level.updateVisibility(playerPosition: player.position)
        onEvent?(.playerMoved(position))
        
        if let item = level.itemAt(position) {
            onEvent?(.itemPickedUp(item))
        }
    }
    
    public func updateVisibility() {
        level.updateVisibility(playerPosition: player.position)
    }
}
