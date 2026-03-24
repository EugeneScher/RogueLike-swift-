import Foundation

print("RogueLike - A classic dungeon crawler")
print("Loading...")

let engine = GameEngine()
let saveService = SaveService()
let curses = CursesUI()
let ui = CursesGameUI(curses: curses, engine: engine)
let presenter = GamePresenter(ui: ui, engine: engine, saveService: saveService)

if curses.initialize() {
    curses.clearScreen()
    curses.refresh()
    
    presenter.runGameLoop()
    
    curses.shutdown()
} else {
    print("Failed to initialize curses. Falling back to console mode...")
    let consoleUI = ConsoleGameUI(engine: engine, saveService: saveService)
    let consolePresenter = GamePresenter(ui: consoleUI, engine: engine, saveService: saveService)
    consolePresenter.runGameLoop()
}

print("\nThanks for playing!")
