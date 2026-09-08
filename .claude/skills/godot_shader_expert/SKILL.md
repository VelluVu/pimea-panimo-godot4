---
name: godot_shader_expert
description: Use when writing or reviewing Godot Shading Language (GLSL-based) code — canvas_item, spatial, or particle shaders — for this project's dark-cellar/brewery visuals (ambient lighting, liquid/foam effects, particle FX). Covers branchless technique, uniform styling, and performance discipline.
---

# Godot Shader Expert

Godot Shading Language (GDShaderLang, GLSL ES 3.0-based dialect) rules for `.gdshader` files in this project. Applies to canvas_item, spatial, and particle process shaders.

## Branchless Syntax

- Avoid `if`/`else` in fragment/vertex code on GPU-diverging paths. Prefer:
  - `mix(a, b, step(threshold, x))` instead of `if (x >= threshold) { ... } else { ... }`
  - `smoothstep()` for soft thresholds instead of hard conditionals.
  - `clamp()`, `min()`, `max()`, `sign()`, `abs()` to reshape math instead of branching.
- Reserve real `if` statements only for compile-time-constant checks or `#ifdef`-style feature toggles — never for per-pixel data-dependent logic.
- When a boolean uniform toggles an effect, multiply by the branchless mask (`float(bool_uniform)`) rather than wrapping the whole block in `if`.

Example:
```glsl
// Avoid
if (glow_enabled) {
    COLOR.rgb += glow_color * glow_strength;
}

// Prefer
COLOR.rgb += glow_color * glow_strength * float(glow_enabled);
```

## Uniform Styling

- snake_case for all uniform names, matching project GDScript convention.
- Always declare an explicit type and a sane default:
  ```glsl
  uniform vec4 liquid_color : source_color = vec4(0.05, 0.02, 0.01, 1.0);
  uniform float foam_threshold : hint_range(0.0, 1.0) = 0.5;
  uniform sampler2D noise_tex : hint_default_black, repeat_enable;
  ```
- Use `hint_range`, `hint_color`/`source_color`, `hint_default_white/black`, `filter_nearest`/`filter_linear`, and `repeat_enable/repeat_disable` hints so the Inspector exposes sane sliders/pickers — never leave numeric uniforms un-hinted if they represent a bounded value (0–1 strength, angle, etc).
- Group related uniforms together and order them: color/texture uniforms first, then numeric strength/threshold uniforms, then toggles.
- Prefix uniforms shared across multiple shaders (e.g. global cellar ambient tint) with a common prefix (`cellar_ambient_color`) rather than generic names (`color1`).

## Performance Discipline

- Do texture sampling once per unique UV and reuse the result; never sample the same `sampler2D` at the same UV twice in one shader stage.
- Precompute invariant math in `vertex()` and pass via `varying`, not in `fragment()`, when it doesn't depend on per-pixel data.
- Avoid `discard` where a branchless alpha blend achieves the same visual (discard breaks early-Z and hurts mobile perf); use it only for true cutout masks.
- Keep particle process shaders minimal — no texture lookups inside `start()`/`process()` unless required for spawn variation.

## Fit With Project Architecture

- Shaders live under `res://assets/textures/` alongside the materials that use them, or in a dedicated `shaders/` subfolder if one exists — check with `godot.filesystem_manage` / `godot.inspect_scene` (MCP tools) before assuming a path; do not guess.
- Shader parameters that need runtime tuning from GDScript should be set via `material.set_shader_parameter("uniform_name", value)` — never hardcode values that should be data-driven per the project's `res://data/` resource conventions.
