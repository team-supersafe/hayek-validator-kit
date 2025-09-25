#!/bin/bash
# Welcome Setup Script for Molecule Test Runner
# This script configures the interactive welcome message and environment
# Usage: setup-welcome.sh [scenario] [project_dir] [config_dir]
set -euo pipefail

# Default values
PROJECT_DIR="${2:-/hayek-validator-kit}"
CONFIG_DIR="${3:-/new-metal-box}"
DEFAULT_SCENARIO="${1:-iam_manager_tests}"

echo "Setting up welcome environment for scenario: $DEFAULT_SCENARIO"

# Create the help function
cat >> ~/.bashrc << 'EOF'

# ============================================================================
# SCENARIO CONFIGURATION DATABASE
# ============================================================================
# To add a new scenario, just add a new numbered block:
# SCENARIO_[N]_NAME="folder-name-in-molecule"
# SCENARIO_[N]_PARAMS="parameters for commands that need them"
# SCENARIO_[N]_COMMANDS="comma-separated list of commands that need params"
# SCENARIO_[N]_DESCRIPTION="Description for help text"
#
# IMPORTANT - SCENARIO_[N]_COMMANDS Explanation:
# This defines WHICH molecule commands need the special parameters.
# - If command is in the list AND params exist → Add parameters
# - If command is NOT in the list → Run without parameters
# - If COMMANDS is empty → ALL commands run without parameters
#
# Example:
# SCENARIO_1_COMMANDS="test,converge,idempotence"
# Result:
#   molecule test -s rbac-tests → WITH params (test is in list)
#   molecule verify -s rbac-tests → WITHOUT params (verify not in list)
#   molecule login -s rbac-tests → WITHOUT params (login not in list)
#
# Common patterns:
# - "test,converge,idempotence" → Setup/testing commands need params
# - "test,converge" → Only initial setup needs params
# - "" → Simple scenario, no special params needed

# Scenario 1: IAM Manager Tests
SCENARIO_1_NAME="iam_manager_tests"
SCENARIO_1_PARAMS="-- -e csv_file=iam_setup.csv"
SCENARIO_1_COMMANDS="test,converge,idempotence"
SCENARIO_1_DESCRIPTION="IAM Manager Testing with CSV configuration"

# Scenario 2: Host Architecture Tests
SCENARIO_2_NAME="host-arch-tests"
SCENARIO_2_PARAMS=""
SCENARIO_2_COMMANDS=""
SCENARIO_2_DESCRIPTION="Host architecture compatibility testing"

# Scenario 3: Performance Tests (example - add when needed)
# SCENARIO_3_NAME="performance-tests"
# SCENARIO_3_PARAMS="-- -e duration=300 -e load_users=100"
# SCENARIO_3_COMMANDS="test,converge"
# SCENARIO_3_DESCRIPTION="Performance and load testing suite"

# Scenario 4: Security Tests (example - add when needed)
# SCENARIO_4_NAME="security-tests"
# SCENARIO_4_PARAMS="-- -e security_level=strict -e scan_depth=full"
# SCENARIO_4_COMMANDS="test,converge,idempotence"
# SCENARIO_4_DESCRIPTION="Security vulnerability scanning and testing"

# ============================================================================

# Function to get scenario parameters by scenario name
get_scenario_params() {
    local scenario_name="$1"
    local command_type="$2"

    # Find the scenario number by iterating through configured scenarios
    local i=1
    while true; do
        local name_var="SCENARIO_${i}_NAME"
        local configured_name="${!name_var:-}"

        # If no more scenarios configured, break
        if [[ -z "$configured_name" ]]; then
            break
        fi

        # If we found the matching scenario
        if [[ "$configured_name" == "$scenario_name" ]]; then
            local params_var="SCENARIO_${i}_PARAMS"
            local commands_var="SCENARIO_${i}_COMMANDS"

            local params="${!params_var:-}"
            local commands="${!commands_var:-}"

            # Check if this command type needs parameters
            if [[ -n "$commands" && ",$commands," =~ ,"$command_type", ]]; then
                echo "$params"
                return
            else
                echo ""
                return
            fi
        fi

        ((i++))
    done

    # Scenario not found in configuration, return empty
    echo ""
}

