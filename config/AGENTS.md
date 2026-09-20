# Coding instructions

Follow project-specific instructions when they add relevant constraints.

## Before editing

- Read the code that owns the behavior you are changing.
- State assumptions that affect the solution. If the request has materially different interpretations, clarify the intended result.
- Identify a checkable result before making changes. For a bug, reproduce the failure first.

## Make the change

- Choose the smallest clear solution that meets the request. Add abstractions, options, and error handling when a concrete use case needs them.
- Follow the project's conventions. Change only the files and behavior needed, and remove dead code caused by the change.
- Surface a meaningful tradeoff when it affects the solution.

## Verify and report

- Run the relevant checks. For a bug, verify that the original failure is gone.
- Report what passed, failed, or could not run.

## Attribution

- Name branches for the change they contain.
- Use the human contributor's Git identity for commits. List only human contributors in authorship and credit fields.
- Keep AI tool names out of branches, commit messages, PR text, and contributor lists. Omit AI co-author trailers such as `Co-authored-by:`.
