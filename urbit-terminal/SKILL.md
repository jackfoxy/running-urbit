---
name: urbit-terminal
description: Attach to a running Urbit ship's interactive dojo terminal via screen or tmux. Use when the user wants to interact with the dojo directly, send dojo commands to a ship running in a terminal multiplexer, read dojo output, or manage an interactive urbit session. Triggers include "attach to ship", "dojo", "send dojo command", "ship terminal", "screen urbit", "tmux urbit", "interactive urbit".
user-invocable: true
disable-model-invocation: false
argument-hint: <command> <session-name>
---

# Urbit Interactive Terminal (screen/tmux)

Attach to and interact with a running Urbit ship's dojo terminal through screen or tmux sessions.

## Step 1: Discover Ship Sessions

### Scan for screen sessions

```bash
screen -ls 2>/dev/null | grep -iE '(zod|bus|nec|bud|wes|sev|per|sut|let|ful|pen|syt|dur|wep|ser|wyl|sun|ryp|syx|dyr|nup|heb|peg|lup|dep|urbit|ship|pier)' || echo "No urbit screen sessions found"
```

### Scan for tmux sessions

```bash
tmux list-sessions 2>/dev/null | grep -iE '(zod|bus|nec|bud|wes|sev|per|sut|let|ful|pen|syt|dur|wep|ser|wyl|sun|ryp|syx|dyr|nup|heb|peg|lup|dep|urbit|ship|pier)' || echo "No urbit tmux sessions found"
```

### Broad scan (all sessions)

If ship-name-based discovery finds nothing, list all sessions and ask the user which one:

```bash
screen -ls 2>/dev/null
tmux list-sessions 2>/dev/null
```

### Detect session type

When the user provides a session name, determine which multiplexer owns it:

```bash
# Check screen first
screen -ls 2>/dev/null | grep -q "<SESSION>" && echo "screen" || \
  (tmux has-session -t "<SESSION>" 2>/dev/null && echo "tmux" || echo "not found")
```

## Step 2: Send Commands

### Screen

Send a dojo command to a screen session:

```bash
# Send command followed by Enter
screen -S <SESSION> -X stuff '<DOJO-COMMAND>\n'
```

Examples:
```bash
screen -S zod -X stuff '+vats\n'
screen -S zod -X stuff '|pack\n'
screen -S zod -X stuff '-eval '\''(add 2 2)'\''\n'
```

### Tmux

Send a dojo command to a tmux session:

```bash
# Send command followed by Enter
tmux send-keys -t <SESSION> '<DOJO-COMMAND>' Enter
```

Examples:
```bash
tmux send-keys -t zod '+vats' Enter
tmux send-keys -t zod '|pack' Enter
tmux send-keys -t zod "-eval '(add 2 2)'" Enter
```

### Sending multi-line input

For screen:
```bash
# Send each line separately
screen -S <SESSION> -X stuff 'line1\n'
screen -S <SESSION> -X stuff 'line2\n'
```

For tmux:
```bash
tmux send-keys -t <SESSION> 'line1' Enter
tmux send-keys -t <SESSION> 'line2' Enter
```

## Step 3: Capture Output

### Screen — capture scrollback

```bash
# Capture scrollback to a temp file, then read it
screen -S <SESSION> -X hardcopy -h /tmp/urbit-screen-capture.txt
cat /tmp/urbit-screen-capture.txt
```

For just the last N lines:
```bash
screen -S <SESSION> -X hardcopy -h /tmp/urbit-screen-capture.txt
tail -n 50 /tmp/urbit-screen-capture.txt
```

### Tmux — capture pane

```bash
# Capture visible pane content
tmux capture-pane -t <SESSION> -p

# Capture with scrollback history (last 500 lines)
tmux capture-pane -t <SESSION> -p -S -500
```

### Strategy for command + capture

To send a command and read its output:

1. Capture current scrollback length (baseline)
2. Send the command
3. Wait briefly for the command to complete
4. Capture new scrollback and diff against baseline

```bash
# Tmux example: send command and capture output
tmux capture-pane -t <SESSION> -p -S -500 > /tmp/urbit-before.txt
tmux send-keys -t <SESSION> '<COMMAND>' Enter
sleep 2
tmux capture-pane -t <SESSION> -p -S -500 > /tmp/urbit-after.txt
diff /tmp/urbit-before.txt /tmp/urbit-after.txt | grep '^>' | sed 's/^> //'
```

