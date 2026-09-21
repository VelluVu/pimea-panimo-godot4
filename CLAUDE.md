# Project Instructions and Context - Pimeä Panimo

## Game Description and Genre
- **Genre:** 2D Humorous, Unrealistic Management/Simulation, Casual.
- **Theme:** The player runs a brewery in a dark cellar. Funny, unique customers arrive to buy beer or make special requests.
- **In-Game Resources:** Money (Euros), Reputation (Maine), and LVV Risk (LVV-riski).
- **Perspective:** Side-scrolling.
- **Language:** Code and comments are written in **English**, but the in-game text and user interface display text are written in **Finnish**.

## Project Structure
- `res://addons/godot_ai/` — Live Godot AI MCP plugin infrastructure
- `res://assets/` — Binary resources, split into `fonts/` and `textures/`
- `res://scenes/` — Scenes and the scripts bound to their nodes (`main.tscn`, `customer.tscn`, `scenes/ui/` windows and panels). Keep these scripts thin; logic lives in `src/`.
- `res://src/` — Code logic:
  - `src/autoload/` — Autoloads: the signal buses (`BrewerySignals`, `GUISignals`), registries and managers of cross-run state
  - One folder per gameplay system for its scripts (data classes, services, pure rules). New scripts go in the folder of the system they belong to:
    - `src/brewing/` — recipes, ingredients, `BrewResolver` and its parts (`BrewMixture`, `BrewQuality`, `StylePricing`, `IngredientSource`), `RecipeSearch`, brewing, inventory
    - `src/brewery/` — the `Brewery` run state and its services (raids, distribution, day rules)
    - `src/customers/` — customers, spawning, group visits, sales
    - `src/events/` — special, day and immersion events
    - `src/progression/` — perks, run modifiers, meta unlocks and their rules, achievements, daily goals
    - `src/ui/` — UI helper classes: pure text and layout logic (`OlutoppiText`, `RecipeLibraryText`), small view helpers (`LabelPulse`, `CollapsibleSection`) and tooltip/hover-area nodes
    - `src/console/` — the game's console commands (`PlayerCommands`, the gitignored cheat sets); the console itself is in `src/systems/console/`
    - `src/save/`, `src/audio/` — save file handling, audio bank
  - `src/systems/` — Reusable systems, one self-contained folder each (`dialog/`, `console/`, `toast/`, `tooltip/`, `toolkit/`). Copy a folder to another project and edit its `*_wiring.gd`. See the rule under Architecture.
  - `src/resources/` — All game content as custom `.tres` resources, one folder per type (`customers/`, `beer_styles/`, `ingredients/`, `perks/`, `daily_goals/`, ...), plus the `ResourceFolder` loader
- `res://tests/` — Unit tests, one `test_<class>.gd` per class (the test runner only looks here)
- `res://dev/` — Everything for developing, not shipped: `tools/` (scripts, see Tools), `docs/` (design references such as `beer_styles_reference.txt`) and `notes/` (local playtest notes, gitignored)

## Architecture
- **Architecture:** Component-based architecture. The UI (GUI) must remain decoupled from game logic; use local and global Signals to communicate between them. 
- **Data Management:** Heavily relies on custom Resources (`.tres`). Registries load them from their folders at launch through `ResourceFolder.load_all()`.
- **Autoload Pattern:** Use `src/autoload/` for cross-run state, registries and the signal buses. State that belongs to one run lives on `Brewery` and its services, which are passed in rather than read from `BrewEngine.current_brewery`; prefer that for new code.
- **Decoupling:** Nodes must communicate upstream using **Signals** and downstream via **Methods** ("Signal up, method down"). Avoid hardcoded node paths like `get_node("../../Customer")`.
- **Data-Driven Design:** Configuration tables and item properties (like recipes and events) must live inside custom `Resource` scripts and `.tres` files in `res://src/resources/`. Never hardcode raw lists directly into components.
- **Scene Scripts:** Scripts directly tied to unique scene nodes can sit inside `res://scenes/` (like `customer.gd` next to `customer.tscn`), but underlying logic should live in `src/`.
- **Systems:** Anything meant to be reused lives in `src/systems/<name>/` and references only its own folder: no game classes, autoloads or outside `res://` paths (use relative paths for its own files). It exposes a small interface (methods and signals). A single `<name>_wiring.gd` file inside the folder connects the game's signals (for example `BrewerySignals`) to that interface and holds the game's wording; that is the only file allowed to touch the game and the one to edit when the system moves. Run `python dev/tools/check_systems.py` after changing a system. When a new reusable piece is needed, build it as a system; migrate existing pieces one at a time.
- **Small Classes:** Pure logic (rules, formatting, layout, maths) goes into small `RefCounted` classes with static functions, one class per file, and gets a test. Do not nest classes inside another script.

## Code Style Rules (Godot 4.x / GDScript)
- **Godot 4 Syntax Only:** Do NOT mix up old Godot 3 logic.
  - Use `await` instead of `yield`, and prefer timer nodes.
  - Use `CharacterBody2D/3D` instead of `KinematicBody`.
  - Use lambda syntax `func(): ...` or explicit `Callable` objects instead of legacy string-based signal strings.
- **Static Typing:** Enforce explicit type hints everywhere. Use syntax like `var health: int = 100` or `func take_damage(amount: float) -> void:`.
- **Node References:** Always opt for `@onready var my_node = $Path` or scenes with Scene Unique Names (`%MyNode`).
- **Naming Conventions:** 
  - PascalCase for `class_name` definitions and scene filenames.
  - snake_case for methods, inner properties, custom signals, and directories.
  - UPPER_CASE for structural constants.
