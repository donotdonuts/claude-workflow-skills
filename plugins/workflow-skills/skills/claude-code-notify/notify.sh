#!/usr/bin/env bash
# Claude Code Notification Hook
# Plays a sound/alert when Claude Code needs your input.

EVENT_TYPE="${1:-unknown}"
CLAUDE_NOTIFY_MODE="${CLAUDE_NOTIFY_MODE:-bell}"
CLAUDE_NOTIFY_SOUND="${CLAUDE_NOTIFY_SOUND:-}"
CLAUDE_NOTIFY_VOICE_MSG="${CLAUDE_NOTIFY_VOICE_MSG:-Claude is waiting for your input}"

detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "macos" ;;
        Linux*)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

OS=$(detect_os)

play_bell() {
    printf '\a'
}

play_sound() {
    local sound_file="${1:-}"
    if [[ -z "$sound_file" ]]; then
        case "$OS" in
            macos)  sound_file="/System/Library/Sounds/Glass.aiff" ;;
            linux)  sound_file="/usr/share/sounds/freedesktop/stereo/complete.oga" ;;
        esac
    fi
    if [[ -n "$sound_file" && -f "$sound_file" ]]; then
        case "$OS" in
            macos)  afplay "$sound_file" 2>/dev/null & ;;
            linux)
                if command -v paplay &>/dev/null; then
                    paplay "$sound_file" 2>/dev/null &
                elif command -v aplay &>/dev/null; then
                    aplay "$sound_file" 2>/dev/null &
                elif command -v mpv &>/dev/null; then
                    mpv --no-terminal "$sound_file" 2>/dev/null &
                else
                    play_bell
                fi ;;
            *)  play_bell ;;
        esac
    else
        play_bell
    fi
}

play_voice() {
    case "$OS" in
        macos)  say "$CLAUDE_NOTIFY_VOICE_MSG" 2>/dev/null & ;;
        linux)
            if command -v espeak &>/dev/null; then
                espeak "$CLAUDE_NOTIFY_VOICE_MSG" 2>/dev/null &
            elif command -v spd-say &>/dev/null; then
                spd-say "$CLAUDE_NOTIFY_VOICE_MSG" 2>/dev/null &
            else
                play_bell
            fi ;;
        *)  play_bell ;;
    esac
}

play_osnotify() {
    case "$OS" in
        macos)
            osascript -e 'display notification "Claude is waiting for your input" with title "🔔 Claude Code" sound name "Glass"' 2>/dev/null & ;;
        linux)
            if command -v notify-send &>/dev/null; then
                notify-send "🔔 Claude Code" "Claude is waiting for your input" --icon=dialog-information 2>/dev/null &
            fi
            play_bell ;;
        *)  play_bell ;;
    esac
}

case "$CLAUDE_NOTIFY_MODE" in
    sound)    play_sound "$CLAUDE_NOTIFY_SOUND" ;;
    voice)    play_voice ;;
    osnotify) play_osnotify ;;
    bell|*)   play_bell ;;
esac

exit 0
