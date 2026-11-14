---
name: redrop
description: Publish artifacts through the `redrop` CLI and return a private link. Use when the user wants a report, HTML page, chart, prototype, file, or static site shared, published, or "given a link", or wants a new version of something already shared.
---

# redrop

redrop turns a file, an HTML page, or a folder into an unguessable **link** on the user's own server. Links can expire, need a password, or stop after N views. The `redrop` CLI is the only interface.

`redrop guide` and `redrop <cmd> --help` are the source of truth for commands, flags, defaults, and exit codes. Read them when you need a flag this page doesn't name.

## 1. Check the CLI is ready

Run `redrop whoami --json`. It prints the server, user, token, and storage usage.

If the command is missing, or exits `8` (not configured) or `3` (bad or revoked token), stop and tell the user:

> Create a token on the redrop dashboard's **Tokens** page and run the setup command shown there.

The user supplies the server URL and token through that setup. Wait for them; a guessed server URL or a token pasted into chat would leak where it should stay local.

**Done when:** `whoami` exits `0`.

## 2. Build the artifact

Every artifact is served from its own sandboxed origin (`https://<slug>.usercontent.example/`), with no backend. Build for that:

- **Documents, explainers, reports, guides:** unless the user wants another look, copy [`templates/doc-page.html`](templates/doc-page.html) to `index.html`, then fill it in following its comments. It is self-contained and has light and dark themes.
- **Charts and other single pages:** one self-contained `.html` file. Inline CSS and JS; CDN scripts work.
- **Multi-page sites and prototypes:** a directory with `index.html` at the root and relative paths throughout. A client-side router needs `--spa`, so unknown extension-less paths serve the entry page.
- **Anything else** (PDF, image, CSV, archive): share the file as is. Viewers get an inline preview and a Download button.
- **State:** keep it in the page. `localStorage` works and is isolated per artifact. The page has no login, no cookies from the user's other sites, and no server of its own to call. Leave secrets and API keys out of it: anyone with the link can read the source.
- **Size:** the server sets the limit per version (typically 500 MB) and a per-user quota; `whoami` shows usage. Exit `5` means too large.

## 3. Publish

Before creating a new link, check whether this artifact was already shared in this conversation or appears in `redrop list --search <title> --json`. If it was, **update** it: the same URL then shows the new version, and anyone holding the link sees the change.

```bash
redrop share report.html --title "Q3 costs" --json          # new link
redrop share ./dist --spa --ttl 30d --json                  # static site
redrop update <id-or-url> report.html --note "fixed totals" --json   # same link, new version
redrop info <id-or-url> --json                              # inspect one
```

Pick access options to fit the purpose:

| Need | Flag |
| --- | --- |
| Expiry | `--ttl 12h`, `7d`, `2w`, or `never`; the server default is usually `7d` |
| Password | `--password-generate`; use `--password-file` for a password the user chose |
| One-time or limited views | `--once` or `--max-views N` |
| Dashboard name | `--title T`; defaults to the page `<title>` or file name |

`update` keeps the link's expiry, password, and view limit. Change those with `redrop set`.

With `--json`, stdout is the artifact object (`id`, `url`, `expires_at`, plus `password` when generated). Errors go to stderr as `{"error", "exit_code"}`. Branch on the exit code: `4` not found, `6` server unreachable, `7` conflict or link used up, and the codes from steps 1 and 2. The full table is in `redrop guide`.

**Done when:** the command exited `0` and you hold the `url` from its output.

## 4. Report back

Give the user the URL, its expiry, and any generated password. The link is a capability: whoever holds it can open the artifact. Give it to the user alone and let them decide who else receives it. Keep it out of commits, issues, and other tools.
