# Risk It Meow - Project Roadmap & Godot Workflow Guide

## 🐈 Project Overview
**Risk It Meow** is a web-based 3D game centering around cats, room building, and interactive environments. The project is currently transitioning from a React Three Fiber (R3F) architecture to **Godot 4.6** to better support mobile browser performance, load times, robust 3D game logic, and maintainability.

---

## 🏗️ Technical Architecture & Environment
- **Game Engine**: Godot Engine (v4.6.1-stable)
- **Renderer**: `gl_compatibility` (Selected explicitly for broad WebGL mobile browser support and optimized web-native performance)
- **Physics Engine**: Jolt Physics 3D (Replaces Godot's default 3D physics for reliable and performant rigid body calculations)
- **Platform Target**: Web (HTML5/WASM) and Mobile Web
- **Workspace Tooling**: Antigravity AI + Godot MCP (for direct scene creation, node manipulation, and debug output streaming) + Superpowers workflow framework.

---

## 🎮 Game Mechanics & Core Features (To Be Implemented/Ported)
Based on previous prototypes and features within the R3F environment, the core systems required for the Godot port include:
1. **Player Controller**: Main scene navigation and interaction.
2. **Cat Variants**: Systems defining different cat models and logic natively in Godot scenes.
3. **Interactive Actions / UI**: Screen-space or world-space UI components (e.g., the "Stand Up" status banner interactions).
4. **Building Mode & Lighting**:
   - A specialized mode for modifying rooms.
   - Intelligent lighting occlusions (e.g., masking occluded walls during building mode so "Sun Leakage" doesn't ruin interior lighting while allowing the player visibility).
5. **Interactive Props**: Art assets and animated environmental items (e.g., detailed ceiling fans, furniture).

---

## 🛣️ Current Progress & Next Steps

### Phase 1: Engine Transition & Setup ✅
- [x] Initial Godot 4.6 Project Creation
- [x] Web/Mobile Rendering Configuration (`gl_compatibility`)
- [x] Physics Engine configuration (`Jolt Physics`)
- [x] Connect Antigravity Godot MCP for remote AI pipeline access

### Phase 2: Core Foundation & Systems (We are here 📍)
- [ ] **First Task**: (Pending User Input) To be defined by the developer next.
- [ ] Port/Rebuild Player Controller
- [ ] Setup Base Scene with Lighting Environment
- [ ] Define Base Interactive Object Class/Node structure

### Phase 3: Web Mechanics & Interactivity
- [ ] Setup UI overlay system (Status banners, interaction prompts)
- [ ] Port 'Building Mode' camera and occlusion logic
- [ ] Integrate 3D Assets (Ceiling fans, room structures)

### Phase 4: Polish & Optimization
- [ ] Configure Web Export Templates
- [ ] Optimize draw calls and asset sizes for Mobile Browser load times
- [ ] Refine Cat Variants and Animations

---

## 🤖 AI Context & Workflow Rules for Godot
- **Always adhere to Web Accessibility**: Keep polycount, texture sizes, and shaders friendly for mobile web GL rendering.
- **Node Paths**: Prefer distinct, unique node naming to allow safe and reliable MCP interaction.
- **Use the MCP**: Use `mcp_godot_create_scene`, `mcp_godot_add_node`, and `mcp_godot_run_project` tools to rapidly test scenes without waiting for user intervention.
- **File Structure**: Keep scripts in `res://scripts/`, scenes in `res://scenes/`, and assets in `res://assets/` depending on the final agreed upon structure.

> **Note to AI**: Always read this ROADMAP.md when entering a new session to understand the current step in the development cycle. Update the "Current Progress" checkboxes whenever a milestone is hit.
