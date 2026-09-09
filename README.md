# Pimeä Panimo (Dark Brewery) 🍻

A 2D side-scrolling business management/crafting game built in **Godot 4 (GDScript)**, parodying Finnish alcohol bureaucracy and the murky world of bootleg brewing.

The player buys raw ingredients from a wholesaler, hauls them from the storage cabinet to the preparation table, tunes the ratios, and brews dynamically-generated beer styles (or dark moonshine) for the cellar shelf — all while dodging AVI risk and the inspectors who come knocking. Funny, unique customers wander in with orders and special requests. In-game currencies are **Money (Euros)**, **Reputation (Maine)**, and **AVI Risk (AVI-riski)**.

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
📁 addons/
  📁 godot_ai/            # Live Godot Editor MCP plugin (AI-assisted development tooling)
📁 assets/
  📁 fonts/                # Pixelify Sans, etc.
  📁 shaders/              # Canvas item / particle shaders (lighting, color variety)
  📁 textures/             # Sprites and UI art
📁 scenes/
  customer.tscn / .gd      # Customer actor scene
  main.tscn                # Main game scene (loads UI + world)
  📁 ui/                    # Component-based GUI scenes & controllers
	 gui.gd                    # Top-level UI layer manager
	 top_panel_resources.gd    # Money / Reputation / AVI Risk display
	 left_shop_view.gd, left_brewing_view.gd, right_warehouse_view.gd
	 ingredient_inventory_panel.gd, brew_preparation_panel.gd, beer_batch_panel.gd
	 shop_entrance_panel.gd, brewery_entrance_panel.gd
	 recipe_library_window.gd, special_event_window.gd, avi_raid_window.gd
	 dialog_view.gd, speech_bubble.gd, clock_ui.gd, feature_tester_panel.gd
📁 src/
  📁 autoload/              # Global singletons (orchestration & signal buses)
	 brew_engine.gd            # Core game-state references
	 brewery_signals.gd        # Global gameplay event bus
	 gui_signals.gd            # Global UI event bus
	 ingredient_database.gd    # Auto-loads all ingredient resources
	 customer_registry.gd      # Auto-loads customer resources + name generator
	 customer_manager.gd       # Drives customer arrival/interaction flow
	 special_event_manager.gd  # Drives special-event customer flow
	 time_manager.gd           # In-game clock/day cycle
	 string_container.gd       # Shared, multi-use UI/dialogue strings
  📁 classes/                # Instantiable data components & core logic
	 brewery.gd, brew_preparation.gd, brew_resolver.gd, brew_recipe.gd
	 brew_batch.gd, brew_result.gd, inventory.gd, inventory_item.gd
	 ingredient_data.gd, malt_data.gd, hop_data.gd, yeast_data.gd
	 customer_data.gd, customer_spawner.gd, special_event_data.gd
	 beer_style.gd, pc_prop.gd, brewery_hover_area.gd, warehouse_hover_area.gd
  📁 resources/               # Custom Resource (.tres) definitions and .gd resource scripts
	 📁 ingredients/            # malts/, hops/, yeasts/
	 📁 beer_styles/, customers/, special_events/, sprite_frames/, themes/
```

---

## 🛠️ Running the Project

```bash
# Run the project (editor-configured main scene)
godot --path .

# Run a specific scene directly
godot res://scenes/main.tscn

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
