# Agent Guide

Use `CLAUDE.md` (or `GEMINI.md` — they are identical) as the project guidance source for this repo.

## CRITICAL: `gpt:` Trigger

When the user's message starts with `gpt:` — this is NOT a GSD command. Do NOT route it to any skill. Instead, follow the **GPT Workflow** documented in `CLAUDE.md` under the "GPT Workflow — `gpt:` Trigger" section. Read that section and execute steps 1–8 exactly.

Quick summary:
1. Run `.\Godot_v4.6.1-stable_win64.exe --path . -s scripts/tools/snapshot_codebase.gd --headless` to generate `codebase_snapshot.txt`
2. Read `scripts/tools/chatgpt_system_prompt.txt`
3. Use Proxima MCP `ask_chatgpt` to upload the snapshot file and send the system prompt + user request
4. The `ask_chatgpt` call will block until ChatGPT finishes — use its returned response directly
5. Present ChatGPT's plan to the user for review — do NOT apply changes yet
6. Wait for user approval ("go ahead", "do it", etc.)
7. Apply the file changes from ChatGPT's structured response
8. Report what was changed

**TOKEN WARNING:** NEVER call `get_typing_status` in a loop — it wastes tokens. The `ask_chatgpt` call handles waiting internally (zero token cost). Just make ONE `ask_chatgpt` call and use its returned response.

### MANDATORY CHECKLIST — Do NOT skip ANY step

Before calling `ask_chatgpt`, you MUST have completed ALL of these. If you skip any, the workflow FAILS:

- [ ] **Step A: Run the snapshot script.** Run this exact command:
  ```
  .\Godot_v4.6.1-stable_win64.exe --path . -s scripts/tools/snapshot_codebase.gd --headless
  ```
  This generates `codebase_snapshot.txt` in the project root. If you skip this, ChatGPT has NO codebase context.

- [ ] **Step B: Read the system prompt file.** Use `view_file` to read `scripts/tools/chatgpt_system_prompt.txt`. Store its full contents. If you skip this, ChatGPT's response will be unstructured garbage.

- [ ] **Step C: Call `ask_chatgpt` with BOTH the file AND the prompt.** The call MUST include:
  - `files`: `["z:\\RiskItMeow\\risk-it-meow\\codebase_snapshot.txt"]` — THIS IS MANDATORY
  - `message`: the system prompt text + `\n---\nUSER REQUEST: <the user's request>`

  If you send a message WITHOUT the `files` parameter, ChatGPT has NO code to analyze. This is the #1 failure mode. DO NOT SKIP THE FILE UPLOAD.

- [ ] **Step D: ONE call only.** Do NOT call `get_typing_status`. Do NOT make a second `ask_chatgpt` call. Use the response from the single call.

  **EVEN IF the response looks truncated, incomplete, or missing sections — DO NOT send another message.** Present whatever came back to the user AS-IS. If it looks cut off, tell the user: "The response appears truncated. Check the ChatGPT tab directly for the full output." NEVER re-prompt, NEVER "investigate", NEVER send a follow-up asking for more detail. ONE call. That's it.

### What a CORRECT `ask_chatgpt` call looks like

```
ask_chatgpt(
  files: ["z:\\RiskItMeow\\risk-it-meow\\codebase_snapshot.txt"],
  message: "<full contents of chatgpt_system_prompt.txt>\n\n---\n\nUSER REQUEST: <user's request>"
)
```

### What a WRONG call looks like (DO NOT DO THIS)

```
ask_chatgpt(
  message: "add a rug item to the game"    ← NO file attached, NO system prompt
)
```

## Current Direction

- Risk It Meow is now a fresh manual-feature Godot project, not a source-porting project.
- The active baseline currently includes player movement, a 10x10 build floor, one room-view orbit camera, and a runtime chair placement prototype.
- Future work is requested and implemented one feature at a time.

## Guardrails

- Do not assume source-project parity or inspect external source repos unless the user explicitly asks for them again.
- Do not add Firebase, backend sync, shared-room, partner, couple, or multiplayer systems unless the user explicitly restores that scope.
- Do not reintroduce click-to-move unless the user explicitly asks for it.
- Keep the current placement/inventory prototype as part of the active baseline unless the user explicitly asks to replace or remove it.
- Treat cats, walls, and roof as removed from the active baseline until requested again.
