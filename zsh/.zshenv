# Raise the soft fd limit only when the hard limit actually allows it
if (( $(ulimit -Hn) >= 2048 )); then
    ulimit -S -n 2048
fi
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
