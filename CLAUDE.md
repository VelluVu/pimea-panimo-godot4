markdown# Project Instructions and Context - Pimeä Panimo

## Game Description and Genre
- **Genre:** 2D Humorous, Unrealistic Management/Simulation, Casual.
- **Theme:** The player runs a brewery in a dark cellar. Funny, unique customers arrive to buy beer or make special requests.
- **In-Game Resources:** Money (Euros), Reputation (Maine), and AVI Risk (AVI-riski).
- **Perspective:** Side-scrolling.
- **Language:** Code and comments are written in **English**, but the in-game text and user interface display text are written in **Finnish**.

## Project Structure
- `res://addons/godot_ai/` — Live Godot AI MCP plugin infrastructure
- `res://assets/` — Binary resources, split into `fonts/` and `textures/`
- `res://data/` — Static databases and game definitions (`events/`, `recipes/`)
- `res://scenes/` — UI layouts and spatial scenes (e.g., `scenes/ui/`, `customer.tscn`, `main.tscn`)
- `res://src/` — Pure architecture and code logic:
  - `src/autoload/` — Global singleton orchestrators (e.g., `EventBus.gd`)
  - `src/classes/` — Instantiable custom data components and global nodes
  - `src/resources/` — Layout definitions and raw custom `.tres` files

## Architecture
- **Architecture:** Component-based architecture. The UI (GUI) must remain decoupled from game logic; use local and global Signals to communicate between them. 
- **Data Management:** Heavily relies on custom Resources (`.tres`). These are automatically loaded from their respective directories at game launch.
- **Autoload Pattern:** Use `src/autoload/` strictly for global game state orchestration and decoupled communications (e.g., `EventBus.gd`).
- **Decoupling:** Nodes must communicate upstream using **Signals** and downstream via **Methods** ("Signal up, method down"). Avoid hardcoded node paths like `get_node("../../Customer")`.
- **Data-Driven Design:** Configuration tables and item properties (like recipes and events) must live inside custom `Resource` scripts inside `res://data/` or `res://src/resources/`. Never hardcode raw lists directly into components.
- **Scene Scripts:** Scripts directly tied to unique scene nodes can sit inside `res://scenes/` (like `customer.gd` next to `customer.tscn`), but underlying logic should live in `src/`.

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

## Useful CLI Commands
* **Run Project:** `godot --path .`
* **Run Scene directly:** `godot res://scenes/main.tscn`
* **Headless execution (Testing):** `godot --headless --quit`

## Core Nodes and Scenes (Autoloads & Scripts)
- `Main.tscn`: Main game scene that loads the UI and world.
- `BrewEngine.gd`: Autoload (Singleton) class containing core references and state.
- `GUI.gd`: Manages the user interface layer.
- `Brewery.gd`: Core logic for managing the brewery operations.
- `IngredientDatabase.gd`: Loads all raw ingredient resources (e.g., `HopData.tres`, `MaltData.tres`, `YeastData.tres`) automatically from folders at startup.
- `CustomerRegistry.gd`: Loads all customer data resources (`CustomerData.tres`) from folders at startup. Includes a name generator for customers.
- `Inventory.gd`: Tracks currently owned raw ingredients.
- `BrewPreparation.gd`: Tracks ingredients selected for the active brewing process.
- `BrewResolver.gd`: Loads all beer style resources (`BeerStyle.tres`) at startup. Determines the resulting beer style based on chosen ingredients and brewing formulas.
- `DialogView.gd`: Runtime creates dialog UI-elements, like chat bubbles.
- `CustomerSpawner.gd`: Loads Customer.tscn and instantiates random customers.
- `CustomerManager.gd`: Handles the customer interaction.
- `SpecialEventManager.gd`: Handles the special event customer interaction.
- `TimeManager.gd`: Handles the in game time.

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