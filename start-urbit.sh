#!/bin/bash

# --- CONFIGURATION ---
PIER_NAME="my-comet"
SESSION_NAME="urbit-session"
# Color codes for better visual separation
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color
# ---------------------

# Function to print script messages with formatting
script_msg() {
    echo -e "${GREEN}${BOLD}==> ${NC}${BOLD}$1${NC}"
}

script_info() {
    echo -e "${CYAN}    $1${NC}"
}

script_error() {
    echo -e "${RED}Error: $1${NC}"
}

# Function to strip ANSI escape sequences and format log output
format_log() {
    # Strip ANSI escape sequences, then prefix each line with dimmed [LOG]
    while IFS= read -r line; do
        # Remove all ANSI escape sequences
        clean_line=$(echo "$line" | sed 's/\x1B\[[0-9;]*[A-Za-z]//g' | sed 's/\x1B\]//g' | sed 's/\r//g')
        echo -e "${DIM}[LOG] ${clean_line}${NC}"
    done
}

# 0. Setup and Safety Cleanup
cd ~
mkdir -p running-urbit
cd running-urbit || exit

# Kill any zombie tail processes from previous runs
pkill -f "tail -f.*urbit-boot.log" 2>/dev/null


OS="$(uname -s)"; ARCH="$(uname -m)"
# 1. Detect System & URL
if [ "$OS" = "Linux" ]; then
   OPEN_CMD="xdg-open"
   if [ "$ARCH" = "x86_64" ]; then URL="https://urbit.org/install/linux-x86_64/latest";
   elif [ "$ARCH" = "aarch64" ]; then URL="https://urbit.org/install/linux-aarch64/latest"; fi
elif [ "$OS" = "Darwin" ]; then
   OPEN_CMD="open"
   if [ "$ARCH" = "x86_64" ]; then URL="https://urbit.org/install/macos-x86_64/latest";
   elif [ "$ARCH" = "arm64" ]; then URL="https://urbit.org/install/macos-aarch64/latest";
   else script_error "Unknown macOS system architecture"; exit 1; fi
fi

if [ -z "$URL" ]; then script_error "Unsupported System."; exit 1; fi

script_msg "$OS detected, using $ARCH architecture."

# 2. Dependency Checks
if ! command -v screen &> /dev/null
  then
  script_error "Install 'screen' using your preferred package manager"
  script_error "'screen' missing."
  exit 1
fi

# 3. Download (Silent)
if [ ! -f "./urbit" ]; then
   script_msg "Downloading Urbit runtime..."
   if [ "$OS" = "Darwin" ]; then
       curl -sS -L "$URL" | tar xzk -s '/.*/urbit/'
   elif [ "$OS" = "Linux" ]; then
       curl -sS -L "$URL" | tar xzk --transform='s/.*/urbit/g'
   fi
fi

# 4. Check for duplicate screen session
if screen -list | grep -q "$SESSION_NAME"; then
   script_msg "Session '$SESSION_NAME' already running."
   script_info "Attach with: screen -r $SESSION_NAME"
   exit 1
fi

# 5. Config Setup (Persistent)
WORK_DIR=$(pwd)
LOGFILE="$WORK_DIR/urbit-boot.log"
CONFIG_FILE="$WORK_DIR/.screenrc.urbit"

rm -f "$LOGFILE"

cat <<EOF > "$CONFIG_FILE"
logfile $LOGFILE
logfile flush 0
defscrollback 5000
msgwait 0
EOF

# 6. Prepare boot command
if [ -d "$PIER_NAME" ]; then
   script_msg "Resuming existing ship '$PIER_NAME'..."
   CMD="./urbit $PIER_NAME"
else
   script_msg "Creating new Comet '$PIER_NAME'..."
   CMD="./urbit -c $PIER_NAME"
fi

# 7. Start Session
script_msg "Launching screen session '$SESSION_NAME'..."

screen -L -c "$CONFIG_FILE" -dmS "$SESSION_NAME" bash -c "$CMD; exec bash"

sleep 2

if ! screen -list | grep -q "$SESSION_NAME"; then
    script_error "Screen session died immediately."
    exit 1
fi

echo -e "\n${YELLOW}════════════════════════════════════════════════════════════════${NC}"
script_msg "Urbit is running. Booting..."
script_info "(The script will stay open. Press 'q' to stop monitoring, Urbit will keep running)"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}\n"

# ----------------------------------------------
# PHASE 1: Initial Log Monitor
# ----------------------------------------------

