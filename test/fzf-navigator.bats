#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../fzf-navigator.sh"
OPEN_KEY="enter"
EXIT_KEY="space"
COPY_KEY="ctrl-c"
INSERT_KEY="ctrl-v"
PARENT_KEY="bspace"
PARENT_ALT_KEY="ctrl-bspace"
SMART_BACKSPACE_GUARD="[ -n {q} ] && echo backward-delete-char ||"
COPIED_FOOTER_PREFIX="change-footer(Copied"

setup() {
  source "$SCRIPT"
  export FZF_NAVIGATOR_LS_FORMAT="plain"
  unset FZF_NAVIGATOR_BINDINGS
  export FZF_NAVIGATOR_TMPDIR="$BATS_TEST_TMPDIR/state"
  mkdir -p "$FZF_NAVIGATOR_TMPDIR"
  FIXTURE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$FIXTURE/parent/child" "$FIXTURE/with space"
  touch "$FIXTURE/parent/file one.txt"
  FIXTURE="$(cd "$FIXTURE" && pwd -P)"
}

seed_state() {
  local current_dir="$1"
  echo "$current_dir" > "$FZF_NAVIGATOR_TMPDIR/lock_current_dir"
  echo "$current_dir" > "$FZF_NAVIGATOR_TMPDIR/lock_initial_dir"
  echo "$current_dir" > "$FZF_NAVIGATOR_TMPDIR/session_start_dir"
  echo "$current_dir" > "$FZF_NAVIGATOR_TMPDIR/history"
  echo "0" > "$FZF_NAVIGATOR_TMPDIR/history_index"
}

@test "should bind enter to open when no custom bindings are set" {
  run __fzf_navigator_parse_bindings
  [[ "$output" == *$'\n'"open:$OPEN_KEY"* || "$output" == "open:$OPEN_KEY"* ]]
}

@test "should bind space to exit when no custom bindings are set" {
  run __fzf_navigator_parse_bindings
  [[ "$output" == *"exit:$EXIT_KEY"* ]]
}

@test "should bind ctrl-c to copy and ctrl-v to insert when no custom bindings are set" {
  run __fzf_navigator_parse_bindings
  [[ "$output" == *"copy_selection:$COPY_KEY"* ]]
  [[ "$output" == *"insert_selection:$INSERT_KEY"* ]]
}

@test "should bind bspace and ctrl-bspace to go_to_parent when no custom bindings are set" {
  run __fzf_navigator_parse_bindings
  [[ "$output" == *"go_to_parent:$PARENT_KEY"* ]]
  [[ "$output" == *"go_to_parent:$PARENT_ALT_KEY"* ]]
}

@test "should bind alt keys for history and jumps when no custom bindings are set" {
  run __fzf_navigator_parse_bindings
  [[ "$output" == *"go_back:alt-b"* ]]
  [[ "$output" == *"go_back:alt-left"* ]]
  [[ "$output" == *"go_forward:alt-f"* ]]
  [[ "$output" == *"go_forward:alt-right"* ]]
  [[ "$output" == *"go_to_session_start:alt-s"* ]]
  [[ "$output" == *"go_home:alt-~"* ]]
  [[ "$output" == *"go_to_root:alt-/"* ]]
}

@test "should not bind old or printable keys when no custom bindings are set" {
  run __fzf_navigator_parse_bindings
  local keys
  keys=$(printf '%s\n' "$output" | cut -d: -f2-)
  for old_key in ctrl-space ctrl-y ctrl-d ctrl-alt-o ctrl-alt-i '[' '\' '/'; do
    if printf '%s\n' "$keys" | grep -qxF -- "$old_key"; then
      echo "unexpected default key: $old_key"
      return 1
    fi
  done
}

@test "should replace the default key when FZF_NAVIGATOR_BINDINGS overrides an action" {
  FZF_NAVIGATOR_BINDINGS="ctrl-y:copy_selection"
  run __fzf_navigator_parse_bindings
  [[ "$output" == *"copy_selection:ctrl-y"* ]]
  [[ "$output" != *"copy_selection:$COPY_KEY"* ]]
}

@test "should guard go_to_parent with backward-delete-char when the query is not empty" {
  run __fzf_navigator_build_bind go_to_parent "$PARENT_KEY"
  [[ "$output" == "$PARENT_KEY:transform($SMART_BACKSPACE_GUARD"* ]]
  [[ "$output" == *"__fzf_navigator_transform_parent"* ]]
}

@test "should leave toggle_help without a generic bind" {
  run __fzf_navigator_build_bind toggle_help "?"
  [ -z "$output" ]
}

@test "should move to parent and push history when going to parent" {
  seed_state "$FIXTURE/parent/child"
  run __fzf_navigator_transform_parent
  [ "$(cat "$FZF_NAVIGATOR_TMPDIR/lock_current_dir")" = "$FIXTURE/parent" ]
  [ "$(cat "$FZF_NAVIGATOR_TMPDIR/history_index")" = "1" ]
  [ "$(sed -n 2p "$FZF_NAVIGATOR_TMPDIR/history")" = "$FIXTURE/parent" ]
  [ "$output" = "become(echo //cd)" ]
}

@test "should ignore when going to parent at root" {
  seed_state "/"
  run __fzf_navigator_transform_parent
  [ "$output" = "ignore" ]
  [ "$(cat "$FZF_NAVIGATOR_TMPDIR/history_index")" = "0" ]
}

@test "should truncate forward history when pushing after going back" {
  seed_state "/a"
  printf '%s\n' /a /b /c > "$FZF_NAVIGATOR_TMPDIR/history"
  echo "0" > "$FZF_NAVIGATOR_TMPDIR/history_index"
  __fzf_navigator_push_history "/d"
  [ "$(cat "$FZF_NAVIGATOR_TMPDIR/history")" = $'/a\n/d' ]
  [ "$(cat "$FZF_NAVIGATOR_TMPDIR/history_index")" = "1" ]
  [ "$(cat "$FZF_NAVIGATOR_TMPDIR/lock_current_dir")" = "/d" ]
}

@test "should copy newline-separated unescaped absolute paths when several entries are selected" {
  seed_state "$FIXTURE/parent"
  local fake_bin="$BATS_TEST_TMPDIR/bin"
  local clip_file="$BATS_TEST_TMPDIR/clipboard"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"
  PATH="$fake_bin:$PATH" run __fzf_navigator_transform_copy <<< $'child\nfile one.txt'
  [[ "$output" == "$COPIED_FOOTER_PREFIX 2 paths)" ]]
  [ "$(cat "$clip_file")" = "$FIXTURE/parent/child"$'\n'"$FIXTURE/parent/file one.txt" ]
}

@test "should ignore copy when nothing is selected" {
  seed_state "$FIXTURE/parent"
  run __fzf_navigator_transform_copy <<< ""
  [ "$output" = "ignore" ]
}

@test "should resolve the absolute path in zsh when cd is a function that calls external commands" {
  run zsh -fc '
    cd() { command ls >/dev/null && builtin cd "$@"; }
    source "$1"
    __fzf_navigator_abspath "$2"
  ' _ "$SCRIPT" "$FIXTURE/with space"
  [ "$output" = "$FIXTURE/with space" ]
}

@test "should list the new keys in the help footer when help is toggled" {
  touch "$FZF_NAVIGATOR_TMPDIR/show_help"
  run __fzf_navigator_footer
  [[ "$output" == *"$COPY_KEY"*"copy selection"* ]]
  [[ "$output" == *"$INSERT_KEY"*"insert selection"* ]]
  [[ "$output" == *"$PARENT_KEY"*"go to parent"* ]]
}
