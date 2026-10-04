#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Opt-in setup: stage a Desktop preset without activating it before the user
# supplies their gateway token. Desktop routing does not use CLI settings.json.
if [[ "$(detect_os)" != "macos" ]]; then
  say "Claude Desktop proxy setup requires macOS." >&2
  exit 1
fi

python3 - "$BACKUP_DIR" <<'PY'
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import uuid

support = Path.home() / "Library/Application Support"
library = support / "Claude-3p/configLibrary"
backup = Path(sys.argv[1]) / "claude-desktop-proxy"


def read_json(path, fallback):
    if not path.exists():
        return fallback
    data = json.loads(path.read_text())
    if not isinstance(data, dict):
        raise ValueError(f"Expected a JSON object in {path}")
    return data


def write_json(path, data):
    if path.exists() and read_json(path, {}) == data:
        return
    if path.exists():
        destination = backup / path.relative_to(support)
        destination.parent.mkdir(parents=True, exist_ok=True)
        # Do not replace an earlier backup if the script is run twice.
        if destination.exists():
            destination = destination.with_name(f"{destination.name}.{uuid.uuid4()}")
        shutil.copy2(path, destination)
        destination.chmod(0o600)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as output:
            json.dump(data, output, indent=2)
            output.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


meta_path = library / "_meta.json"
meta = read_json(meta_path, {"appliedId": "", "entries": []})
entries = meta.get("entries")
if not isinstance(entries, list):
    raise ValueError(f"Expected an entries array in {meta_path}")
for entry in entries:
    if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
        raise ValueError(f"Invalid configuration entry in {meta_path}")
    uuid.UUID(entry["id"])

# An empty default keeps the existing Desktop login mode active until Apply
# Changes is selected. Preserve any previously applied configuration.
default_id = None
if not entries:
    default_id = str(uuid.uuid4())
    entries.append({"id": default_id, "name": "Default"})
    meta["appliedId"] = default_id

entry = next((item for item in entries if item["name"] == "CLIProxy"), None)
if entry is None:
    entry = {"id": str(uuid.uuid4()), "name": "CLIProxy"}
    entries.append(entry)
config_path = library / f'{entry["id"]}.json'
config = read_json(config_path, {})
config.update({
    "inferenceProvider": "gateway",
    "inferenceCredentialKind": "static",
    "inferenceGatewayBaseUrl": "https://agents-api.lviv.win",
    "inferenceGatewayAuthScheme": "bearer",
})
# Never copy a token from another provider or put a placeholder in the key field.
developer_path = support / "Claude/developer_settings.json"
developer = read_json(developer_path, {})
developer["allowDevTools"] = True

if default_id:
    write_json(library / f"{default_id}.json", {})
write_json(config_path, config)
write_json(meta_path, meta)
write_json(developer_path, developer)
print(f"CLIProxy preset saved: {config_path}")
print("Quit and reopen Claude, then open Developer > Configure Third-Party Inference.")
print("Select CLIProxy, enter Gateway API key, then Apply Changes > Save & Restart.")
PY
