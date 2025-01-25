#!/usr/bin/bash


function table_operations() {
        
    while true; do
        echo "****************************************** Table Operations ******************************************"
        select choice in create_table list_table drop_table manipulate_table back_to_main; do
            case $choice in
                create_table)
                    read -p "-Enter your table name to create: " table_name
                  
                    
                    if validate_name "$table_name"; then
                        if [[ -e "$table_name" ]]; then
                            echo "Table '$table_name' already exists."
                        else
                            read -p "-Please enter the number of columns: " colNum
                            if [[ $colNum =~ ^[0-9]+$ ]] && [[ $colNum -gt 0 ]]; then
                                declare -a columns
                                declare -a datatypes
                                primary_key_set=false

                                # Create metadata file
                                 metadata_file="meta-data"
                                echo "Column Name : Data Type : Primary Key" > "$metadata_file"

                                for ((i = 1; i <= $colNum; i++)); do
                                    while true; do
                                        read -p "-Please enter column $i name: " colName
                                        if validate_name "$colName"; then
                                            # Check if column name already exists
                                            if [[ " ${columns[@]} " =~ " ${colName} " ]]; then
                                                echo ":(Column name '$colName' already exists. Please enter a unique name."
                                            else
                                                break
                                            fi
                                        fi
                                    done

                                    while true; do
                                        read -p "-Please enter data type for column '$colName' (int/str): " colType
                                        if [[ "$colType" =~ ^([iI][nN][tT]|[iI])$ || "$colType" =~ ^([sS][tT][rR]|[sS])$ ]]; then
                                            break
                                        else
                                            echo ":)Invalid data type. Please enter 'int' or 'str'."
                                        fi
                                    done  

                                    # Initialize the line with column name and data type
                                    line="$colName : $colType"

                                    # primary key
                                    if ! $primary_key_set; then
                                        while true; do
                                            read -p "-Do you want to make '$colName' the primary key? (yes/no): " pkCheck
                                            if [[ "$pkCheck" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                                                line+=": pk"
                                                primary_key_set=true
                                                break
                                            elif [[ "$pkCheck" =~ ^([nN][oO]|[nN])$ ]]; then
                                                line+=":"
                                                break
                                            else
                                                echo ":(Invalid input. Please enter 'yes' or 'no'."
                                            fi
                                        done
                                    else
                                        line+=":"
                                    fi

                                    # Append the column metadata to the file
                                    echo "$line" >> "$metadata_file"

                                    # Store column name and data type in arrays
                                    columns+=("$colName")
                                    datatypes+=("$colType")
                                done

                                # Create the table file
                                touch "$table_name"
                                echo ":)Table '$table_name' created successfully with the following columns:"
                                cat "$metadata_file"
                            else
                                echo ":(Invalid number of columns. Please enter a positive integer."
                            fi
                        fi
                    fi
                    break
                    ;;
                list_table)
                    echo "****************************************** Available Tables ******************************************"
                    ls -F | grep -v '/'
                    break
                    ;;
                drop_table)
                    read -p "-Enter the table name to drop: " table_name
                    if validate_name "$table_name"; then
                        if [[ -e "$table_name" ]]; then
                            rm "$table_name"
                            echo ":)Table '$table_name' dropped successfully."
                        else
                            echo ":(Table '$table_name' does not exist."
                        fi
                    fi
                    break
                    ;;
                back_to_main)
                    cd ..
                    return
                    ;;
                manipulate_table)
                 # File paths

                 

                    
                    metadata_file="meta-data"  
                    # Function to check if the schema file exists
                    check_schema_file() {
                        if [ ! -f "$metadata_file" ]; then
                            echo "Schema file  not found!"
                            exit 1
                        fi
                    }
                    if [ ! -f "$table_name" ]; then
                         echo "Table data file '$table_name' not found!"
                         exit 1
                    fi


                    # Function to read the schema from meta data table and store column names and types
                    read_schema() {
                        num_cols=$(sed -n '2,$p' $metadata_file | wc -l)
                        col_names=()
                        col_types=()

                        for ((i = 1; i <= $num_cols; i++)); do
                            # Read the schema for column name and type
                            col_info=$(sed -n "$((i+1))p" "$metadata_file")
                            col_name=$(echo "$col_info" | cut -d: -f1)
                            col_type=$(echo "$col_info" | cut -d: -f2)

                            # Store column names and types
                            col_names+=("$col_name")
                            col_types+=("$col_type")
                        done
                    }

                    # Function to insert data into the table with validation
                    
                      insert_data() {
                        insert_data=""
                        primary_key_col=""

                        # Find the primary key column (if any)
                        for ((i = 0; i < $num_cols; i++)); do
                            if [[ "${primary_keys[$i]}" == "pk" ]]; then
                                primary_key_col="${col_names[$i]}"
                                break
                            fi
                        done

                        # Loop through the schema and prompt the user for each column
                        for ((i = 0; i < $num_cols; i++)); do
                            col_name="${col_names[$i]}"
                            col_type="${col_types[$i]}"

                            # Loop until valid data is entered
                            while true; do
                                read -p "Enter $col_name ($col_type): " data
                                data=$(echo "$data" | xargs)  # Trim leading/trailing whitespace

                                # Data validation
                                if [[ "$col_type" == "int" && ! "$data" =~ ^[0-9]+$ ]]; then
                                    echo "Error: Invalid input for $col_name. Expected an integer. Please try again."
                                elif [[ "$col_type" == "string" && -z "$data" ]]; then
                                    echo "Error: Invalid input for $col_name. Expected a non-empty string. Please try again."
                                else
                                    # Check for primary key uniqueness
                                    if [[ "$col_name" == "$primary_key_col" ]]; then
                                        if awk -F'|' -v col="$((i+1))" -v val="$data" '$col == val' "$table_name" | grep -q .; then
                                            echo "Error: Value '$data' already exists in the primary key column '$primary_key_col'. It must be unique."
                                        else
                                            break
                                        fi
                                    else
                                        break
                                    fi
                                fi
                            done

                            # Append data with a delimiter (e.g., '|')
                            if [[ -z "$insert_data" ]]; then
                                insert_data="$data"
                            else
                                insert_data="$insert_data|$data"
                            fi
                        done

                        # Insert the data into the data file
                        if echo "$insert_data" >> "$table_name"; then
                            echo "Data inserted successfully into the table."
                        else
                            echo "Error: Failed to write data to the table file."
                            exit 1
                        fi
                    }


