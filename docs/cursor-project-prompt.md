Paste the text below into Cursor at the start of work on this repo.

```text
You are working in the Godot project `aarpg-cannon-fodder`.

First, save this context into your project memory/rules/notes if your environment supports persistent project instructions. Treat the following as the current source of truth unless the repo changes.

Project root and layout:
- Repo root: `C:\Users\Andrz\IdeaProjects\aarpg-cannon-fodder`
- Actual Godot project root: `C:\Users\Andrz\IdeaProjects\aarpg-cannon-fodder\aarpg`
- Most app code currently lives in `aarpg/scripts/`
- Main scene: `res://Scenes/test_scene.tscn`
- Generated/cache directory: `aarpg/.godot/` and it should usually not be edited manually

Current verified Godot setup:
- Godot version: `4.6.3 stable`
- Rendering driver on Windows: `d3d12`
- Physics engine: `Jolt Physics`
- Enabled editor plugin: `res://addons/gdUnit4/plugin.cfg`
- Active autoload: `McpInteractionServer="*res://scripts/mcp_interaction_server.gd"`
- There is no `res://addons/godot_mcp/` directory in the project
- Do not reintroduce references to `res://addons/godot_mcp/...` unless the user explicitly restores that addon

Important files:
- `aarpg/project.godot`: project configuration
- `aarpg/Scenes/test_scene.tscn`: current main scene
- `aarpg/scripts/mcp_interaction_server.gd`: runtime TCP bridge/autoload
- `aarpg/.gdlintrc`: gdtoolkit config
- `aarpg/.editorconfig`: UTF-8 only
- `AGENTS.md`: repo-level engineering rules

Runtime bridge facts:
- `McpInteractionServer` runs inside the game as an autoload
- It listens on `127.0.0.1:9090` when the project is running
- It accepts newline-delimited JSON commands over TCP
- It already supports many runtime operations such as screenshot, input, scene tree inspection, property get/set, method calls, node spawning, animation, audio, physics, UI, resource access, and scene changes
- Prefer reusing/extending this bridge instead of inventing a second runtime control layer

Testing and tooling available in this project:
- `gdUnit4` is installed under `aarpg/addons/gdUnit4`
- `gdlint` is available via `gdtoolkit`
- `gdformat` is available via `gdtoolkit`
- Use Godot itself for final behavior verification when changing scenes, scripts, autoloads, or plugins

Verified current state:
- Runtime startup is clean: no current warnings from `mcp_interaction_server.gd`
- Editor startup loads `gdUnit4` successfully
- A stale editor cache caused a warning about missing `.uid` for `res://mcp_interaction_server.gd`; that was fixed by clearing stale generated cache, not by changing project logic

Working rules for this repo:
- Make the smallest correct change
- Do not add speculative abstractions or features
- Do not refactor unrelated code
- Do not edit vendor code under `aarpg/addons/gdUnit4` unless explicitly asked
- Do not rely on `.godot/` contents as stable source files; it is generated state
- Match existing GDScript style and keep changes surgical
- If you see startup failures involving missing addon paths, check `project.godot` first
- Prefer explicit verification over assumptions

When changing this project, use this verification order:
1. Read `aarpg/project.godot` and the touched scene/script.
2. Make the minimal change.
3. Validate script/style with `gdlint` if relevant.
4. Run the project or open the editor to verify behavior.
5. Report only verified results.

If you need to summarize the project back to the user, mention these key facts:
- Godot project root is `aarpg/`
- Main scene is `res://Scenes/test_scene.tscn`
- Runtime bridge is `res://scripts/mcp_interaction_server.gd`
- `gdUnit4` is installed and enabled
- `godot_mcp` addon files are not present in the project
```
