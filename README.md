# urbit-skills

Claude Code skills for interacting with running Urbit ships.

## Skills

### urbit-conn

Programmatic ship interaction via the `conn.c` Unix domain socket (`.urb/conn.sock`). Sends commands using `click` or the raw `urbit eval | nc` pipeline without requiring an interactive terminal session.

Supports: scry (`%peek`), runtime queries (`%peel`), thread execution (`%fyrd`), raw event injection (`%ovum`), and runtime commands (`%urth`). Includes ready-to-use templates for common operations like `|pack`, `|meld`, `+code`, `+vats`, `|ota`, and `|install`.

### urbit-terminal

Interactive dojo access through screen or tmux. Discovers running ship sessions, sends dojo commands, and captures output via scrollback buffers.

Includes a dojo command reference covering generators, hood commands, threads, and agent interaction, along with safety guards for destructive operations.

## Installation

Add the skills directory to your Claude Code configuration:

```
/add-dir /path/to/urbit-skills
```

Or place individual skill directories into `~/.claude/skills/`.

## Requirements

- **urbit-conn**: `urbit` binary on PATH (required). `click` on PATH (optional, recommended). `nc` (netcat) for raw socket communication.
- **urbit-terminal**: `screen` or `tmux` with a ship running in a named session.
