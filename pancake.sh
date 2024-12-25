#!/bin/bash

# Use the directory to access pancake.yml
config_file="$(dirname "$0")/pancake.yml"

create_directories() {
    project=$1
    project_location=$(yq e '.project_location' $config_file)
    config_base="$project_location/pancake_config/$project"

    # Create directories if they do not exist
    for location in "$config_base/logs" "$config_base/secrets" "$config_base/override"; do
        if [ ! -d "$location" ]; then
            mkdir -p "$location"
            echo "Created directory: $location"
        fi
    done
}

project_list() {
    echo "📚 Project list:"
    printf "| %-10s | %-10s | %-20s | %-25s | %-30s |\n" "Name" "Branch" "Last Committer" "Version" "Last Updated"
    echo "|------------|------------|----------------------|---------------------------|--------------------------------|"
    # Parse $config_file and list each project
    project_location=$(yq e '.project_location' $config_file)
    for project in $(yq e '.projects | keys | .[]' $config_file); do
        # Get the last updated date-time of the project
        project_folder="$project_location/$project"
        if [ -d "$project_folder" ]; then
            last_updated=$(git -C "$project_folder" log -1 --format="%cd")
            current_branch=$(git -C "$project_folder" rev-parse --abbrev-ref HEAD)
            last_committer=$(git -C "$project_folder" log -1 --format='%an')
            version=$(git -C "$project_folder" describe --tags --always)
            printf "| %-10s | %-10s | %-20s | %-25s | %-30s |\n" "$project" "$current_branch" "$last_committer" "$version" "$last_updated"
        else
            printf "| %-10s | %-10s | %-20s | %-25s | %-30s |\n" "$project" "-" "-" "-" "-"
        fi
    done
}

project_sync() {
    echo "🔄 : Syncing projects... "
    # Parse $config_file and clone/update each project
    project_location=$(yq e '.project_location' $config_file)
    mkdir -p $project_location
    for project in $(yq e '.projects | keys | .[]' $config_file); do
        project_sync_single "$project"
    done
    echo "✅ All projects synced."
}

project_sync_single() {
    project=$1
    if [ -z "$(yq e ".projects.$project" $config_file)" ]; then
        echo "❌ Error: Project '$project' not found in config file."
        return 1
    fi
    if [ -z "$(yq e ".projects.$project.github_link" $config_file)" ]; then
        echo "❌ Error: GitHub link for project '$project' not found in config file."
        return 1
    fi
    echo "🔄 $(yq e ".projects.$project.github_link" $config_file): Syncing $project..."
    create_directories $project
    # Parse $config_file and clone/update the project
    project_location=$(yq e '.project_location' $config_file)
    project_folder="$project_location/$project"
    mkdir -p $project_folder
    git -C "$project_folder" pull || git clone "$(yq e ".projects.$project.github_link" $config_file)" "$project_folder"
    echo "✅ $project synced."
}


build_project() {
    project=$1
    echo "🔨 Building $project..."
    # Parse $config_file and get the build command for the project
    project_location=$(yq e '.project_location' $config_file)
    project_folder="$project_location/$project"
    build_command=$(yq e ".projects.$project.build" $config_file)
    if [ "$build_command" != "null" ]; then
        if [ -d "$project_folder" ]; then
            echo "Running in subshell: cd $project_folder && $build_command"
            (cd "$project_folder" && $build_command)
            echo "✅ $project built successfully."
        else
            echo "❌ The project directory does not exist."
        fi
    else
        echo "❌ Build variable not exists. Cannot build the project."
    fi
}

