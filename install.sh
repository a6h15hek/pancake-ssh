#!/bin/bash

# Define the function to install yq
install_yq() {
    echo "🔧 Installing yq..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo wget https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        brew install yq
    else
        echo "❌ This OS is not supported. yq package not installed."
        exit 1
    fi
    echo "✅ yq installed successfully."
}

# Check if yq is already installed
if command -v yq &> /dev/null
then
    echo "✅ yq is already installed."
else
    install_yq
fi

# Check if pancake is already installed
if command -v pancake &> /dev/null
then
    echo "✅ pancake is already installed."
    exit 0
fi

echo "🚀 Starting the installation process..."

# Get the absolute path of pancake.sh
PANCAKE_PATH=$(realpath pancake.sh)

echo "🔍 Checking if pancake.sh exists..."
# Check if pancake.sh exists
if [ ! -f "$PANCAKE_PATH" ]; then
    echo "❌ Error: pancake.sh does not exist."
    exit 1
fi

echo "✅ Found pancake.sh."

echo "🔧 Making pancake.sh executable..."
# Make pancake.sh executable
chmod +x "$PANCAKE_PATH"
echo "✅ pancake.sh is now executable."

echo "📂 Adding pancake to the PATH..."
# Add the directory of pancake.sh to the PATH in the appropriate profile file
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

# Add the directory of pancake.sh to the PATH only if it doesn't already exist
if ! grep -q "$(dirname "$PANCAKE_PATH")" "$PROFILE_FILE"; then
    echo "export PATH=\$PATH:$(dirname "$PANCAKE_PATH")" >> "$PROFILE_FILE"
fi

source "$PROFILE_FILE"

# Rename pancake.sh to pancake
cp "$PANCAKE_PATH" "$(dirname "$PANCAKE_PATH")/pancake"

# Make pancake executable for all users but not readable or writable
chmod 111 "$(dirname "$PANCAKE_PATH")/pancake"


# Check if pancake is installed
if command -v pancake &> /dev/null
then
    echo "✅ pancake has been added to the PATH and can be accessed with the command 'pancake'."
    echo "🎉 Installation completed successfully! You can now run pancake from anywhere by typing 'pancake'."
else
    echo "❌ Failed to install pancake."
fi
