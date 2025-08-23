#!/bin/bash
# Welcome Setup Script for Molecule Test Runner
# This script configures the interactive welcome message and environment
# Usage: setup-welcome.sh [scenario] [project_dir] [config_dir]
set -euo pipefail

# Default values
DEFAULT_SCENARIO="${1:-rbac-tests}"
PROJECT_DIR="${2:-/hayek-validator-kit}"
CONFIG_DIR="${3:-/root/new-metal-box}"

echo "Setting up welcome environment for scenario: $DEFAULT_SCENARIO"

# Create the help function
cat >> ~/.bashrc << 'EOF'
# Welcome message for test-runner
show_test_help() {
    local scenario="${MOLECULE_SCENARIO:-rbac-tests}"
    local project_dir="${PROJECT_DIR:-/hayek-validator-kit}"
    local config_dir="${CONFIG_DIR:-/root/new-metal-box}"

    echo -e "\n\033[1;36m=========================================="
    echo -e "🧪 HAYEK VALIDATOR KIT - TEST RUNNER"
    echo -e "==========================================\033[0m"
    echo -e "\n\033[1;32m📋 Available Test Commands:\033[0m"
    echo -e "\n\033[1;33m🔐 Current Scenario: $scenario\033[0m"

    # Add CSV parameter only for rbac-tests scenario
    local csv_param=""
    if [ "$scenario" = "rbac-tests" ]; then
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
    echo -e "  molecule login -s $scenario        # SSH into testing container"
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
                if [ "$scenario_name" = "${MOLECULE_SCENARIO:-rbac-tests}" ]; then
                    current_marker=" \033[1;32m← current\033[0m"
                fi
                echo -e "  \033[1;36m$scenario_name\033[0m$current_marker"

                # Try to read scenario description from molecule.yml
                local molecule_file="$scenario_dir/molecule.yml"
                if [ -f "$molecule_file" ] && command -v yq >/dev/null 2>&1; then
                    local description=$(yq eval '.scenario.description // ""' "$molecule_file" 2>/dev/null)
                    if [ -n "$description" ]; then
                        echo -e "    \033[1;90m$description\033[0m"
                    fi
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
        "SSH access (login)"
        "Cleanup (destroy)"
        "Cancel"
    )

    # Step 3: Interactive selection
    select choice in "${options[@]}"; do
        case $REPLY in
            1)
                local cmd="molecule test -s $scenario"
                # Add CSV parameter for rbac-tests
                if [ "$scenario" = "rbac-tests" ]; then
                    cmd="$cmd -- -e csv_file=iam_setup.csv"
                fi
                ;;
            2)
                local cmd="molecule converge -s $scenario"
                if [ "$scenario" = "rbac-tests" ]; then
                    cmd="$cmd -- -e csv_file=iam_setup.csv"
                fi
                ;;
            3)
                local cmd="molecule verify -s $scenario"
                ;;
            4)
                local cmd="molecule idempotence -s $scenario"
                if [ "$scenario" = "rbac-tests" ]; then
                    cmd="$cmd -- -e csv_file=iam_setup.csv"
                fi
                ;;
            5)
                local cmd="molecule login -s $scenario"
                ;;
            6)
                local cmd="molecule destroy -s $scenario"
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
