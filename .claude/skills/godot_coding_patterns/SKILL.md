---
name: godot_coding_patterns
description: Use when designing gameplay systems in this project — enforces Node-based Finite State Machines, Component Composition (e.g. Health/Hitbox-style components), and the global signal buses (Observer) `BrewerySignals` and `GUISignals`. Load when adding customer behavior, brewing state, or any new cross-system interaction.
---

# Godot Coding Patterns (Pimeä Panimo)

Three structural patterns this project standardizes on. Patterns 1 and 2 are guidance for new code: no `State`, `StateMachine` or component classes exist yet, so create them in the system folder that needs them (for example `src/customers/`), not in a `src/classes/` folder. Use these instead of ad hoc state flags, monolithic scripts, or direct cross-node references.

## 1. Node-Based Finite State Machines (FSM)

For any actor with distinct behavioral modes (customer AI, brew process stages, special-event flow), model state as child `Node`s under a `StateMachine` node, not as an enum + giant `match` in one script.

- Structure:
  ```
  Customer (CharacterBody2D)
  └── StateMachine (Node)
      ├── IdleState (Node)
      ├── OrderingState (Node)
      ├── WaitingState (Node)
      └── LeavingState (Node)
  ```
- Each state script extends a common `State` base class (one file per class, in the folder of the system that uses it) with a consistent interface:
  ```gdscript
  class_name State
  extends Node

  signal state_finished(next_state_name: StringName)

  func enter() -> void:
      pass

  func exit() -> void:
      pass

  func process_frame(delta: float) -> void:
      pass

  func process_physics(delta: float) -> void:
      pass
  ```
- `StateMachine.gd` owns the active state reference, calls `exit()`/`enter()` on transition, and forwards `_process`/`_physics_process` to the current state only. It listens for `state_finished` from the active state (signal up) and drives the transition (method down) — states never switch each other directly.
- State names are `StringName` constants or an enum defined once (e.g. in `StateMachine.gd`), never duplicated magic strings across state scripts.
- Use this pattern for: customer behavior (`CustomerManager.gd` interactions), brew stages (`BrewResolver.gd`/`BrewPreparation.gd` flow), special event sequences (`SpecialEventManager.gd`).

## 2. Component Composition

Favor small, single-responsibility components attached as child nodes over deep inheritance hierarchies or one script doing everything.

- Pattern: a `HealthComponent` (or in this project's domain terms, e.g. `PatienceComponent`, `ReputationImpactComponent`) is a standalone `Node`/`Resource`-backed script that:
  - Owns only its own data (`current: float`, `max: float`) and emits signals on change (`signal depleted`, `signal value_changed(new_value: float)`).
  - Exposes methods for its owner to call (`apply_damage(amount: float) -> void`, `reduce_patience(amount: float) -> void`).
  - Never reaches into its parent/owner node — it is attached via the scene tree and communicates purely via signal up / method down.
- Example composition for a customer:
  ```
  Customer (CharacterBody2D)
  ├── StateMachine
  ├── PatienceComponent (Node)      # emits patience_depleted
  └── OrderComponent (Node)         # emits order_placed(recipe: RecipeData)
  ```
- A "Hitbox/Hurtbox"-equivalent in this game's domain: e.g. an `InteractionArea` (`Area2D`) component that detects player proximity/click and emits `interacted` — reused across customer types and brewery equipment rather than duplicating `Area2D` signal-wiring logic in every scene script.
- Components are added in the `.tscn` scene, referenced via `@onready var patience: PatienceComponent = %PatienceComponent`, never instantiated ad hoc in code unless the component must be spawned dynamically (then use `PackedScene.instantiate()`, not `Node.new()` + manual property assembly, if the component has an associated scene).

## 3. Global Signal Buses (Observer Pattern via Autoload)

Two autoloads in `src/autoload/` carry cross-system signals between unrelated branches of the scene tree, so a `Customer` can notify `Brewery` and `GUI` without referencing either:
- `BrewerySignals` (`brewery_signals.gd`): game events going from logic to the UI and other systems, for example `bottles_sold`, `style_discovered`, `lvv_raid_triggered`, `dialogue_pushed`.
- `GUISignals` (`gui_signals.gd`): player actions going from the UI to the logic, for example `buy_ingredient`, `start_brewing`, `ship_batch_to_bar_requested`.

- Declare new cross-cutting signals at the top of the matching bus file with typed arguments. Read the file first and reuse an existing signal if one fits.
- Emitters call `BrewerySignals.some_signal.emit(...)`; they do not hold a reference to the listener.
- Listeners connect in `_ready()`: `BrewerySignals.bottles_sold.connect(_on_bottles_sold)`. Godot auto-disconnects when a listener node is freed; only long-lived non-autoload listeners that get reparented need an explicit disconnect in `_exit_tree()`.
- Reusable folders in `src/systems/` never touch the buses directly. Their single `*_wiring.gd` connects the buses to the system's interface.
- Do not use a bus for tightly-scoped parent-child communication where a direct local signal already works (e.g. a `PatienceComponent` talking to its own owning `Customer`) — reserve it for genuinely global, cross-system events. Overusing the bus for local signals defeats discoverability.
- New global event types are data-driven where payload shape is non-trivial: pass a typed Resource or data object (`CustomerData`, `SaleReceiptEntry`, `Brewery`) as the signal argument rather than several loose primitive arguments, so the schema lives in `src/resources/` alongside other data definitions.

## When Adding a New System

1. Ask: is this a *mode/phase* of one actor? → FSM (pattern 1).
2. Ask: is this a *reusable capability* attachable to multiple actors? → Component (pattern 2).
3. Ask: does this need to notify *other unrelated systems*? → signal bus (pattern 3).

These three patterns compose: a state inside an FSM can emit through a signal bus; a component can drive an FSM transition via its owner. Keep each pattern's responsibility pure — don't let a component reach into a signal bus directly if the owning node can relay it, unless the component is meant to be a global-facing sensor by design.
