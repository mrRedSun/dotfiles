# AI Skills

These are the reusable, project-independent skills included in this repository.

| Skill | Use it for |
| --- | --- |
| `architect` | Design types, signatures, and module boundaries before implementation. |
| `arena` | Generate parallel solutions, select a base, and merge the strongest parts. |
| `blast-radius` | Find what a change could break outside the diff and verify its key safety assumption. |
| `bro` | Re-pitch the previous response with enough context and plain language. |
| `code-review` | Review a diff against documented coding standards and the originating spec with parallel sub-agents. |
| `diagnosing-bugs` | Reproduce, narrow, instrument, fix, and verify difficult bugs. |
| `grilling` | Stress-test a plan through focused rounds of questions. |
| `handoff` | Turn the current work into a continuation document for another agent. |
| `how` | Explain runtime flow, ownership, and architecture in an unfamiliar codebase. |
| `interrogate` | Run independent adversarial reviews and synthesize their findings. |
| `resolving-merge-conflicts` | Resolve Git merge or rebase conflicts while preserving intent. |
| `show-me-your-work` | Keep a decision log for long-running or unattended work. |
| `swarm` | Split work across parallel agents and combine their findings. |
| `tdd` | Write a focused failing regression test before fixing a bug when practical. |
| `teach` | Combine how and why into one clear explanation. |
| `technical-writing` | Write and review concise, structured technical documentation. |
| `unslop` | Remove AI writing patterns, filler, and unnatural phrasing. |
| `why` | Investigate the historical reason for code or design decisions using available evidence. |
| `writing-for-agents` | Write skills and other agent-facing instructions, including `AGENTS.md` and `CLAUDE.md`. |

## Using the Skills

Run `./install.sh` to sync the skills as part of the normal dotfiles setup. It links each `skills/<name>` directory into Claude Code and into the shared Codex/OpenCode skill directory. To sync only the skills, run `./scripts/common/ai-skills.sh`.

Each skill's full instructions and any supporting files live under `skills/<name>/`.
