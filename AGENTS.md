<!-- Synced from multica-ai/andrej-karpathy-skills: CLAUDE.md -->
<!-- Run ./scripts/update-agents-md.sh to refresh this file. -->

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

# AARPG Cannon Fodder — Project Rules

## Project structure (DDD)

```
aarpg/
├── player/          # Gracz: CharacterBody3D, utils
├── combat/          # Walka: hit_box, hurt_box, damage
├── world/           # Świat: poziomy, teren, budynki
├── enemies/         # Przeciwnicy
├── weapons/         # Bronie
├── projectiles/     # Pociski
├── items/           # Przedmioty, loot
├── ai/              # FSM, behavior tree, strategie
├── camera/          # Kamera, follow, shake
├── systems/         # Cross-cutting: EventBus, save, audio
├── ui/              # HUD, inventory, dialog
├── assets/          # textures/, models/, materials/, shaders/
├── scripts/         # Narzędzia dev (mcp_interaction_server.gd)
└── tests/           # gdUnit4 — lustro domen
```

Każdy nowy plik ląduje w odpowiedniej domenie, nie w płaskim `Scenes/` czy `scripts/`.

## Godot 4.6 specifics

- **Engine:** Godot 4.6.3, Forward+ renderer, Jolt Physics, d3d12 na Windows
- **GDScript:** `extends`, `class_name`, `@export`, `@onready`, type hints
- **Sceny:** `[gd_scene format=3]`, `load_steps`, `ext_resource`/`sub_resource`
- **UID:** Godot 4.4+ używa `.uid` plików — nie twórz ich ręcznie, edytor generuje
- **Autoloady:** Dodawaj przez `project.godot` → `[autoload]` z `*` prefixem dla `PROCESS_MODE_ALWAYS`
- **Input Map:** `manage_input_map` w godot-mcp lub edytor UI
- **Testy:** gdUnit4 v6.2.0, `extends GdUnitTestSuite`

## Communication patterns

### EventBus (systems/event_bus.gd — autoload)
Globalny bus sygnałów. Każda domena emituje i subskrybuje przez `EventBus`:

```gdscript
# Emitowanie
EventBus.character_moved.emit(global_position)
EventBus.hit_received.emit(target, damage)

# Subskrypcja
EventBus.character_moved.connect(_on_character_moved)
```

### class_name dla dostępu globalnego
Generyczne komponenty rejestrują się przez `class_name` zamiast autoloadu:

```gdscript
# combat/hit_box/hit_box.gd
class_name HitBox extends Area3D

# player/player_utils.gd
class_name PlayerUtils extends RefCounted
```

Inne skrypty używają bezpośrednio: `PlayerUtils.instance()`, `if node is HitBox`.

## Scene conventions

### Generic scenes (HitBox pattern)
Sceny generyczne NIE mają zahardkodowanych kształtów. Owner ustawia shape przez API:

```gdscript
# hit_box.gd — NIE ma shape w .tscn
func set_shape(shape: Shape3D) -> void:
    $CollisionShape3D.shape = shape

# player.gd — owner ustawia shape w _ready()
hit_box.set_shape(hitbox_shape)
```

### Parameters in editor, not hardcoded
Wymiary, prędkości, offsety — wszystko jako `@export var` z sensownym defaultem:

```gdscript
@export var hitbox_radius: float = 0.4
@export var hitbox_height: float = 1.8
```

## PlayerUtils (player/player_utils.gd)
Zawsze używaj `PlayerUtils` zamiast `get_tree().get_nodes_in_group("player")`:

```gdscript
PlayerUtils.instance()           # → CharacterBody3D | null
PlayerUtils.global_position()    # → Vector3
```

## Code quality rules

- **Żaden plik .gd nie może mieć >500 linii** — dziel na mniejsze moduły zanim przekroczysz
- **Brak hardkodowanych wartości** w generycznych komponentach — wszystko `@export`
- **Brak komentarzy** — kod mówi sam za siebie. Jeśli potrzebujesz komentarza, nazwij lepiej zmienną
- **Brak `pass` w pustych blokach** — usuń pustą metodę
- **Jeden `@export_category` na grupę zmiennych** (Physics, Collision, Movement)
- **Sygnały przez EventBus** dla komunikacji między domenami; sygnały lokalne dla komunikacji wewnątrz domeny
- **Sprawdzaj `is_instance_valid()`** przy referencjach do node'ów które mogą być zwolnione
- **`_physics_process`** dla ruchu, **`_process`** dla kamery/UI

## Verifications

Przed oznaczeniem zadania jako gotowe:
```bash
& "C:\Users\Andrz\OneDrive\Desktop\Godot_v4.6.3-stable_win64.exe" --path "aarpg" --headless --quit 2>&1 | Select-String "ERROR|WARNING"
```
Output musi być pusty.
