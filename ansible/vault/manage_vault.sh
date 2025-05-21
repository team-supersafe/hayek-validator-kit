#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vault file path
VAULT_FILE="group_vars/host_keys_vault.yml"
PASSWORD_FILE=".vault_pass"
KEYS_DIR="$HOME/.validator-keys"

# Function to check if vault file exists
check_vault_file() {
    if [ ! -f "$VAULT_FILE" ]; then
        echo -e "${YELLOW}Vault file not found. Creating new vault...${NC}"
        # Create a new vault file
        ansible-vault create "$VAULT_FILE"
    fi
}

# Function to view vault contents
view_vault() {
    echo -e "${YELLOW}Viewing vault contents...${NC}"
    ansible-vault view "$VAULT_FILE"
}

# Function to create password file
create_password_file() {
    echo -e "${YELLOW}Creating password file...${NC}"
    echo -e "${YELLOW}Enter the vault password:${NC}"
    read -s password
    echo "$password" > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
    echo -e "${GREEN}Password file created.${NC}"
}

# Function to remove password file
remove_password_file() {
    if [ -f "$PASSWORD_FILE" ]; then
        rm "$PASSWORD_FILE"
        echo -e "${GREEN}Password file removed.${NC}"
    else
        echo -e "${YELLOW}Password file not found.${NC}"
    fi
}

# Function to update vault with keypair files
update_vault() {
    local vault_id="$1"
    local keypair_file="jito-relayer-block-eng.json"
    local source_path="$KEYS_DIR/$vault_id/$keypair_file"

    # Check if source file exists
    if [ ! -f "$source_path" ]; then
        echo -e "${RED}Error: Keypair file not found at $source_path${NC}"
        exit 1
    }

    # Check if vault file exists
    check_vault_file

    # Create temporary file for vault content
    local temp_file=$(mktemp)

    # Get current vault content
    ansible-vault view "$VAULT_FILE" > "$temp_file" 2>/dev/null || true

    # Add or update the keypair in the vault
    local keypair_content=$(cat "$source_path" | base64)
    local yaml_key="keypair_${vault_id//-/_}"

    # Check if the key already exists in the vault
    if grep -q "^$yaml_key:" "$temp_file"; then
        # Update existing key
        sed -i.bak "s|^$yaml_key:.*|$yaml_key: $keypair_content|" "$temp_file"
    else
        # Add new key
        echo "$yaml_key: $keypair_content" >> "$temp_file"
    fi

    # Update the vault with new content
    ansible-vault encrypt --vault-id "$vault_id@$PASSWORD_FILE" "$temp_file" > "$VAULT_FILE"

    # Clean up
    rm -f "$temp_file" "${temp_file}.bak"

    echo -e "${GREEN}Successfully updated vault with keypair for $vault_id${NC}"
    echo -e "${YELLOW}IMPORTANT: Please delete the source keypair file at $source_path immediately!${NC}"
}

# Function to show help
show_help() {
    echo -e "${GREEN}Ansible Vault Management Script${NC}"
    echo "Usage: $0 [command] [vault_id]"
    echo
    echo "Commands:"
    echo "  view      - View vault contents"
    echo "  passfile  - Create a password file for non-interactive use"
    echo "  rm-pass   - Remove the password file"
    echo "  update    - Update vault with keypair files (requires vault_id)"
    echo "  help      - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 update host-alpha-canopy  # Update vault with keypair for host-alpha-canopy"
}

# Main script logic
case "$1" in
    "view")
        check_vault_file
        view_vault
        ;;
    "passfile")
        create_password_file
        ;;
    "rm-pass")
        remove_password_file
        ;;
    "update")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Vault ID is required for update command${NC}"
            show_help
            exit 1
        fi
        update_vault "$2"
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac