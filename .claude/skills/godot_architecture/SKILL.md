---
name: godot_architecture
description: Use when writing, reviewing, or refactoring GDScript in this project — enforces Godot 4.x static typing, signal-based decoupling, node lifecycle rules, and the project's src/scenes/data structure. Load before touching any .gd file.
---

# Godot Architecture (Godot 4.x, Pimeä Panimo)

Enforces the structural rules from the project's CLAUDE.md. This skill is the authority on *how* GDScript is written and wired in this repo — read it before editing or creating any `.gd` file.

## Static Typing — No Exceptions

- Every variable, parameter, and return type gets an explicit hint:
  ```gdscript
  var health: int = 100
  var reputation: float = 0.0
  func take_damage(amount: float) -> void:
  func get_active_recipe() -> RecipeData:
  ```
- Untyped `var x = something` or `func foo(x):` is not acceptable outside of genuine `Variant`-necessary cases (rare — e.g. a generic signal payload that must accept multiple Resource subtypes). If `Variant` is used, comment why.
- Type arrays and dictionaries where practical: `var ingredients: Array[IngredientData] = []`.
- Use `class_name` + explicit type for custom Resources instead of passing them around as untyped `Resource`.

## Godot 4.x Syntax Only

- `await`, never `yield`.
- `CharacterBody2D`/`CharacterBody3D`, never `KinematicBody`.
- Lambda syntax (`func(): ...`) or bound `Callable` for signal connections — never string-based `connect("signal_name", self, "method_name")` (that's Godot 3).
- `@onready var` and `@export var` annotations, not the old `onready`/`export` keywords.
- Scene Unique Names (`%NodeName`) or `@onready var x = $Path` for node refs — never a hardcoded deep relative path like `get_node("../../Customer")`.

## Signal Up, Method Down

- A child node never reaches upward into a parent's state directly. It emits a signal; the parent (or an autoload) listens and reacts.
- A parent/orchestrator drives a child by calling its public methods directly — not by having the child poll or infer state.
- Declare every custom signal at the very top of the script, above `@export`/`@onready` vars:
  ```gdscript
  signal customer_served(order_type: String)
  signal brew_completed(beer_style: BeerStyle)
  ```
- Cross-system communication (e.g. Customer → Brewery, SpecialEventManager → GUI) goes through `EventBus.gd` (autoload), not direct node references across unrelated branches of the scene tree.
- Before wiring a new signal connection to an existing scene, verify the actual node hierarchy with the live MCP tools (`godot.inspect_scene`, `mcp__godot-ai__scene_get_hierarchy`, `mcp__godot-ai__node_find`) — never guess a node path from memory or from reading `.tscn` text alone if the live editor is available.

## Node Lifecycle Rules

- `_ready()` only sets up this node's own state and connects to signals it owns or subscribes to — it must not assume sibling/parent nodes are already initialized unless order is guaranteed by scene tree position or `@onready` deferred call chains.
- Disconnect signals in `_exit_tree()` (or rely on Godot's automatic disconnect-on-free for object-to-object connections) when a node connects to a long-lived autoload — a short-lived node (e.g. a spawned `customer.tscn` instance) connecting to `EventBus` must not leak a dangling connection after `queue_free()`.
- Prefer `queue_free()` over `free()` for any node that might still be mid-signal-emission.
- One-shot timers for delayed logic: use a `Timer` node with `one_shot = true`, not manual `await get_tree().create_timer(...).timeout` sprinkled ad hoc, when the delay is a reusable/tunable gameplay value (e.g. customer patience timeout) — that value belongs in a data Resource, not a magic number in the script.

## Project Structure Placement

- `src/autoload/` — only global orchestration singletons (`EventBus.gd`, `BrewEngine.gd`, `TimeManager.gd`, etc.), registered in `project.godot` autoload list. Never put per-instance scene logic here.
- `src/classes/` — instantiable custom data components and reusable global-purpose nodes.
- `src/resources/` — `.tres` resource definitions and the `Resource`-derived scripts that define their schema (e.g. `RecipeData.gd`, `CustomerData.gd`).
- `data/` — the actual `.tres` data files (recipes, events) loaded by the corresponding `*Database.gd` / `*Registry.gd` autoload at startup.
- `scenes/` — `.tscn` files and the script directly bound to that unique scene node (e.g. `customer.gd` beside `customer.tscn`). Business logic that isn't scene-specific still belongs in `src/`, called from the scene script.
- Never hardcode a raw list of items/stats/recipes inline in a script — it belongs as a `Resource` under `data/` or `src/resources/`.

## Naming

- PascalCase: `class_name` declarations, scene filenames (`Customer.tscn` — verify existing casing on disk before introducing a new one, this repo currently uses lowercase `customer.tscn`, so match existing sibling files rather than the abstract rule when they conflict).
- snake_case: methods, properties, custom signals, directories, file names for `.gd` scripts.
- UPPER_CASE: constants (`const MAX_REPUTATION: int = 100`).

## Before Committing a Structural Change

- Never touch `project.godot` autoload/input map entries without explicit developer confirmation.
- Never apply a deep refactor without first validating against the live scene tree via MCP tools — check `godot.get_error_log` / `mcp__godot-ai__logs_read` after any script edit that touches a node already running in the editor.
