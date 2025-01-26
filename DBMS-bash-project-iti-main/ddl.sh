#!/usr/bin/bash


function table_operations() {
        
    while true; do
        echo "****************************************** Table Operations ******************************************"
        select choice in create_table list_table drop_table manipulate_table back_to_main; do
            case $choice in
                create_table)
                while true; do
                    read -p "-Enter your table name to create: " table_name
                  
                    
                    if validate_name "$table_name"; then
                        if [[ -e "$table_name" ]]; then
                            echo "Table '$table_name' already exists."
                        else
                            read -p "-Please enter the number of columns: " colNum
                            if [[ $colNum =~ ^[0-9]+$ ]] && [[ $colNum -gt 0 ]]; then
                                declare -a columns
                                declare -a datatypes
                                declare -a primary_keys  # Declare the primary_keys array
                                primary_key_set=false

                                # Create metadata file
                                 metadata_file="meta-data_$table_name"
                                 
                               
                                 
                                 
                                echo "Column Name : Data Type : Primary Key" > "$metadata_file"

                                for ((i = 1; i <= colNum; i++)); do
                                    while true; do
                                        read -p "-Please enter column $i name: " colName
                                        if validate_name "$colName"; then
                                            # Check if column name already exists
                                            if [[ " ${columns[@]} " =~  ${colName}  ]]; then
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
                                                primary_keys+=("pk")  # Mark this column as a primary key
                                                primary_key_set=true
                                                break
                                            elif [[ "$pkCheck" =~ ^([nN][oO]|[nN])$ ]]; then
                                                line+=":"
                                                primary_keys+=("")  # Mark this column as not a primary key
                                                break
                                            else
                                                echo ":(Invalid input. Please enter 'yes' or 'no'."
                                            fi
                                        done
                                    else
                                        line+=":"
                                        primary_keys+=("")  # Mark this column as not a primary key
                                    fi

                                    # Append the column metadata to the file
                                    echo "$line" >> "$metadata_file"

                                    # Store column name and data type in arrays
                                    columns+=("$colName")
                                    datatypes+=("$colType")
                                done

                                # Create the table file
                                data_file=$(touch "$table_name")
                                echo ":)Table '$table_name' created successfully with the following columns:"
                                cat "$metadata_file"
                                break
                            else
                                echo ":(Invalid number of columns. Please enter a positive integer."
                            fi
                        fi
                    fi
                   done
                   break
                    ;;
                list_table)
                    echo "****************************************** Available Tables ******************************************"
                    ls -F | grep -v '/'
                    break
                    ;;
                drop_table)
                        while true; do
                    read -p "-Enter the table name to drop: " table_name
                    if validate_name "$table_name"; then
                        if [[ -f "$table_name" ]]; then
                        rm "$table_name"
                        echo ":)Table file '$table_name' dropped successfully."
                    fi
                    
                    if [[ -f "meta-data_$table_name" ]]; then
                        rm "meta-data_$table_name"
                        echo ":)Metadata file 'meta-data_$table_name' dropped successfully."
                    fi
                    
                    break
                    
                    fi
                    done
                    break
                    ;;
                back_to_main)
                    cd ..
                    return
                    ;;
                manipulate_table)
                 
                  while true; do
                 read -p "-enter the table name you want to manipulate: " table_name

                 # Explicitly set the metadata file path
                      metadata_file=meta-data_$table_name              
                     
                        if [ ! -f "$metadata_file" ]; then
                        
                            echo ":(Not found table name "
                            continue
                        else
                          break
                        fi
                        
                    
                    done
                    

                    # Function to read the schema from meta data table and store column names and types
                    read_schema() {
                        num_cols=$(sed -n '2,$p' "$metadata_file" | wc -l)
                        col_names=()
                        col_types=()
                        primary_keys=()

                        

                        
                        

                        for ((i = 1; i <= num_cols; i++)); do
                            # Read the schema for column name and type
                            col_info=$(sed -n "$((i+1))p" "$metadata_file")
                            col_name=$(echo "$col_info" | cut -d: -f1)
                            col_type=$(echo "$col_info" | cut -d: -f2)
                            primary_key_col=$(echo "$col_info" | cut -d: -f3)
                          
                           
                            # Store column names and types and primary keys
                            col_names+=("$col_name")
                            col_types+=("$col_type")
                            primary_keys+=("$primary_key_col")
                        done
                    }

                    # Function to insert data into the table with validation
                    
                      insert_data() {
                        insert_data=""
                        primary_key_index=-1
                        

                        # Find the primary key column (if any)
                        for ((i = 0; i < num_cols; i++)); do
                           
                            if [ "$(echo "${primary_keys[$i]}" | xargs | tr '[:upper:]' '[:lower:]')" == "pk" ]; then
                                primary_key_col="${col_names[$i]}"
                                primary_key_index=$i
                                echo "-Primary key column: $primary_key_col"  # Debugging
                                break
                            fi
                        done

  

                        # Loop through the schema and prompt the user for each column
                        for ((i = 0; i < num_cols; i++)); do
                            col_name="${col_names[$i]}"
                            col_type="${col_types[$i]}"

                            # Loop until valid data is entered
                            while true; do
                                read -p "Enter $col_name($col_type): " data
                                
                                # Trim spaces
                                data=$(echo "$data" | xargs)
                                col_type=$(echo "$col_type" | xargs)

                                # Data validation for integer type
                                if [[ "$col_type" == "int" || "$col_type" =~ ^[iI]$ ]]; then
                                    if [[ -z "$data" || ! "$data" =~ ^[0-9]+$ ]]; then
                                        echo ":(Error: Invalid input for $col_name. Expected an integer. Please try again."
                                        continue  # Retry the loop if input is not a valid integer
                                    fi
                                # Data validation for string type
                                elif [[ "$col_type" == "str" || "$col_type" =~ ^[sS]$ ]]; then
                                    if [[ -z "$data" ]]; then
                                        echo ":(Error: Invalid input for $col_name. Expected a non-empty string. Please try again."
                                        continue  # Retry the loop if input is an empty string
                                    fi
                                fi

                                # Check for primary key uniqueness only if we are at the primary key column
                                if [[ "$i" -eq "$primary_key_index" ]]; then
                                    if cut -d'|' -f$((i+1)) "$table_name" | grep -qx "$data"; then
                                        echo ":(Error: Value '$data' must be unique in primary key column."
                                        continue  # Retry if the primary key is not unique
                                    fi
                                fi

                                # Break the loop once valid data is entered
                                break
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
                            echo ":)Data inserted successfully into the table."
                        else
                            echo ":(Error: Failed to write data to the table file."
                            exit 1
                        fi
                    }
                   # Function to calculate column widths based on data
                    calculate_column_widths() {
                        local data_file="$1"
                        column_widths=()  # Reset the array to avoid appending to old values

                        for ((i = 0; i < num_cols; i++)); do
                            max_len=${#col_names[$i]}  # Start with the length of the column name

                            # Read the data file line by line
                            while IFS= read -r line; do
                                col_data=$(echo "$line" | cut -d'|' -f$((i+1)))  # Extract data from the column
                                len=${#col_data}
                                if ((len > max_len)); then
                                    max_len=$len  # Update the maximum length if necessary
                                fi
                            done < "$data_file"

                            column_widths+=("$max_len")  # Store the max length for each column
                        done
                    }

                    # Function to print the table
                    print_table() {
                        local meta_file="$1"
                        local data_file="$2"

                        # Check if the metadata and data files exist and are not empty
                        if [[ ! -f "$meta_file" || ! -s "$meta_file" ]]; then
                            echo ":(Error: Metadata file '$meta_file' is missing or empty."
                            return 1
                        fi

                        if [[ ! -f "$data_file" || ! -s "$data_file" ]]; then
                            echo ":(Error: Data file '$data_file' is missing or empty."
                            return 1
                        fi

                        # Initialize column names from the metadata file (skip headers and read column names)
                        col_names=()
                        while IFS= read -r line; do
                            # Skip the header line, assuming it starts with "Column Name"
                            if [[ "$line" =~ ^Column\ Name ]]; then
                                continue
                            fi
                            
                            # Extract the column name (before the first ' : ')
                            column_name=$(echo "$line" | cut -d' ' -f1)
                            col_names+=("$column_name")
                        done < "$meta_file"
                        
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

                        # Print the data rows (skip the first line, which is the header)
                        while IFS= read -r line; do
                            row=""
                            for ((i = 0; i < num_cols; i++)); do
                                col_data=$(echo "$line" | cut -d'|' -f$((i+1)))
                                row+="| $(printf "%-${column_widths[$i]}s" "$col_data") "
                            done
                            row+="|"
                            echo "$row"
                        done < "$data_file"  # Read from the data file

                        # Print the bottom separator line
                        echo "$separator"
                    }

                    

                          
                      

                   select_data() {
                        # Ask the user for a column to filter by
                        echo ">>Available columns for filtering: ${col_names[@]}"
                        read -p "-Enter the column name to filter by (or press Enter to show all data): " filter_col

                        # If the user chose to filter by a column (filter_col is not empty)
                        if [ -n "$filter_col" ]; then
                            # Check if the column exists
                            col_index=-1
                            for ((i = 0; i < num_cols; i++)); do
                                # Case-insensitive comparison of column names
                                if [ "$(echo "${col_names[$i]}" | xargs | tr '[:upper:]' '[:lower:]')" == "$(echo "$filter_col" | xargs | tr '[:upper:]' '[:lower:]')" ]; then
                                    col_index=$i
                                    break
                                fi
                            done

                            if [ $col_index -eq -1 ]; then
                                echo ":(Column '$filter_col' does not exist. Displaying all data."
                                print_table "$metadata_file" "$table_name"  # Assuming metadata_file and table_name are different
                                return
                            fi

                            # Ask for the value to filter by
                            read -p "-Enter the value to filter '$filter_col' by: " filter_value

                            # Filter the data using awk (case-insensitive filter on the column value)
                            temp_file=$(mktemp)  # Create a temporary file
                            awk -F'|' -v col="$((col_index+1))" -v val="$(echo "$filter_value" | tr '[:upper:]' '[:lower:]')" '
                                tolower($col) == val { print $0 }
                            ' "$table_name" > "$temp_file"  # Filter with case-insensitive comparison

                            # Check if any rows match the filter
                            if [[ ! -s "$temp_file" ]]; then
                                echo ":(No matching data found for '$filter_value' in '$filter_col'."
                            else
                                # Print the filtered data in table format
                                calculate_column_widths "$temp_file"
                                print_table "$metadata_file" "$temp_file"  # Print using metadata and filtered data
                            fi

                            # Clean up the temporary file
                            rm "$temp_file"
                        else
                            # If no filter is chosen, print all data
                            calculate_column_widths "$table_name" 
                            print_table "$metadata_file" "$table_name"
                        fi
                    }


                    # Function to update data based on conditions
                   update_data() {
                        # Ask the user for the column to update
                        echo ">>Available columns for updating: ${col_names[@]}"
                        read -p "-Enter the column name you want to update: " update_col

                        # Check if the column exists
                        col_index=-1
                        for ((i = 0; i < num_cols; i++)); do
                        #echo "Debug: Column names: ${col_names[@]}"
                            if [ "$(echo "${col_names[$i]}" | xargs | tr '[:upper:]' '[:lower:]')" == "$(echo "$update_col" | xargs | tr '[:upper:]' '[:lower:]')" ]; then
                                        col_index=$i
                                        #echo "Debug: Match found at index $col_index"
                                        break
                                   
                                    fi
                        done

                        if [ $col_index -eq -1 ]; then
                            echo ":(Error: Column '$update_col' does not exist. Exiting update process."
                            return
                        fi

                        # Ask the user for the row identifier (primary key or unique column)
                        echo ">>Available columns for identifying the row: ${col_names[@]}"
                        read -p "-Enter the column name to identify the row (e.g., primary key,unique column): " identifier_col

                        # Check if the identifier column exists
                        identifier_index=-1
                        for ((i = 0; i < num_cols; i++)); do
                            if [ "$(echo "${col_names[$i]}" | xargs | tr '[:upper:]' '[:lower:]')" == "$(echo "$identifier_col" | xargs | tr '[:upper:]' '[:lower:]')" ]; then
                                identifier_index=$i
                                break
                            fi
                        done

                        if [ $identifier_index -eq -1 ]; then
                            echo ":(Error: Column '$identifier_col' does not exist. Exiting update process."
                            return
                        fi

                        # Ask for the identifier value
                        read -p "-Enter the value of '$identifier_col' to identify the row: " identifier_value

                        # Find the row to update
                        row_to_update=$(awk -F'|' -v col="$((identifier_index+1))" -v val="$identifier_value" '$col == val' "$table_name")
                        if [ -z "$row_to_update" ]; then
                            echo "Error: No row found with '$identifier_col' = '$identifier_value'."
                            return
                        fi

                        # Ask for the new value
                        read -p "-Enter the new value for '$update_col': " new_value

                        # Validate the new value against the column's data type
                        col_type="${col_types[$col_index]}"
                        if [[ "$col_type" == "int" && ! "$new_value" =~ ^[0-9]+$ ]]; then
                            echo "Error: Invalid input for '$update_col'. Expected an integer."
                            return
                        elif [[ "$col_type" == "string" && -z "$new_value" ]]; then
                            echo ":(Error: Invalid input for '$update_col'. Expected a non-empty string."
                            return
                        fi

                        # Check for primary key uniqueness if updating the primary key column
                        if [[ "${primary_keys[$col_index]}" == "pk" ]]; then
                            if awk -F'|' -v col="$((col_index+1))" -v val="$new_value" '$col == val' "$table_name" | grep -q .; then
                                echo ":(Error: Value '$new_value' already exists in the primary key column '$update_col'. It must be unique."
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

                        echo ":)Row updated successfully."
                    }
                    # Function to delete data from the table based on a condition
                  delete_data() {
                            # Ask the user for the column to delete by
                            echo ">>Available columns for deleting: ${col_names[@]}"
                            read -p "-Enter the column name to delete by: " delete_col

                            # Check if the column exists
                            col_index=-1
                            for ((i = 0; i < num_cols; i++)); do
                                if [ "$(echo "${col_names[$i]}" | xargs | tr '[:upper:]' '[:lower:]')" == "$(echo "$delete_col" | xargs | tr '[:upper:]' '[:lower:]')" ]; then
                                    col_index=$i
                                    break
                                fi
                            done

                            if [ $col_index -eq -1 ]; then
                                echo ":(Error: Column '$delete_col' does not exist. Exiting delete process."
                                return
                            fi

                            # Ask for the value to delete
                            read -p "-Enter the value of '$delete_col' to delete the row: " delete_value

                           
                              # Trim any surrounding spaces

   
                           delete_value="$(echo "$delete_value" | xargs)"  # Trim any surrounding spaces

                            # Check if the row exists in the table
                            if grep -q "$delete_value" "$table_name"; then
                                # Delete the row containing the value
                                
                                sed -i "/$delete_value/d" "$table_name"  # Remove the row from the table
                                echo ":)Row with value $delete_value in column $delete_col deleted successfully."
                            else
                                echo ":(Error: No row found with $delete_col = $delete_value."
                            fi
                        }



                    # Main function to control the flow of the script
                    main() {
                       

                        # Read the schema file
                        read_schema

                        while true; do
                            echo ">>Choose an action:"
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
                                    echo ":(Exiting the program."
                                    exit 0
                                    ;;
                                *)
                                    echo ":(Invalid choice. Please try again."
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
