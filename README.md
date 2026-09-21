# Pimeä Panimo (Dark Brewery) 🍻

A 2D side-scrolling business management/crafting game built in **Godot 4 (GDScript)**, parodying Finnish alcohol bureaucracy and the murky world of bootleg brewing.

The player buys raw ingredients from a wholesaler, hauls them from the storage cabinet to the preparation table, tunes the ratios, and brews dynamically-generated beer styles (or dark moonshine) for the cellar shelf — all while dodging LVV risk and the inspectors who come knocking. Funny, unique customers wander in with orders and special requests. In-game currencies are **Money (Euros)**, **Reputation (Maine)**, and **LVV Risk (LVV-riski)**.

> Code and comments are written in English; all in-game text and UI copy are in Finnish.

---

## 💎 Architectural & Technical Highlights

*   **Recursively Self-Loading Databases**: `ingredient_database.gd` and `customer_registry.gd` bypass hardcoded data lists entirely. They scan their resource directories on startup and compile centralized dictionaries of every custom `Resource` (`IngredientData`, `MaltData`, `HopData`, `CustomerData`, etc.), keyed by unique ID.
*   **Event-Driven, Decoupled Pull-Model UI**: The GUI never reaches into game logic directly. Autoload signal buses (`brewery_signals.gd`, `gui_signals.gd`) broadcast state changes; UI panels react and *pull* only the data they need. "Signal up, method down" — no hardcoded node paths.
*   **Zero-Garbage UI Node Recycling**: Dynamic containers (the warehouse cabinet, the preparation table) don't instantiate or `queue_free()` rows during gameplay. Rows are built once on `_ready()` in ID-order; the UI just toggles visibility and updates values.
*   **Strongly Typed, Object-Oriented Inventory**: `inventory.gd` protects state with a multi-layered nested dictionary (`items[Type][ID] = InventoryItem`). Mutable runtime quantities are fully decoupled from the immutable `.tres` static data resources.
*   **Math-Based Crafting Resolver**: `brew_resolver.gd` doesn't use rigid fixed recipes — it weighs malt EBC color, hop alpha-acids, and yeast attenuation to dynamically deduce which beer style emerges from a given batch.
*   **Data-Driven Everything**: Ingredients, beer styles, customers, and special events all live as custom `Resource` (`.tres`) definitions under `src/resources/`, loaded automatically rather than hardcoded into scripts.

---

## 📂 Project Architecture

```text
📁 addons/                  Godot plugins (the godot_ai MCP plugin, dev tools)
📁 assets/                  Fonts, shaders, textures
📁 src/                     The game
  📁 scenes/                Scenes and their bound scripts: main.tscn, customer.tscn, ui/ windows and panels
  📁 systems/               Reusable systems you can copy to another project (see systems/README.md)
    dialog/, console/         Have a *_wiring.gd, the only project-specific file
    toast/, tooltip/, toolkit/  Need no wiring
  📁 autoload/              Signal buses (brewery_signals, gui_signals), registries and managers
  📁 brewing/               Ingredients, recipes, BrewResolver and its parts, inventory
  📁 brewery/               The Brewery run state and its services
  📁 customers/             Customers, spawning, group visits, sales
  📁 events/                Special, day and immersion events
  📁 progression/           Perks, run modifiers, meta unlocks, achievements, daily goals
  📁 ui/                    UI helper classes (text, layout, hover areas)
  📁 console/               The game's console commands
  📁 save/, audio/          Save file handling, audio bank
  📁 resources/             All content as .tres files, one folder per type
📁 tests/                   Unit tests, one test_<class>.gd per class
📁 dev/                     Development only: tools/ (sheets.py, check_systems.py), docs/, notes/ (local)
```

---

## 🛠️ Running the Project

```bash
# Run the project (editor-configured main scene)
godot --path .

# Run a specific scene directly
godot res://src/scenes/main.tscn

# Headless run (e.g. for CI / quick sanity checks)
godot --headless --quit
```

Requires **Godot 4.7** (GL Compatibility renderer).

---

## 🤖 AI-Assisted Development

This project uses a live **Godot Editor MCP plugin** (`addons/godot_ai/`) so an AI assistant can inspect the running scene tree, read runtime errors, and modify nodes directly in the editor rather than guessing at structure. See [CLAUDE.md](CLAUDE.md) for the full set of architecture rules, code style, and AI collaboration guidelines this repo follows.

---

## 📜 License

Copyright (c) 2026 VelluVu. All Rights Reserved. 

This repository contains proprietary software. 
While the source code is publicly visible for transparency, security auditing, and portfolio evaluation, no open-source rights are granted.