# Function to get scenario description by scenario name
get_scenario_description() {
    local scenario_name="$1"

    # Find the scenario number by iterating through configured scenarios
    local i=1
    while true; do
        local name_var="SCENARIO_${i}_NAME"
        local configured_name="${!name_var:-}"

        # If no more scenarios configured, break
        if [[ -z "$configured_name" ]]; then
            break
        fi

        # If we found the matching scenario
        if [[ "$configured_name" == "$scenario_name" ]]; then
            local desc_var="SCENARIO_${i}_DESCRIPTION"
            echo "${!desc_var:-No description available}"
            return
        fi

        ((i++))
    done

    # Scenario not found in configuration
    echo "No description available"
}

# Welcome message for test-runner
show_test_help() {
    local scenario="${MOLECULE_SCENARIO:-iam_manager_tests}"
    local project_dir="${PROJECT_DIR:-/hayek-validator-kit}"
    local config_dir="${CONFIG_DIR:-/new-metal-box}"

    echo -e "\n\033[1;36m=========================================="
    echo -e "🧪 HAYEK VALIDATOR KIT - TEST RUNNER"
    echo -e "==========================================\033[0m"
    echo -e "\n\033[1;32m📋 Available Test Commands:\033[0m"
    echo -e "\n\033[1;33m🔐 Current Scenario: $scenario\033[0m"

    # Add CSV parameter only for iam_manager_tests scenario
    local csv_param=""
    if [ "$scenario" = "iam_manager_tests" ]; then
        csv_param=" -- -e csv_file=iam_setup.csv"
    fi

    echo -e "  \033[1;32m# Full test suite:\033[0m"
    echo -e "  molecule test -s $scenario$csv_param"
    echo -e "  \033[1;90m  → Runs complete suite: converge + verify + destroy\033[0m"
    echo -e ""
    echo -e "  \033[1;32m# Initial setup (configuration only):\033[0m"
    echo -e "  molecule converge -s $scenario$csv_param"
    echo -e "  \033[1;90m  → Creates container and applies configuration\033[0m"
    echo -e ""
    echo -e "  \033[1;32m# Idempotency test:\033[0m"
    echo -e "  molecule idempotence -s $scenario$csv_param"
    echo -e "  \033[1;90m  → Verifies that changes are idempotent\033[0m"
    echo -e ""
    echo -e "  \033[1;32m# Verification on active container:\033[0m"
    echo -e "  molecule verify -s $scenario       # Run verification tests only"
    echo -e "  \033[1;90m  → Runs tests without recreating container\033[0m"
    echo -e ""
    echo -e "  \033[1;32m# Direct container access:\033[0m"
    echo -e "  molecule login -s $scenario        # Access testing container"
    echo -e "  \033[1;90m  → For manual debugging and exploration\033[0m"
    echo -e ""
    echo -e "  \033[1;32m# Cleanup:\033[0m"
    echo -e "  molecule destroy -s $scenario      # Remove testing containers"
    echo -e "\n\033[1;33m🎯 Other Available Scenarios:\033[0m"

    # Dynamically list available scenarios
    if [ -d "$project_dir/ansible-tests/molecule" ]; then
        for scenario_dir in "$project_dir/ansible-tests/molecule"/*; do
            if [ -d "$scenario_dir" ]; then
                local scenario_name=$(basename "$scenario_dir")
                if [ "$scenario_name" != "$scenario" ]; then
                    echo -e "  molecule test -s $scenario_name"
                fi
            fi
        done
    fi

    echo -e "\n\033[1;33m📁 Important Paths:\033[0m"
    echo -e "  $project_dir/            # Main project directory"
    echo -e "  $config_dir/             # CSV configuration files"
    echo -e "  $project_dir/ansible-tests/molecule/  # All test scenarios"
    echo -e "\n\033[1;32m💡 Quick Tips:\033[0m"
    echo -e "  • Use 'help' to show this message again"
    echo -e "  • Use 'scenarios' to list all available test scenarios"
    echo -e "  • Use 'select' for interactive scenario selection"
    echo -e "  • Use 'run' for interactive test execution"
    echo -e "\n\033[1;33m🎯 Quick Interactive Commands:\033[0m"
    echo -e "  select                    # Interactive scenario picker"
    echo -e "  run                       # Interactive test runner"
    echo -e "\n\033[1;36m==========================================\033[0m\n"
}

# Function to list available scenarios
list_scenarios() {
    local project_dir="${PROJECT_DIR:-/hayek-validator-kit}"
    echo -e "\n\033[1;33m📋 Available Test Scenarios:\033[0m"

    if [ -d "$project_dir/ansible-tests/molecule" ]; then
        for scenario_dir in "$project_dir/ansible-tests/molecule"/*; do
            if [ -d "$scenario_dir" ]; then
                local scenario_name=$(basename "$scenario_dir")
                local current_marker=""
                if [ "$scenario_name" = "${MOLECULE_SCENARIO:-iam_manager_tests}" ]; then
                    current_marker=" \033[1;32m← current\033[0m"
                fi
                                echo -e "  \033[1;36m$scenario_name\033[0m$current_marker"

                # Get description from configuration variables
                local description=$(get_scenario_description "$scenario_name")
                if [ -n "$description" ] && [ "$description" != "No description available" ]; then
                    echo -e "    \033[1;90m$description\033[0m"
                fi
            fi
        done
    else
        echo -e "  \033[1;31mNo scenarios found in $project_dir/ansible-tests/molecule/\033[0m"
    fi
    echo ""
}

# Function to interactively select a scenario using bash select
select_scenario() {
    local project_dir="${PROJECT_DIR:-/hayek-validator-kit}"
    local scenarios=()

    echo -e "\n\033[1;33m📋 Available Test Scenarios:\033[0m"

    # Collect scenarios
    if [ -d "$project_dir/ansible-tests/molecule" ]; then
        for scenario_dir in "$project_dir/ansible-tests/molecule"/*; do
            if [ -d "$scenario_dir" ]; then
                local scenario_name=$(basename "$scenario_dir")
                scenarios+=("$scenario_name")
            fi
        done
    fi

    if [ ${#scenarios[@]} -eq 0 ]; then
        echo -e "  \033[1;31mNo scenarios found!\033[0m"
        return 1
    fi

    # Use bash select for interactive choice
    echo -e "\nSelect a scenario:"
    select scenario in "${scenarios[@]}" "Cancel"; do
        case $scenario in
            "Cancel")
                echo -e "\033[1;90mSelection cancelled.\033[0m"
                return 0
                ;;
            "")
                echo -e "\033[1;31mInvalid selection. Please try again.\033[0m"
                ;;
            *)
                export MOLECULE_SCENARIO="$scenario"

                # Update .bashrc for persistence
                if grep -q "export MOLECULE_SCENARIO=" ~/.bashrc; then
                    sed -i "s/export MOLECULE_SCENARIO=.*/export MOLECULE_SCENARIO=\"$scenario\"/" ~/.bashrc
                else
                    echo "export MOLECULE_SCENARIO=\"$scenario\"" >> ~/.bashrc
                fi

                echo -e "\n\033[1;32m✅ Scenario changed to: $scenario\033[0m"
                echo -e "\033[1;90mRun 'help' to see updated commands for this scenario.\033[0m\n"
                return 0
                ;;
        esac
    done
}