run_project() {
    project=$1
    # Parse $config_file and get the type of the project
    project_type=$(yq e ".projects.$project.type" $config_file)
    if [ "$project_type" = "web" ]; then
        run_project_web $project
        return
    fi

    # Check if the process is already running
    pid=$(jps -l | grep "$project" | awk '{print $1}')
    if [ -n "$pid" ]; then
        echo "⚠️ $project is already running with PID $pid."
        return
    fi
    echo "🏃 Running $project..."
    # Parse $config_file and get the run command for the project
    run_command=$(yq e ".projects.$project.run" $config_file)
    project_location=$(yq e '.project_location' $config_file)
    project_folder="$project_location/$project"
    if [ "$run_command" != "null" ]; then
        # Replace all occurrences of @@variable@ with the value of the variable
        for variable in $(yq e 'keys | .[]' $config_file); do
            value=$(yq e ".$variable" $config_file)
            run_command=${run_command//@$variable@/$value}
        done
        # Replace <project_name> with the actual project name
        run_command=${run_command//<project_name>/$project}
        echo "Running: $run_command"
        nohup $run_command > "$project_folder/pancake_config/$project/start.log" 2>&1 &
        echo "✅ $project run successfully. Logs are saved in $logs_location/$project/start.log."
    else
        echo "❌ Run variable not exists. Cannot run the project."
    fi
}

run_project_web() {
    project=$1
    # Check if the process is already running
    port=$(yq e ".projects.$project.port" $config_file)
    if command -v lsof &> /dev/null; then
        pid=$(lsof -t -i:$port)
    else
        pid=$(netstat -ano | awk -v port="$port" 'BEGIN{FS=" "}{split($2,a,":"); if (a[2] == port) print $5}' | head -n 1)
    fi
    if [ -n "$pid" ]; then
        echo "⚠️ $project is already running with PID $pid."
        return
    fi
    echo "🏃 Running Web $project..."
    # Parse $config_file and get the run command for the project
    run_command=$(yq e ".projects.$project.run" $config_file)
    logs_location=$(yq e '.logs_location' $config_file)
    project_location=$(yq e '.project_location' $config_file)
    project_folder="$project_location/$project"
    if [ "$run_command" != "null" ]; then
        # Replace all occurrences of @@variable@ with the value of the variable
        for variable in $(yq e 'keys | .[]' $config_file); do
            value=$(yq e ".$variable" $config_file)
            run_command=${run_command//@$variable@/$value}
        done
        # Replace <project_name> with the actual project name
        run_command=${run_command//<project_name>/$project}
        # # Add the PORT environment variable to the run command
        # if [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win32"* ]]; then
        #     # Windows
        #     run_command="set PORT=$port && $run_command"
        # else
        #     # Linux or Mac OSX
        #     run_command="PORT=$port $run_command"
        # fi
        echo "Running in subshell: cd $project_folder && $run_command"
        (cd "$project_folder" && nohup $run_command > "$project_folder/pancake_config/$project/start.log" 2>&1 &)
        echo "✅ $project run successfully. Logs are saved in $project_folder/pancake_config/$project/start.log."
    else
        echo "❌ Run variable not exists. Cannot run the project."
    fi
}

stop_process() {
    project=$1
    echo "🛑 Stopping $project..."

    # Parse $config_file and get the type of the project
    project_type=$(yq e ".projects.$project.type" $config_file)
    if [ "$project_type" = "web" ]; then
        stop_process_web $project
        return
    fi

    # Check the operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        # Linux or Mac OSX
        pid=$(jps -l | grep "$project" | awk '{print $1}')
        if [ -n "$pid" ]; then
            kill -9 $pid
            echo "✅ $project stopped successfully."
        else
            echo "❌ $project is not running."
        fi
    elif [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win32"* ]]; then
        # Windows
        pid=$(jps -l | findstr "$project" | awk '{print $1}')
        if [ -n "$pid" ]; then
            taskkill //PID $pid //F
            echo "✅ $project stopped successfully."
        else
            echo "❌ $project is not running."
        fi
    else
        echo "❌ This OS is not supported."
    fi
}

stop_process_web() {
    project=$1
    port=$(yq e ".projects.$project.port" $config_file)
    echo "🛑 Stopping $project with port: $port..."
    # Check the operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        # Linux or Mac OSX
        pid=$(lsof -t -i:$port)
        if [ -n "$pid" ]; then
            kill -9 $pid
            echo "✅ $project stopped successfully."
        else
            echo "❌ $project is not running."
        fi
    elif [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win32"* ]]; then
        # Windows
        pid=$(netstat -ano | awk -v port="$port" 'BEGIN{FS=" "}{split($2,a,":"); if (a[2] == port) print $5}' | head -n 1)
        if [ -n "$pid" ]; then
            taskkill //PID $pid //F
            echo "✅ $project stopped successfully."
        else
            echo "❌ $project is not running."
        fi
    else
        echo "❌ This OS is not supported."
    fi
}

edit_config() {
    SUCCESS_MSG="✅ $config_file opened successfully."
    FAIL_MSG="❌ Failed to open $config_file."
    UNSUPPORTED_OS_MSG="❌ This OS is not supported."

    echo "🔧 Opening $config_file in the default editor..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        xdg-open $config_file && echo $SUCCESS_MSG || echo $FAIL_MSG
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        open $config_file && echo $SUCCESS_MSG || echo $FAIL_MSG
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        start $config_file && echo $SUCCESS_MSG || echo $FAIL_MSG
    else
        echo $UNSUPPORTED_OS_MSG
        exit 1
    fi
}


help_menu() {
    echo "📖 Pancake Project Management Tool 📖"
    echo "Pancake is a versatile tool designed to streamline your project management workflow. It simplifies running web and server modules, monitors application status, and offers customizable project locations and override files. Best of all, you can run and open projects from anywhere!"
    echo ""
    echo "🌟 Features:"
    echo "1. Simplifies running web and server modules."
    echo "2. Monitors all running and non-running applications."
    echo "3. Customizable project locations and override files."
    echo "4. Runs and opens projects from anywhere."
    echo ""
    commands=(
        "pancake project list"
        "pancake project sync"
        "pancake project sync <project_name>"
        "pancake project build <project_name>"
        "pancake project run <project_name>"
        "pancake project stop <project_name>"
        "pancake status"
        "pancake config edit"
        "pancake open <project_name>"
    )
    descriptions=(
        "List all projects defined in the pancake.yml file."
        "Sync all projects. This clones or pulls the latest changes from the repositories."
        "Sync the specified project. This clones or pulls the latest changes from the repository of the specified project."
        "Build the specified project. This runs the build command defined in the pancake.yml file for the specified project."
        "Run the specified project. This runs the command defined in the run variable in the pancake.yml file for the specified project."
        "Stop the specified project. This stops the process running the specified project."
        "Check the status of all projects. This prints the status, PID, and start time of the process for each project."
        "Open the pancake.yml file in the default editor."
        "Open the specified project with the command mentioned in code_editor_command."
    )
    printf "| %-35s | %-127s |\n" "Command " "Description"
    printf "|%s|%s|\n" "-------------------------------------" "---------------------------------------------------------------------------------------------------------------------------------"
    for i in "${!commands[@]}"; do
        printf "| %-35s | %-127s |\n" "${commands[$i]}" "${descriptions[$i]}"
    done
    echo ""
    echo "💡 Usage:"
    echo "pancake [command]"
    echo ""
    echo "👨‍💻 Developer: Yadav, Abhishek - http://github.com/a6h15hek"
    echo ""
    echo "Please replace <project_name> with the name of your project."
}

open_project() {
    project=$1
    # Parse $config_file and get the code editor command and project location
    code_editor_command=$(yq e '.code_editor_command' $config_file)
    project_location=$(yq e '.project_location' $config_file)

    if [ -z "$project" ]; then
        echo "📂 No project specified. Running default command..."
        command_to_run="$code_editor_command"
    else
        echo "📂 Opening $project..."
        command_to_run="$code_editor_command $project_location/$project"
    fi

    echo "🔨 Running command: $command_to_run"
    # Open the project with the code editor command
    if $command_to_run ; then
        echo "✅ Command executed successfully."
    else
        echo "❌ Error: Failed to execute command."
    fi
}


if [ "$#" -eq 0 ]; then
    help_menu
    exit 0
elif [ "$1" = "project" ]; then
    if [ "$2" = "list" ]; then
        project_list
    elif [ "$2" = "sync" ]; then
        if [ -n "$3" ]; then
            project_sync_single $3
        else
            project_sync
        fi
    elif [ "$2" = "build" ]; then
        if [ -n "$3" ]; then
            build_project $3
        else
            echo "⚠️ No third argument provided for build"
            exit 1
        fi
    elif [ "$2" = "run" ]; then
        if [ -n "$3" ]; then
            run_project $3
        else
            echo "⚠️ No third argument provided for run"
            exit 1
        fi
    elif [ "$2" = "stop" ]; then
        if [ -n "$3" ]; then
            stop_process $3
        else
            echo "⚠️ No third argument provided for stop"
            exit 1
        fi
    elif [ "$2" = "status" ]; then
        status_project
    elif [ "$2" = "open" ]; then
        open_project $3
    else
        echo "❌ Invalid second argument for project: $2"
        exit 1
    fi
elif [ "$1" = "config" ]; then
    if [ "$2" = "edit" ]; then
        edit_config
    else
        echo "❌ Invalid second argument for config: $2"
        exit 1
    fi
else
    echo "❌ Invalid command: $1"
    exit 1
fi
