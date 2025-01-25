#!/usr/bin/bash



# File paths
schema_file=".table"
data_file="$table_name"

# Function to check if the schema file exists
check_schema_file() {
    if [ ! -f "$schema_file" ]; then
        echo "Schema file  not found!"
        exit 1
    fi
}


# Function to read the schema from .table.str and store column names and types
read_schema() {
    num_cols=$(wc -l < "$schema_file")
    col_names=()
    col_types=()

    for ((i = 1; i <= num_cols; i++)); do
        # Read the schema for column name and type
        col_info=$(sed -n "${i}p" "$schema_file")
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
    
    # Loop through the schema and prompt the user for each column
    for ((i = 0; i < num_cols; i++)); do
        col_name="${col_names[$i]}"
        col_type="${col_types[$i]}"

        # Loop until valid data is entered
        while true; do
            read -p "Enter $col_name ($col_type): " data

            # Data validation
            if [[ "$col_type" == "int" && ! "$data" =~ ^[0-9]+$ ]]; then
                echo "Invalid input for $col_name. Expected an integer. Please try again."
            elif [[ "$col_type" == "string" && -z "$data" ]]; then
                echo "Invalid input for $col_name. Expected a non-empty string. Please try again."
            else
                # If data is valid, break the loop
                break
            fi
        done

        # Append valid data to the insert_data string
        insert_data=$insert_data$data 
    done

    # Insert the data into the data file
    echo "$insert_data" >> "$data_file"
    echo "Data inserted successfully into the table."
}



# Function to calculate the maximum width of each column
calculate_column_widths() {
    column_widths=()
    
    for ((i = 0; i < num_cols; i++)); do
        max_len=${#col_names[$i]}
        # Calculate max length for each column by checking data
        for line in $(cat "$data_file"); do
            col_data=$(echo $line | cut -d' ' -f$((i+1)))
            len=${#col_data}
            if ((len > max_len)); then
                max_len=$len
            fi
        done
        column_widths+=($max_len)
    done
}

# Function to print the table with proper formatting
print_table() {
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
        separator+=$(printf "%-${width}s" "-------")
        separator+="+"
    done
    echo "$separator"

    # Print the data rows
    while IFS= read -r line; do
        row=""
        for ((i = 0; i < num_cols; i++)); do
            col_data=$(echo $line | cut -d' ' -f$((i+1)))
            row+="| $(printf "%-${column_widths[$i]}s" "$col_data") "
        done
        row+="|"
        echo "$row"
    done < "$data_file"

    # Print the bottom separator line
    echo "$separator"
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
        echo "Column '$update_col' does not exist. Exiting update process."
        return
    fi
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
        echo "Column '$delete_col' does not exist. Exiting delete process."
        return
    fi

    # Ask for the value to delete
    read -p "Enter the value of $delete_col to delete the row: " delete_value

    # Remove the row from the data file
    sed -i "/$delete_value/d" "$data_file"
    echo "Row with value '$delete_value' in column '$delete_col' deleted successfully."
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