# Function to interactively run tests
run_test() {
    local scenario="${MOLECULE_SCENARIO:-}"
    local project_dir="${PROJECT_DIR:-/hayek-validator-kit}"

    # Step 1: Ensure we have a scenario selected
    if [ -z "$scenario" ]; then
        echo -e "\n\033[1;33m📋 No scenario selected. Please choose one first:\033[0m"
        select_scenario || return 1
        scenario="${MOLECULE_SCENARIO}"
    fi

    # Step 2: Show current scenario and test options
    echo -e "\n\033[1;32m🎯 Current Scenario: \033[1;36m$scenario\033[0m"
    echo -e "\n\033[1;33m📋 Select test to run:\033[0m"

    # Define test options
    local options=(
        "Full test suite (test)"
        "Setup only (converge)"
        "Verify only (verify)"
        "Idempotency test (idempotence)"
        "Container access (login)"
        "Cleanup (destroy)"
        "Cancel"
    )

    # Step 3: Interactive selection
    select choice in "${options[@]}"; do
        local cmd=""
        local params=""

        case $REPLY in
            1)
                cmd="molecule test -s $scenario"
                params=$(get_scenario_params "$scenario" "test")
                ;;
            2)
                cmd="molecule converge -s $scenario"
                params=$(get_scenario_params "$scenario" "converge")
                ;;
            3)
                cmd="molecule verify -s $scenario"
                params=$(get_scenario_params "$scenario" "verify")
                ;;
            4)
                cmd="molecule idempotence -s $scenario"
                params=$(get_scenario_params "$scenario" "idempotence")
                ;;
            5)
                cmd="molecule login -s $scenario"
                params=$(get_scenario_params "$scenario" "login")
                ;;
            6)
                cmd="molecule destroy -s $scenario"
                params=$(get_scenario_params "$scenario" "destroy")
                ;;
            7)
                echo -e "\033[1;90mOperation cancelled.\033[0m"
                return 0
                ;;
            *)
                echo -e "\033[1;31mInvalid selection. Please try again.\033[0m"
                continue
                ;;
        esac

        # Add parameters if they exist
        if [ -n "$params" ]; then
            cmd="$cmd $params"
        fi

        # Step 4: Confirm and execute
        echo -e "\n\033[1;32m🚀 About to execute:\033[0m"
        echo -e "  \033[1;36m$cmd\033[0m"
        echo -e "\nProceed? [Y/n]: "
        read -r confirm

        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            echo -e "\033[1;90mExecution cancelled.\033[0m"
            return 0
        fi

        echo -e "\n\033[1;32m▶️  Executing: $cmd\033[0m\n"
        eval "$cmd"
        return $?
    done
}

