#!/bin/bash
set -e

# Create directories
mkdir -p ~/new-metal-box /tmp/molecule_keys
chmod 700 /tmp/molecule_keys

# Define users (name:role:groups)
users="alice:sysadmin:sysadmin,, bob:validator_operators:,validator_operators, hugo:validator_viewers:validator_viewers,,"

# Generate CSV header
echo "user,key,group_a,group_b,group_c" > ~/new-metal-box/iam_setup.csv

# Generate keys and CSV content
for user_data in $users; do
    IFS=':' read -r name role groups <<< "$user_data"
    
    # Generate SSH key
    ssh-keygen -t ed25519 -f /tmp/molecule_keys/${name}_key -N "" -C "${name}@molecule.test" >/dev/null 2>&1
    
    # Read public key and add to CSV
    pubkey=$(cat /tmp/molecule_keys/${name}_key.pub)
    echo "${name},${pubkey},${groups}" >> ~/new-metal-box/iam_setup.csv
done

# Validate and display results
lines=$(wc -l < ~/new-metal-box/iam_setup.csv)
[ $lines -eq 4 ] && echo "✅ CSV created: $lines lines" || { echo "❌ Wrong line count: $lines"; exit 1; }

echo "📋 CSV Preview:"
head -n3 ~/new-metal-box/iam_setup.csv
echo "🎯 Generated users: alice, bob, hugo"
