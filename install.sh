#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${LCOM_SCRIPT:-$SCRIPT_DIR/lcom.sh}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
TARGET_SCRIPT="$LOCAL_BIN/lcom.sh"
RC_FILES=("$HOME/.bashrc" "$HOME/.zshrc")
DEFAULT_VM_DIR="$HOME/"

LCOM_SCRIPT="$TARGET_SCRIPT"

countdown_before_prompt() {
  local seconds="${1:-3}"

  if [[ -t 1 ]]; then
    while ((seconds > 0)); do
      printf "\rPrompting for folder in %ds" "$seconds"
      sleep 1
      ((seconds--))
    done
    printf "\r%*s\r" 40 ""
  else
    sleep "$seconds"
  fi
}

VM_DIR=""
countdown_before_prompt 3
if command -v zenity >/dev/null 2>&1; then
  VM_DIR="$(zenity --file-selection --directory --title="LCOM VM folder" --filename="$HOME/" 2>/dev/null || true)"
fi
if [[ -z "$VM_DIR" ]]; then
  read -r -p "VM folder [$DEFAULT_VM_DIR]: " VM_DIR
  VM_DIR="${VM_DIR:-$DEFAULT_VM_DIR}"
fi

for required in "MINIX-LCOM.vbox" "MINIX-LCOM.vbox-prev" "MINIX-LCOM.vdi"; do
  if [[ ! -f "$VM_DIR/$required" ]]; then
    echo "Error: missing '$required' in '$VM_DIR'"
    exit 1
  fi
done

VM_NAME="$(basename "$VM_DIR")"
SHARED_DIR="$VM_DIR/shared"
printf -v VM_NAME_Q '%q' "$VM_NAME"
printf -v SHARED_DIR_Q '%q' "$SHARED_DIR"

ALIAS_BLOCK=$(cat <<EOF
# >>> lcom aliases >>>
alias lcomsh='LCOM_VM_NAME=$VM_NAME_Q "$LCOM_SCRIPT" --ssh'
alias lcomshgui='LCOM_VM_NAME=$VM_NAME_Q "$LCOM_SCRIPT" --ssh --gui'
alias lcomgui='LCOM_VM_NAME=$VM_NAME_Q "$LCOM_SCRIPT" --show'
alias lcomstop='LCOM_VM_NAME=$VM_NAME_Q "$LCOM_SCRIPT" --stop'
lcom_cd() { cd $SHARED_DIR_Q; }
alias lcomcd='lcom_cd'
# <<< lcom aliases <<<
EOF
)

PATH_BLOCK=$(cat <<EOF
# >>> lcom local bin path >>>
if [[ ":\$PATH:" != *":$LOCAL_BIN:"* ]]; then
  export PATH="$LOCAL_BIN:\$PATH"
fi
# <<< lcom local bin path <<<
EOF
)

mkdir -p "$LOCAL_BIN"
if [[ -f "$SOURCE_SCRIPT" && "$SOURCE_SCRIPT" != "$TARGET_SCRIPT" ]]; then
  cp -f "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
fi
chmod +x "$TARGET_SCRIPT"

append_once() {
  local rc_file="$1"
  local marker="$2"
  local block="$3"
  local end_marker="$4"
  local tmp

  [[ -f "$rc_file" ]] || touch "$rc_file"

  if grep -q "$marker" "$rc_file"; then
    tmp="$(mktemp)"
    awk -v s="$marker" -v e="$end_marker" '
      $0 == s { skip=1; next }
      $0 == e { skip=0; next }
      !skip { print }
    ' "$rc_file" > "$tmp"
    mv "$tmp" "$rc_file"
  fi

  { echo; echo "$block"; } >> "$rc_file"
}

remove_existing_lcom_defs() {
  local rc_file="$1"
  local tmp

  [[ -f "$rc_file" ]] || touch "$rc_file"

  tmp="$(mktemp)"
  awk '
    BEGIN { in_lcom_cd=0 }

    in_lcom_cd {
      if ($0 ~ /^}/) {
        in_lcom_cd=0
      }
      next
    }

    /^[[:space:]]*alias[[:space:]]+lcom(sh|shgui|gui|stop|cd)=/ { next }
    /^[[:space:]]*lcom_cd[[:space:]]*\(\)[[:space:]]*\{/ {
      in_lcom_cd=1
      next
    }

    { print }
  ' "$rc_file" > "$tmp"
  mv "$tmp" "$rc_file"
}

for rc_file in "${RC_FILES[@]}"; do
  remove_existing_lcom_defs "$rc_file"
  append_once "$rc_file" "# >>> lcom aliases >>>" "$ALIAS_BLOCK" "# <<< lcom aliases <<<"
  append_once "$rc_file" "# >>> lcom local bin path >>>" "$PATH_BLOCK" "# <<< lcom local bin path <<<"
done

eval "$(echo "$ALIAS_BLOCK" | grep -v '^#')"

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
  echo "Done: installed and loaded"
else
  echo "Done: installed"
  echo "VM: $VM_NAME"
  echo "Shared folder: $SHARED_DIR"
  echo "Run: source ~/.bashrc or source ~/.zshrc"
fi
