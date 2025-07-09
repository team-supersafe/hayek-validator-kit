#!/bin/bash

set -euo pipefail

# schedule_set_hot_spare_identity.sh
#
# This script schedules a validator set-identity operation at a specified UTC date and time.
# The intention is to switch the validator's identity to a non-voting (hot spare) identity,
# placing the main identity in a delinquent state, typically for a planned cluster halt.
#
# Usage:
#   ~/bin/schedule_set_hot_spare_identity.sh "<validator_name>" "<UTC date and time>"
#
# Example:
#   ~/bin/schedule_set_hot_spare_identity.sh "hayek-testnet" "15:00 UTC 2025-07-02"
#   ~/bin/schedule_set_hot_spare_identity.sh "hayek-mainnet" "15:00 UTC 2025-07-02"
#
# The date and time format must be compatible with the 'at' command (see 'man at').

# Configuration
LOG_FILE="$HOME/logs/schedule_set_hot_spare_identity.log"
OUTPUT_FILE="$HOME/logs/set-identity.log"
SOLANA_INSTALL_DIR="$HOME/.local/share/solana/install"
KEYS_BASE_DIR="$HOME/keys"
LEDGER_PATH="/mnt/ledger"

# Ensure log output directory exists early
touch "$LOG_FILE" "$OUTPUT_FILE"
chmod 600 "$LOG_FILE" "$OUTPUT_FILE"

# Log function for consistent logging
log_message() {
    local level
    level="$1"
    local message
    message="$2"
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] [$level] $message" | tee -a "$LOG_FILE"
}

# Trap signals for graceful shutdown and logging
trap 'log_message "INFO" "Script interrupted by signal"; exit 130' INT TERM

# Input validation function
validate_validator_name() {
    local name
    name="$1"
    # Only allow alphanumeric characters, hyphens, and underscores
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_message "ERROR" "Invalid validator name: '$name'. Only alphanumeric characters, hyphens, and underscores are allowed."
        return 1
    fi
    # Prevent directory traversal attempts
    if [[ "$name" == *".."* ]] || [[ "$name" == *"/"* ]] || [[ "$name" == *"\\"* ]]; then
        log_message "ERROR" "Invalid validator name: '$name'. Directory traversal characters are not allowed."
        return 1
    fi
    return 0
}

# Validate date/time format and ensure it's in the future
validate_datetime() {
    local datetime
    datetime="$1"

    # Schedule a test job and get the job ID in one step
    job_output=$(echo "echo 'test'" | at "$datetime" 2>&1)
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Invalid date/time format: '$datetime'. Please use format compatible with 'at' command."
        return 1
    fi

    # Extract job ID and remove the test job
    job_id=$(echo "$job_output" | awk '/job/ {print $2}')
    if [[ -n "$job_id" ]]; then
        atrm "$job_id" 2>/dev/null || true
    fi

    # Check if the scheduled time is in the future
    local scheduled_timestamp
    scheduled_timestamp=$(date -d "$datetime" +%s 2>/dev/null || echo "0")
    local current_timestamp
    current_timestamp=$(date +%s)

    if [ "$scheduled_timestamp" -le "$current_timestamp" ]; then
        log_message "ERROR" "Scheduled time '$datetime' is in the past or present. Please specify a future time."
        return 1
    fi

    # Log the time difference for verification
    local time_diff
    time_diff=$((scheduled_timestamp - current_timestamp))
    local hours
    hours=$((time_diff / 3600))
    local minutes
    minutes=$(((time_diff % 3600) / 60))
    log_message "INFO" "Job scheduled for $hours hours and $minutes minutes from now"

    return 0
}

# Check if we're running as the correct user
check_user() {
    if [ "$(whoami)" != "sol" ] && [ "$(whoami)" != "root" ]; then
        log_message "ERROR" "This script must be run as 'sol' or 'root' user. Current user: $(whoami)"
        exit 1
    fi
}