EOF

# Add environment variables
cat >> ~/.bashrc << EOF
# Environment configuration
export MOLECULE_SCENARIO="$DEFAULT_SCENARIO"
export PROJECT_DIR="$PROJECT_DIR"
export CONFIG_DIR="$CONFIG_DIR"

EOF

# Add aliases
cat >> ~/.bashrc << 'EOF'
# Convenient aliases
alias help="show_test_help"
alias scenarios="list_scenarios"
alias h="help"
alias s="scenarios"
alias select="select_scenario"
alias run="run_test"

# Molecule shortcuts
alias mt="molecule test"
alias mc="molecule converge"
alias mv="molecule verify"
alias mi="molecule idempotence"
alias ml="molecule login"
alias md="molecule destroy"

EOF

# Add auto-navigation and welcome
cat >> ~/.bashrc << EOF
# Auto-navigate to tests directory
cd $PROJECT_DIR/ansible-tests/ 2>/dev/null || echo "Warning: Molecule tests directory not found"

# Show welcome message on login (only for interactive shells)
if [[ \$- == *i* ]]; then
    show_test_help
fi
EOF

echo "✅ Welcome environment configured successfully!"
echo "   Default scenario: $DEFAULT_SCENARIO"
echo "   Project directory: $PROJECT_DIR"
echo "   Config directory: $CONFIG_DIR"