# Pancake Project Management Tool

Pancake is a simple and easy-to-use project management tool that helps you manage multiple projects defined in a `pancake.yml` file. It can list, sync, build, run, stop, and check the status of the projects. It also allows you to open a project with a specified command.

## Installation

To install Pancake, you can use the `install.sh` script. This script will make the `pancake.sh` script executable and create a symbolic link to it, so you can use the `pancake` command from anywhere.

```bash
./install.sh
```

## Uninstallation
To uninstall Pancake, you can use the uninstall.sh script. This script will remove the symbolic link created by the install.sh script.

./uninstall.sh

## Usage
Here are the available commands:

- pancake project list: List all projects defined in the pancake.yml file.
- pancake project sync: Sync all projects defined in the pancake.yml file. This will clone or pull the latest changes from the repositories.
- pancake project sync <project_name>: Sync the specified project. This will clone or pull the latest changes from the repository of the specified project.
- pancake build <project_name>: Build the specified project. This will run the build command defined in the pancake.yml file for the specified project.
- pancake run <project_name>: Run the specified project. This will run the command defined in the run variable in the pancake.yml file for the specified project.
- pancake stop <project_name>: Stop the specified project. This will stop the process running the specified project.
- pancake status: Check the status of all projects. This will print the status, PID, and start time of the process for each project.
- pancake edit config: Open the pancake.yml file in the default editor.
- pancake open <project_name>: Open the specified project with the command mentioned in code_editor_command.
Please replace <project_name> with the name of your project.

## Thank You
Thank you for using Pancake! If you have any questions or need further assistance, feel free to ask.