# Main script logic
main() {
    log_message "INFO" "Starting schedule_set_hot_spare_identity.sh"

    # Check user permissions
    check_user

    # Validate input parameters
    if [ -z "${1:-}" ]; then
        log_message "ERROR" "No validator name provided."
        echo "Usage: $0 \"<validator_name>\" \"<UTC date and time>\"" | tee -a "$LOG_FILE"
        echo "Example: $0 \"hayek-testnet\" \"15:00 UTC 2025-07-02\"" | tee -a "$LOG_FILE"
        echo "Example: $0 \"hayek-mainnet\" \"15:00 UTC 2025-07-02\"" | tee -a "$LOG_FILE"
        exit 1
    fi

    if [ -z "${2:-}" ]; then
        log_message "ERROR" "No date/time provided."
        echo "Usage: $0 \"<validator_name>\" \"<UTC date and time>\"" | tee -a "$LOG_FILE"
        echo "Example: $0 \"hayek-testnet\" \"15:00 UTC 2025-07-02\"" | tee -a "$LOG_FILE"
        echo "Example: $0 \"hayek-mainnet\" \"15:00 UTC 2025-07-02\"" | tee -a "$LOG_FILE"
        exit 1
    fi

    VALIDATOR_NAME="$1"
    SCHEDULED_TIME="$2"

    # Validate validator name
    if ! validate_validator_name "$VALIDATOR_NAME"; then
        exit 1
    fi

    # Validate date/time format
    if ! validate_datetime "$SCHEDULED_TIME"; then
        exit 1
    fi

    # Construct paths safely
    VALIDATOR_KEYS_DIR="$KEYS_BASE_DIR/$VALIDATOR_NAME"
    IDENTITY_FILE="$VALIDATOR_KEYS_DIR/hot-spare-identity.json"

    log_message "INFO" "Validator: $VALIDATOR_NAME"
    log_message "INFO" "Scheduled time: $SCHEDULED_TIME"
    log_message "INFO" "Identity file: $IDENTITY_FILE"

    # Verify keys directory exists
    if [ ! -d "$VALIDATOR_KEYS_DIR" ]; then
        log_message "ERROR" "Validator keys directory not found: $VALIDATOR_KEYS_DIR"
        exit 1
    fi

    # Check if agave-validator exists and is executable
    AGAVE_BINARY="$SOLANA_INSTALL_DIR/active_release/bin/agave-validator"
    if [ ! -f "$AGAVE_BINARY" ] || [ ! -x "$AGAVE_BINARY" ]; then
        log_message "ERROR" "agave-validator binary not found or not executable: $AGAVE_BINARY"
        exit 2
    fi

    # Verify agave-validator works
    if ! "$AGAVE_BINARY" --version >/dev/null 2>&1; then
        log_message "ERROR" "agave-validator binary failed to execute: $AGAVE_BINARY"
        exit 2
    fi

    # Check if identity file exists and is readable
    if [ ! -f "$IDENTITY_FILE" ]; then
        log_message "ERROR" "Identity file not found: $IDENTITY_FILE"
        exit 3
    fi

    if [ ! -r "$IDENTITY_FILE" ]; then
        log_message "ERROR" "Identity file not readable: $IDENTITY_FILE"
        exit 3
    fi

    # Check ownership
    if [ "$(stat -c '%U' "$IDENTITY_FILE")" != "sol" ]; then
        log_message "WARNING" "Identity file is not owned by 'sol' user."
    fi

    # Check permissions
    if [ "$(stat -c '%a' "$IDENTITY_FILE")" -gt 600 ]; then
        log_message "WARNING" "Identity file permissions are too permissive: $(stat -c '%a' "$IDENTITY_FILE")"
    fi

    # Verify ledger path exists and is accessible
    if [ ! -d "$LEDGER_PATH" ]; then
        log_message "ERROR" "Ledger directory not found: $LEDGER_PATH"
        exit 4
    fi

    # Check if 'at' command is available
    if ! command -v at >/dev/null 2>&1; then
        log_message "ERROR" "'at' command not found. Please install the 'at' package."
        exit 5
    fi

    # Check if atd service is running
    if ! pgrep -x "atd" >/dev/null 2>&1; then
        log_message "ERROR" "atd service is not running. Please start it with: sudo systemctl start atd"
        exit 5
    fi

    # Build the scheduled script content
    SCHEDULED_SCRIPT=$(cat <<EOF
#!/bin/bash
export PATH=${SOLANA_INSTALL_DIR}/active_release/bin:$PATH
agave-validator --ledger $LEDGER_PATH set-identity $IDENTITY_FILE > $OUTPUT_FILE 2>&1
EOF
)

    # Schedule the job with better error handling
    local exit_code
    exit_code=0
    local job_output

    job_output=$(echo "$SCHEDULED_SCRIPT" | at "$SCHEDULED_TIME" 2>&1) || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Extract job ID from output for better logging
        local job_id
        job_id=$(echo "$job_output" | awk '/job/ {print $2}')
        log_message "INFO" "Validator identity switch scheduled for $VALIDATOR_NAME at: $SCHEDULED_TIME"
        if [[ -n "$job_id" ]]; then
            log_message "INFO" "Job ID: $job_id"
        fi
        log_message "INFO" "Job scheduled successfully. Use 'atq' to view pending jobs."
    else
        log_message "ERROR" "Failed to schedule validator identity switch. Exit code: $exit_code"
        log_message "ERROR" "at command output: $job_output"
        exit 6
    fi
}

# Run main function
main "$@"
