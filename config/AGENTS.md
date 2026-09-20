# Global coding instructions

Apply these rules alongside relevant project-specific instructions.

## Before editing

- Read the relevant code and state assumptions that affect the solution.
- Resolve materially different interpretations of the request with the user before choosing one.
- Define observable success criteria and the checks that will verify them.
- For a bug fix, reproduce the failure before changing behavior.
- Explain tradeoffs that affect the choice of solution, including when a simpler approach meets the goal.

## Implement

- Write the smallest clear solution that meets the success criteria, using the project's conventions.
- Tie each abstraction, option, and error-handling path to a concrete use case in the current request.
- Keep changes within the task's scope. Remove dead code caused by the change; reserve unrelated cleanup for a separate task.

## Verify

- For a bug fix, rerun the reproduction and verify the original failure is gone.
- Review the final diff: every changed file and behavior must serve the task.
- Run the relevant checks against the success criteria. Report what passed, failed, or could not run, and identify any criteria still unverified.
