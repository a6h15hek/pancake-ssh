#!/bin/bash

# Check if pancake is installed
if ! command -v pancake &> /dev/null
then
    echo "❌ pancake is not installed."
    exit 0
fi

echo "🚀 Starting the uninstallation process..."

# Get the absolute path of pancake
PANCAKE_PATH=$(which pancake)

echo "🔍 Checking if pancake exists..."
# Check if pancake exists
if [ ! -f "$PANCAKE_PATH" ]; then
    echo "❌ Error: pancake does not exist."
    exit 1
fi

echo "✅ Found pancake."

echo "🔧 Removing pancake..."
# Remove pancake
rm "$PANCAKE_PATH"
echo "✅ pancake has been removed."

echo "📂 Removing pancake from the PATH..."
# Remove the directory of pancake from the PATH in the appropriate profile file
PROFILE_FILE=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    PROFILE_FILE=~/.bashrc
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    PROFILE_FILE=~/.zshrc
elif [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win32"* ]]; then
    # Windows
    PROFILE_FILE=~/.bash_profile
else
    echo "❌ This OS is not supported."
    exit 1
fi

# Use grep to check if the PATH update for pancake exists in the PROFILE_FILE
if grep -q "export PATH=\\$PATH:$(dirname "$PANCAKE_PATH")" "$PROFILE_FILE"; then
    # If it exists, use sed to remove it
    sed -i "" "/export PATH=\\\$PATH:$(dirname "$PANCAKE_PATH")/d" "$PROFILE_FILE"
fi

source "$PROFILE_FILE"

# Check if pancake is uninstalled
if ! command -v pancake &> /dev/null
then
    echo "✅ pancake has been removed from the PATH and can no longer be accessed with the command 'pancake'."
    echo "🎉 Uninstallation completed successfully!"
else
    echo "❌ Failed to uninstall pancake."
fi