print_table() {
    local data_file="$1"

    # Check if the data file exists and is not empty
    if [[ ! -f "$data_file" || ! -s "$data_file" ]]; then
        echo "Error: Data file '$data_file' is missing or empty."
        return 1
    fi

    # Initialize column names (first row in the data file) and calculate column count
    IFS='|' read -r -a col_names < "$data_file"  # Read first row as column names
    num_cols=${#col_names[@]}  # Set the number of columns based on the column names

    # Initialize column_widths array if not already done
    if [[ ${#column_widths[@]} -eq 0 ]]; then
        calculate_column_widths "$data_file"
    fi

    # Print the table header
    header=""
    for ((i = 0; i < num_cols; i++)); do
        header+="| $(printf "%-${column_widths[$i]}s" "${col_names[$i]}") "
    done
    header+="|"
    echo "$header"

    # Print the separator line
    separator="+"
    for width in "${column_widths[@]}"; do
        separator+=$(printf "%-$((width+2))s" "" | tr ' ' '-')
        separator+="+"
    done
    echo "$separator"

    # Print the data rows
    # Skip the first line (header) and process the rest
    tail -n +2 "$data_file" | while IFS= read -r line; do
        row=""
        for ((i = 0; i < num_cols; i++)); do
            col_data=$(echo "$line" | cut -d'|' -f$((i+1)))
            row+="| $(printf "%-${column_widths[$i]}s" "$col_data") "
        done
        row+="|"
        echo "$row"
    done

    # Print the bottom separator line
    echo "$separator"
}


# Helper function to calculate column widths
calculate_column_widths() {
    local data_file="$1"
    column_widths=()

    for ((i = 0; i < num_cols; i++)); do
        max_len=${#col_names[$i]}
        while IFS= read -r line; do
            col_data=$(echo "$line" | cut -d'|' -f$((i+1)))
            len=${#col_data}
            if ((len > max_len)); then
                max_len=$len
            fi
        done < "$data_file"
        column_widths+=("$max_len")
    done
}

                    select_data() {
                        # Ask the user for a column to filter by
                        echo "Available columns for filtering: ${col_names[@]}"
                        read -p "Enter the column name to filter by (or press Enter to show all data): " filter_col

                        # If the user chose to filter by a column
                        if [ -n "$filter_col" ]; then
                            # Check if the column exists
                            col_index=-1
                            for ((i = 0; i < num_cols; i++)); do
                                if [ "${col_names[$i]}" == "$filter_col" ]; then
                                    col_index=$i
                                    break
                                fi
                            done

                            if [ $col_index -eq -1 ]; then
                                echo "Column '$filter_col' does not exist. Displaying all data."
                                print_table
                                return
                            fi

                            # Ask for the value to filter by
                            read -p "Enter the value to filter '$filter_col' by: " filter_value
                            
                            # Filter the data and display the rows
                            filtered_data=$(grep -E "^([^\ ]*\ ){${col_index}}$filter_value" "$data_file")
                            if [ -z "$filtered_data" ]; then
                                echo "No matching data found for '$filter_value' in '$filter_col'."
                            else
                                # Print the filtered data in table format
                                calculate_column_widths
                                print_table <<< "$filtered_data"
                            fi
                        else
                            # If no filter is chosen, print all data
                            calculate_column_widths
                            print_table
                        fi
                    }

                    # Function to update data based on conditions
                   update_data() {
                        # Ask the user for the column to update
                        echo "Available columns for updating: ${col_names[@]}"
                        read -p "Enter the column name you want to update: " update_col

                        # Check if the column exists
                        col_index=-1
                        for ((i = 0; i < num_cols; i++)); do
                            if [ "${col_names[$i]}" == "$update_col" ]; then
                                col_index=$i
                                break
                            fi
                        done

                        if [ $col_index -eq -1 ]; then
                            echo "Error: Column '$update_col' does not exist. Exiting update process."
                            return
                        fi

                        # Ask the user for the row identifier (primary key or unique column)
                        echo "Available columns for identifying the row: ${col_names[@]}"
                        read -p "Enter the column name to identify the row (e.g., primary key): " identifier_col

                        # Check if the identifier column exists
                        identifier_index=-1
                        for ((i = 0; i < num_cols; i++)); do
                            if [ "${col_names[$i]}" == "$identifier_col" ]; then
                                identifier_index=$i
                                break
                            fi
                        done

                        if [ $identifier_index -eq -1 ]; then
                            echo "Error: Column '$identifier_col' does not exist. Exiting update process."
                            return
                        fi

                        # Ask for the identifier value
                        read -p "Enter the value of '$identifier_col' to identify the row: " identifier_value

                        # Find the row to update
                        row_to_update=$(awk -F'|' -v col="$((identifier_index+1))" -v val="$identifier_value" '$col == val' "$table_name")
                        if [ -z "$row_to_update" ]; then
                            echo "Error: No row found with '$identifier_col' = '$identifier_value'."
                            return
                        fi

                        # Ask for the new value
                        read -p "Enter the new value for '$update_col': " new_value

                        # Validate the new value against the column's data type
                        col_type="${col_types[$col_index]}"
                        if [[ "$col_type" == "int" && ! "$new_value" =~ ^[0-9]+$ ]]; then
                            echo "Error: Invalid input for '$update_col'. Expected an integer."
                            return
                        elif [[ "$col_type" == "string" && -z "$new_value" ]]; then
                            echo "Error: Invalid input for '$update_col'. Expected a non-empty string."
                            return
                        fi

                        # Check for primary key uniqueness if updating the primary key column
                        if [[ "${primary_keys[$col_index]}" == "pk" ]]; then
                            if awk -F'|' -v col="$((col_index+1))" -v val="$new_value" '$col == val' "$table_name" | grep -q .; then
                                echo "Error: Value '$new_value' already exists in the primary key column '$update_col'. It must be unique."
                                return
                            fi
                        fi

                        # Update the row in the table file
                        awk -F'|' -v col="$((col_index+1))" -v val="$new_value" -v id_col="$((identifier_index+1))" -v id_val="$identifier_value" '
                        BEGIN { OFS="|" }
                        {
                            if ($id_col == id_val) {
                                $col = val
                            }
                            print $0
                        }
                        ' "$table_name" > "${table_name}.tmp" && mv "${table_name}.tmp" "$table_name"

                        echo "Row updated successfully."
                    }
                    # Function to delete data from the table based on a condition
                  delete_data() {
                            # Ask the user for the column to delete by
                            echo "Available columns for deleting: ${col_names[@]}"
                            read -p "Enter the column name to delete by: " delete_col

                            # Check if the column exists
                            col_index=-1
                            for ((i = 0; i < num_cols; i++)); do
                                if [ "${col_names[$i]}" == "$delete_col" ]; then
                                    col_index=$i
                                    break
                                fi
                            done

                            if [ $col_index -eq -1 ]; then
                                echo "Error: Column '$delete_col' does not exist. Exiting delete process."
                                return
                            fi

                            # Ask for the value to delete
                            read -p "Enter the value of '$delete_col' to delete the row: " delete_value

                            # Use awk to delete the row where the specified column matches the value
                            awk -F'|' -v col="$((col_index+1))" -v val="$delete_value" '
                            {
                                if ($col != val) {
                                    print $0
                                }
                            }
                            ' "$data_file" > "${data_file}.tmp" && mv "${data_file}.tmp" "$data_file"

                            # Check if the row was deleted
                            if grep -q "$delete_value" "$data_file"; then
                                echo "Error: No row found with '$delete_col' = '$delete_value'."
                            else
                                echo "Row with value '$delete_value' in column '$delete_col' deleted successfully."
                            fi
                        }




                    # Main function to control the flow of the script
                    main() {
                        # Check if the schema file exists
                        check_schema_file

                        # Read the schema file
                        read_schema

                        while true; do
                            echo "Choose an action:"
                            echo "1. Insert Data"
                            echo "2. Select Data"
                            echo "3. Update Data"
                            echo "4. Delete Data"
                            echo "5. Exit"
                            read -p "Enter your choice: " choice

                            case $choice in
                                1)
                                    # Insert data
                                    insert_data
                                    ;;
                                2)
                                    # Select data
                                    select_data
                                    ;;
                                3)
                                    # Update data
                                    update_data
                                    ;;
                                4)
                                    # Delete data
                                    delete_data
                                    ;;
                                5)
                                    # Exit the script
                                    echo "Exiting the program."
                                    exit 0
                                    ;;
                                *)
                                    echo "Invalid choice. Please try again."
                                    ;;
                            esac
                        done
                    }

                    # Run the main function
                    main
                                    break
                                        ;;
                *)
                    echo ":(Invalid option. Please try again."
                    ;;
            esac
        done
    done
}