```bash
# Screen example: send command and capture output
screen -S <SESSION> -X hardcopy -h /tmp/urbit-before.txt
screen -S <SESSION> -X stuff '<COMMAND>\n'
sleep 2
screen -S <SESSION> -X hardcopy -h /tmp/urbit-after.txt
diff /tmp/urbit-before.txt /tmp/urbit-after.txt | grep '^>' | sed 's/^> //'
```

**Note:** The `sleep` duration may need to be increased for long-running commands (e.g. `|pack`, `|meld`, `+vats` on large ships).

## Dojo Command Reference

### Generators (prefixed with +)

| Command | Description |
|---------|-------------|
| `+vats` | Show desk status and OTA info |
| `+code` | Show web login code |
| `+trouble` | Generate a trouble report |
| `+keys` | Show Azimuth key information |

### Hood generators (prefixed with |)

| Command | Description |
|---------|-------------|
| `|pack` | Compact event log |
| `|meld` | Deduplicate persistent state |
| `|ota ~source %desk` | Set OTA source |
| `|ota %disable` | Disable OTAs |
| `|install ~ship %desk` | Install a desk from a ship |
| `|uninstall %desk` | Uninstall a desk |
| `|suspend %desk` | Suspend a desk |
| `|revive %desk` | Revive a suspended desk |
| `|bump` | Force kernel OTA |
| `|exit` | Shut down the ship |
| `|mass` | Print memory report |
| `|hi ~ship` | Ping another ship |
| `|pass` | Pass a task to a vane |

### Threads (prefixed with -)

| Command | Description |
|---------|-------------|
| `-eval '<hoon>'` | Evaluate a Hoon expression |
| `-khan-eval '<thread>'` | Run an inline thread |

### Agent interaction (prefixed with :)

| Command | Description |
|---------|-------------|
| `:agent +dbug` | Debug an agent |
| `:agent &mark <data>` | Poke an agent |
| `:dojo\|allow-remote-login ~ship` | Allow remote dojo access |
| `:dojo\|acl` | View remote access list |

### Dojo-specific commands

| Command | Description |
|---------|-------------|
| `=dir /path` | Change working directory |
| `+ls /path` | List files at path |
| `+cat /path` | Print file contents |
| `Ctrl+X` | Clear the current input line |
| `Ctrl+C` | Cancel current computation |

### Dojo link commands

| Command | Description |
|---------|-------------|
| `\|dojo/link %app` | Connect to a local CLI app |
| `\|dojo/unlink %app` | Disconnect from a CLI app |

## Safety Guards

**Before sending any command, always:**

1. **Confirm the target session** — verify which ship the session belongs to by capturing recent output and looking for the dojo prompt (e.g. `~zod:dojo>`)
2. **Warn before destructive commands** — the following require explicit user confirmation:
   - `|exit` — shuts down the ship entirely
   - `|nuke %desk` — destroys a desk and all its data
   - `|nuke %desk, =sure &` — confirmed destructive nuke
   - `|uninstall %desk` — removes a desk
   - `%ovum` injection via `-eval` or `-khan-eval`
3. **Long-running operations** — warn the user that `|pack`, `|meld`, and `|bump` can take significant time and will block the ship during execution
4. **Never send Ctrl+D** — this detaches the terminal from the ship process; if running directly (not in screen/tmux), this will shut the ship down

## Troubleshooting

### "No screen session found" / "session not found"
- The ship may not be running in screen/tmux
- Check if it's running as a bare process: `pgrep -a urbit`
- Consider using the `urbit-conn` skill instead (conn.c socket doesn't require screen/tmux)

### Commands appear to hang
- The ship may be processing a long computation (spinner shows in terminal)
- Increase the sleep duration before capturing output
- Check if the ship is responsive: send an empty Enter and see if the prompt returns

### Screen hardcopy is empty
- Ensure the screen session name is correct
- Try `screen -ls` to get the exact session identifier (may include PID prefix like `12345.zod`)

### Tmux capture-pane shows old content
- Increase `-S` value to capture more scrollback
- The pane index may be wrong — use `tmux list-panes -t <SESSION>` to check
