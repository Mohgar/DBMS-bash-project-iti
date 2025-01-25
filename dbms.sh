#!/usr/bin/bash

# Source the script2 file using a relative path
SCRIPT_DIR=$(dirname "$0")
source "./ddl.sh"

PS3=" Type your choice number: "
dbms_dir="./dbms_dir"

# Check if the directory exists
if [[ -e "$dbms_dir" ]]; then
    cd "$dbms_dir"
    echo "-Database is connected..."
else
    mkdir -p "$dbms_dir"
    cd "$dbms_dir"
    echo "-Database is connected..."
fi

# Function for validation
function validate_name() {
    name="$1"
    case $name in
        '')
            echo ":(Please Enter a Valid Name (cannot be empty)."
            return 1
            ;;
        *[[:space:]]*)
            echo ":(Please Enter a Valid Name (cannot contain spaces)."
            return 1
            ;;
        [0-9]*)
            echo ":(Please Enter a Valid Name (cannot start with a number)."
            return 1
            ;;
        *[^a-zA-Z0-9_]*)
            echo ":(Please Enter a Valid Name (can only contain letters, numbers, and underscores)."
            return 1
            ;;
        *)
            return 0  # Name is valid
            ;;
    esac
}

# Function to handle database operations
function database_operations() {
    while true; do
        echo "****************************************** WELCOME TO DBMS ENGINE ******************************************"
        select choice in CreateDB List_DataBase Connect_to_DataBase Drop_DataBase Quit; do
            case $choice in
                CreateDB)
                    read -p "-Please Enter Database name: " DBName
                    if validate_name "$DBName"; then
                        if [[ -e "$DBName" ]]; then
                            echo ":(Database '$DBName' already exists. Try another name."
                        else
                            mkdir "$DBName" 2>/dev/null
                            if [[ $? -eq 0 ]]; then
                                echo ":)Database '$DBName' created successfully."
                            else
                                echo ":(Error: Permission denied. Cannot create database '$DBName'."
                            fi
                        fi
                    fi
                    break
                    ;;
                List_DataBase)
                    echo ":)****************************************** Available Databases ******************************************"
                    ls -F | grep '/$' | sed 's|/$||'
                    break
                    ;;
                Connect_to_DataBase)
                    read -p "-Please Enter Database name to connect: " DBName
                    if validate_name "$DBName"; then
                        if [[ -d "$DBName" ]]; then
                            cd "$DBName"
                            echo ":)Connected to database '$DBName'"
                            table_operations  # Enter table operations menu
                        else
                            echo ":(Database '$DBName' does not exist."
                        fi
                    fi
                    break
                    ;;
                Drop_DataBase)
                    read -p "-Please Enter Database name to drop: " DBName
                    if validate_name "$DBName"; then
                        if [[ -d "$DBName" ]]; then
                            rm -r "$DBName" 2>/dev/null
                            if [[ $? -eq 0 ]]; then
                                echo ":)Database '$DBName' dropped successfully."
                            else
                                echo ":(Error: Permission denied. Cannot drop database '$DBName'."
                            fi
                        else
                            echo ":(Database '$DBName' does not exist."
                        fi
                    fi
                    break
                    ;;
                Quit)
                    echo ":)Exiting..."
                    exit 0
                    ;;
                *)
                    echo ":(Invalid option. Please try again."
                    ;;
            esac
        done
    done
}

# Start the database operations menu
database_operations