- **Signals:** Declare all custom signals at the very top of files: `signal customer_served(order_type: String)`.
- **Comments:** Short. Say why, not what; one to four lines. Names and small functions carry the rest.
- **Strings:** Only strings used in several places go into `StringContainer`; a string used once is a local `const` in its script. Player-facing text is Finnish and never contains an em dash (—); use periods, commas or colons.

## Useful CLI Commands
* **Run Project:** `godot --path .`
* **Run Scene directly:** `godot res://scenes/main.tscn`
* **Headless load check:** `godot --headless --quit` (only checks that the project loads; it does not run the tests)

## Core Nodes and Scenes (Autoloads & Scripts)
- `Main.tscn`: Main game scene that loads the UI and world.
- `BrewEngine` (autoload): holds `current_brewery` and the save/load hooks.
- `Brewery` (`src/brewery/`): the run state (money, reputation, LVV risk, inventory, recipes) and the services that act on it.
- `GUI` (`scenes/ui/gui.gd`): the UI layer; `GuiViewSwitcher` and `GuiAnnouncer` hold its view switching and toasts.
- `IngredientDatabase`, `CustomerRegistry` (autoloads): load all ingredient and customer resources from their folders at startup. `CustomerUnlockTracker` decides which customers are unlocked.
- `Inventory`, `BrewPreparation` (`src/brewing/`): owned ingredients, and the ingredients selected for the active brew.
- `BrewResolver` (`src/brewing/`): loads the beer styles and resolves a brew to a style, with `BrewMixture` (the totals), `BrewQuality` (the quality maths) and `StylePricing` (cost and price).
- `DevConsole` (`src/systems/console/`): the console panel and command registry; `ConsoleWiring` adds the game's commands and log sources.
- `DialogView` (`src/systems/dialog/`): speech bubbles and floating popups, project-independent; `DialogWiring` connects `BrewerySignals` to it. `SpecialEventPresenter` (`src/events/`) opens the special event windows.
- `CustomerSpawner` (`src/customers/`): spawns customers and group visits (`GroupVisitDirector`).
- `CustomerManager` (autoload): counter slots and sales (`SaleProcessor`). `SpecialEventManager` and `DayEventManager` handle special customers and day events.
- `TimeManager` (autoload): in-game time, with `DayRules`.
- `DailyGoalManager`, `MetaProgressManager`, `AchievementManager`, `LeaderboardManager` (autoloads): daily goals (`DailyGoalRules`, `GoalSlot`), the Olutoppi talent tree (`MetaUnlockRules`), achievements and the leaderboard; the last three keep their own `ConfigFile`.
- `SettingsManager`, `InputManager`, `SaveManager`, `AudioManager` (autoloads): settings, rebindable input actions, the run save, and audio.

## Testing and Verification
- Tests are in `tests/`, extend `McpTestSuite` and are run through the MCP `test_run` tool with the editor open. Each run prints about 10 errors and 2 warnings from the save-file tests; those are expected.
- Autoloads are not reachable from tests: preload the script by path (`const XScript := preload(...)`) and inject dependencies, as `test_brew_resolver.gd` does.
- The editor caches preloaded scripts. After editing a script a test preloads, failures that look like the old behavior may be stale; restart the editor before believing them.
- After a change, run the game through MCP and read the game log (`logs_read` with `source="game"`): some errors, like a failed lookup, only show up there. For UI changes take a screenshot too.
- Playtests and `game_eval` can write the real user data in `%APPDATA%/Godot/app_userdata/Pimea Panimo/` (saves, `meta_progress.cfg`, leaderboard). Back it up first and restore it afterwards.

## Tools
- `dev/tools/check_systems.py` checks that every folder in `src/systems/` is self-contained (exit code 1 on a violation).
- `dev/tools/sheets.py` exports the customers and beer styles to spreadsheets (`export`) and reads edited sheets back into the `.tres` files (`import`, a dry run unless `--apply` is given). Needs `pip install openpyxl`. Output goes to `dev/tools/sheets/`, which is gitignored.

## Model Context Protocol (MCP) Live Usage Rules
You are connected to the live Godot Editor via the `godot_ai` MCP plugin. Always utilize your toolsets before guessing or making structural assumptions:
1. **Never Guess Node Paths:** If you need to interface with nodes inside `customer.tscn` or `main.tscn`, use `godot.inspect_scene` or `godot.get_node_properties` first to confirm the exact hierarchy.
2. **Runtime Error Checking:** If a script you wrote throws bugs, do not randomly guess a refactor. Call your runtime/console log tools (`godot.get_error_log` or reading console buffers) to see the exact stack trace.
3. **Modifying Scenes:** You have permission to manipulate node properties or scene nodes via your MCP tools, but prioritize doing UI logic inside the script domain (`.gd`) matching our decoupling rules.

## Claude Behavior Guidelines (Token Saving)
- Never rewrite an entire file unless explicitly asked. Provide only the modified functions or specific lines of code.
- Do not guess node paths (`$Path/To/Node`). If unsure, use the MCP server tools to check the live scene tree.
- Keep explanations concise. Explain the logic briefly in English before providing the code changes.

## Strictly Prohibited Actions (AI Boundaries)
- **Blind Commits:** Never apply deep refactor packages without performing structural runtime validation loops via MCP first.
- **Do Not Override Core Configuration:** Do not touch configuration paths inside `project.godot` without absolute confirmation from the developer.