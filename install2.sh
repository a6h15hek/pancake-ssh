#!/bin/bash

# Check if bash is installed
if ! command -v bash &> /dev/null
then
    echo "❌ bash could not be found. Please install bash before running this script."
    exit 1
fi

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

echo "🔒 Making pancake.sh only executable..."
# Make pancake.sh only executable (not readable or writable)
chmod 111 "$PANCAKE_PATH"
echo "✅ pancake.sh is now only executable."

echo "🔗 Creating a symbolic link to pancake.sh in /usr/local/bin..."
# Create a symbolic link to pancake.sh in /usr/local/bin
ln -s "$PANCAKE_PATH" /usr/local/bin/pancake
echo "✅ Symbolic link created successfully."

echo "🎉 Installation completed successfully! You can now run pancake from anywhere by typing 'pancake'."
