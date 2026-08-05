# Pimeä Panimo (Dark Brewery) 🍻

A 2D business management and crafting game made in **Godot 4 (GDScript)**, parodying Finnish alcohol bureaucracy and the murky world of bootleg brewing.

pelaajan tehtävänä on ostaa raaka-aineita tukkukaupasta, nostaa ne varastokaapista valmistelupöydälle, säätää suhteita ja keittää dynaamisesti erilaisia oluttyylejä (tai pimeää kotipolttoa) kellarilistalle myyntiä varten – samalla viranomaisriskiä ja AVI:n tarkastajia vältellen.

---

## 💎 Architectural & Technical Highlights

This project was built from scratch with a heavy focus on clean, decoupled, and highly performant object-oriented programming (OOP) standards in GDScript.

*   **Recursively Self-Loading Database (`IngredientDatabase`)**: The engine completely bypasses hardcoded data lists. It automatically scans the asset directories recursively on startup, dynamically compiling a centralized master dictionary of all custom resources (`IngredientData`, `MaltData`, `HopData`, etc.) sorted strictly by their unique Integer IDs.
*   **Event-Driven & Decoupled Pull-Model UI**: To maximize performance and prevent frame-rate stutters, the user interface relies entirely on a centralized event signal (`brewery_state_changed`). Instead of pushing bloated data frames through parameters or running expensive check-loops in `_process()`, the GUI elements simply react to the event and *pull* exactly the state they need from the data model.
*   **Zero-Garbage UI Node Recycling**: Dynamic containers (like the warehouse storage cabinet and the preparation table) do not instantiate or destroy (`queue_free()`) layout nodes during gameplay. Rows are generated once on `_ready()` in perfect ID-order, and the UI simply toggles their visibility and textual numbers in real-time.
*   **Strongly Typed, Object-Oriented Nested Inventory**: Purity of state is protected via a custom multi-layered nested dictionary system (`items[Type][ID] = InventoryItem`). The mutable entity runtime amounts are completely decoupled from the immutable `.tres` static data resources, preventing data corruption and memory leaks.
*   **Math-Based Crafting Resolver**: Crafting does not use strict, rigid recipes. The game calculations analyze the weighted averages of malt EBC colors, hop Alpha-acids, and yeast attenuation variables dynamically to deduce what batch style emerges from the pot.

---

## 📂 Project Architecture

```text
📁 src/
  📁 autoload/          # Global managers & singletons (BrewEngine.gd, BrewerySignals.gd)
  📁 classes/           # Core object models (Inventory.gd, BrewPreparation.gd, BrewResolver.gd)
  📁 resources/         # Immutable data resource scripts (IngredientData.gd, MaltData.gd)
📁 data/
  📁 ingredients/       # Organized asset sheets (.tres files) subdivided into /malts, /hops, etc.
📁 scenes/
  📁 ui/                # Component-based custom GUI view controls (TopPanelResources.gd, IngredientOptionButton.gd)
```

---

## 📜 License

This repository is published under the **MIT License**. Feel free to study the backend patterns or use them as a foundation for your own Godot 4 manager games!
