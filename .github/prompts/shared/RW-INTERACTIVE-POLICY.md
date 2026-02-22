# RW Interactive Policy (Shared)

Use this policy for any prompt decision that needs user input.

1) Try `#tool:vscode/askQuestions` once.
2) If the tool is unavailable, ask the equivalent question in chat once.
3) If still unresolved after that single fallback:
   - If `NON_INTERACTIVE_MODE=true`, continue with safe defaults (`AI_DECIDE` equivalent).
   - Otherwise, stop with the prompt-specific token/cancel behavior.

Rules:
- Do not retry the same decision loop more than once.
- Keep options concise and mutually exclusive when possible.
