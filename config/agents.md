# Global coding instructions

These are Karpathy-inspired rules for coding agents. Follow project-specific instructions when they add relevant constraints.

## Think before coding

- Read the relevant code and state assumptions that affect the solution.
- If the request has materially different interpretations, clarify the intended result before committing to one.
- Surface meaningful tradeoffs and say when a simpler approach would meet the goal.

## Keep it simple

- Write the smallest clear solution for the current request.
- Add abstractions, options, and error handling when a concrete use case calls for them.
- Prefer code that a reader can understand without tracing unnecessary layers.

## Make focused changes

- Change only the files and behavior needed for the task.
- Match the project's existing conventions.
- Remove dead code caused by the change; leave unrelated cleanup for a separate task.

## Work toward a checkable result

- Define what success looks like before editing.
- For a bug, reproduce it, fix it, and verify the original failure is gone.
- Run the relevant checks and report what passed, failed, or could not run.