FILTER_PATTERN="urbit [0-9]|boot: downloading|boot: home|boot: found|bootstrap|clay: kernel|clay: base|vere: checking|http: web interface|pier .* live|mdns: .* registered"

tail -f "$LOGFILE" 2>/dev/null | grep --line-buffered -E "$FILTER_PATTERN" | format_log &
TAIL_PID=$!

trap "kill $TAIL_PID 2>/dev/null" EXIT

# ----------------------------------------------
# PHASE 2: Wait for URL
# ----------------------------------------------

URL_FOUND=""
URL_TIMEOUT=600
COUNTER=0

while [ $COUNTER -lt $URL_TIMEOUT ]; do
   if [ -f "$LOGFILE" ]; then
       DETECTED_URL=$(grep "http: web interface live on http://localhost:" "$LOGFILE" | grep -o "http://localhost:[0-9]*" | tail -1)
       if [ ! -z "$DETECTED_URL" ]; then
           URL_FOUND="$DETECTED_URL"
           break
       fi
   fi
   sleep 2
   ((COUNTER+=2))
done

if [ -z "$URL_FOUND" ]; then
    script_error "Timeout waiting for Urbit URL."
    exit 1
fi

# ==========================================================
# PAUSE! Clean up the terminal
# ==========================================================

disown $TAIL_PID
kill $TAIL_PID 2>/dev/null
echo "" 
sleep 1 

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}✓ Web interface is live at ${YELLOW}$URL_FOUND${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"

# ----------------------------------------------
# PHASE 3: Get Code (Quietly)
# ----------------------------------------------

script_msg "Waiting for Dojo to retrieve +code..."
sleep 15

if screen -list | grep -q "$SESSION_NAME"; then
    screen -S "$SESSION_NAME" -p 0 -X stuff "+code$(printf \\r)"
else
    script_error "Screen session died unexpectedly."
    exit 1
fi

# Wait for code
CODE_FOUND=""
CODE_COUNTER=0
while [ $CODE_COUNTER -lt 20 ]; do
   if [ -f "$LOGFILE" ]; then
       DETECTED_CODE=$(grep -A 5 "+code" "$LOGFILE" | grep -oE "[~]?[a-z]{6}-[a-z]{6}-[a-z]{6}-[a-z]{6}" | grep -v "~" | tail -1)
       
       if [ ! -z "$DETECTED_CODE" ]; then
           CODE_FOUND="$DETECTED_CODE"
           break
       fi
   fi
   sleep 1
   ((CODE_COUNTER++))
done

if [ ! -z "$CODE_FOUND" ]; then
   echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
   echo -e "${GREEN}${BOLD}✓ LOGIN CODE: ${YELLOW}${BOLD}$CODE_FOUND${NC}"
   echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
      if [ "$OS" = "Darwin" ]; then
       echo -n "$CODE_FOUND" | pbcopy  # <-- ADD THIS LINE BACK
       echo -e "${CYAN}(Copied to macOS clipboard)${NC}"
   elif command -v xclip &> /dev/null; then
       echo -n "$CODE_FOUND" | xclip -selection clipboard
       echo -e "${CYAN}(Copied to Linux clipboard)${NC}"
   fi
else
   script_msg "Could not retrieve code automatically."
fi

echo ""
script_msg "Opening Browser..."
sleep 2
$OPEN_CMD "$URL_FOUND"

# ----------------------------------------------
# PHASE 4: Interactive Monitor (Resume)
# ----------------------------------------------

# Restart monitor with error suppression
tail -f "$LOGFILE" 2>/dev/null | grep --line-buffered -E "$FILTER_PATTERN" | format_log &
TAIL_PID=$!
trap "kill $TAIL_PID 2>/dev/null" EXIT

echo -e "\n${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Urbit is running in background session '$SESSION_NAME'.${NC}"
echo -e "${DIM}Showing live logs below (mdns registration, etc)...${NC}"
echo -e "${CYAN}Press 'q' to quit this script (Urbit keeps running).${NC}"
echo -e "${RED}Press 'x' to kill Urbit and exit.${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}\n"

while true; do
    read -n 1 -s -r -p "" INPUT < /dev/tty
    if [[ "$INPUT" == "q" ]]; then
        echo ""
        script_msg "Exiting monitor."
        disown $TAIL_PID
        kill $TAIL_PID 2>/dev/null
        break
    elif [[ "$INPUT" == "x" ]]; then
        echo ""
        script_msg "Killing Urbit session..."
        disown $TAIL_PID
        kill $TAIL_PID 2>/dev/null
        screen -S "$SESSION_NAME" -X quit
        script_msg "Done."
        break
    fi
done
