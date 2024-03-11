#!/bin/bash

DATABASE_DIR="databases"

function echo_adv() {
  echo -e "\n--------------------------------------------------------------------"
  echo -e "$1\n"
  echo -e "---------------------------------------------------------------\n"
}

function name_validation() {
 if [[ -n "$1" && "$1" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
	return 0  # Valid name
  else
	echo_adv "Invalid name. Names should not be empty, and must start with a letter or underscore, and only contain letters, numbers, or underscores without any spaces."
	return 1  # Invalid name
  fi
}


function Create_Table() {
  read -p "Enter the New table name: " TBname

  if ! name_validation "$TBname"; then
    Connect_Database
  fi

  # Check if the table already exists
  if [[ -f "$DATABASE_DIR/$db_name/$TBname" ]]; then
    echo_adv "Error: Table '$TBname' already exists in the current database."
    Connect_Database
  fi

  read -p "Enter the number of columns: " TBcolnum
  while [[ ! $TBcolnum =~ ^[1-9]$|^1[0-9]$ ]]; do
    read -p "Invalid input please try again .. Enter the number of columns: " TBcolnum
  done

  counter=1
  sep="|"
  lsep="\n"
  col_names=()
  data_types=()  # Added array to store data types
  metadata=""
  PK=""

  while [ $counter -le $TBcolnum ]; do
    read -p "Enter the name of column $counter: " TBTBcolname

    # Check if the column name starts with a space
    if [[ "${TBTBcolname:0:1}" == " " ]]; then
      echo_adv "Error: Column name '$TBTBcolname' starts with a space. Please choose a different name."
      continue
    fi

    # Check if the column name already exists
    if [[ " ${col_names[@]} " =~ " ${TBTBcolname} " ]]; then
      echo_adv "Error: Column name '$TBTBcolname' already exists. Please choose a different name."
      continue
    fi

    if ! name_validation "$TBTBcolname"; then
      continue
    fi

    echo "Choose the data type for $TBTBcolname"
    select choice in "int" "string"; do
      case $REPLY in
        1) data_type="int"; break ;;
        2) data_type="string"; break ;;
        *) echo -e "\nInvalid option, please try again." ;;
      esac
    done

    col_names+=("$TBTBcolname")
    data_types+=("$data_type")  # Add data type to the array

    let counter=$counter+1

  done

  # Ask about the primary key using a while loop
  echo "List of columns:"
  index=1
  for col_name in "${col_names[@]}"; do
    echo "$index) $col_name"
    let index=index+1
  done

  while true; do
    read -p "Choose a column number for the primary key (1-$TBcolnum): " col_choice_index

    if [[ $col_choice_index =~ ^[1-9]$|^1[0-9]$|^20$ ]] && [ $col_choice_index -le $TBcolnum ]; then
      col_choice=${col_names[$((col_choice_index-1))]}
      echo -e "\nSetting '$col_choice' as the primary key."
      PK="$col_choice"

      # Enhanced part: Rebuild metadata with PK information
      metadata=""
      for i in "${!col_names[@]}"; do
        col="${col_names[$i]}"
        data_type="${data_types[$i]}"
        pk_flag=""
        if [[ $col == $PK ]]; then
          pk_flag="PK"

        fi
        metadata+="$col|$data_type|$pk_flag\n"
      done

      break
    else
      echo -e "\nInvalid choice, please enter a valid column number."
    fi
  done

  # Join array elements into strings
  TBcolnames=$(IFS=$sep; echo "${col_names[*]}")

  # Write metadata and table data
  echo -e $metadata > "$DATABASE_DIR/$db_name/$TBname-meta.txt"
  echo -e $TBcolnames > "$DATABASE_DIR/$db_name/$TBname"

  echo_adv "Table '$TBname' created successfully."
  Connect_Database
}



function Drop_Table() {
    List_Tables
    read -p "Enter the name of the table to be dropped: " table_name

    if [ -f "$db_path/$table_name" ]; then
        table_path="$db_path/$table_name"
        meta_path="$db_path/$table_name-meta.txt"

        read -p "Are you sure you want to delete table '$table_name'? (y/n): " confirm_delete

        case $confirm_delete in
            [yY])
                if rm "$table_path" && rm "$meta_path"; then
                    echo "Table '$table_name' deleted successfully."
                else
                    echo "Failed to delete table '$table_name'."
                fi
                ;;
            [nN])
                echo "Deletion canceled."
                ;;
            *)
                echo "Invalid choice. Deletion canceled."
                ;;
        esac
    else
        echo "Table '$table_name' does not exist."
    fi
Connect_Database
}



function List_Tables() {
 echo "Existing tables in database '$db_name':"
 for TBname in "$DATABASE_DIR/$db_name"/*; do
  if [ -f "$TBname" ] && [[ ! $TBname =~ -meta.txt$ ]]; then
   echo "$(basename "$TBname")"
  fi
 done

}

function Drop_Database() {
  List_Databases
  read -p "Enter the database name that you want to drop: " db_name
  if name_validation "$db_name"; then
    db_path="$DATABASE_DIR/$db_name"
    if [ -d "$db_path" ]; then
      echo "Database '$db_name' exists."
      # Ask for confirmation before dropping the database
      read -p "Are you sure you want to drop database '$db_name'?(y/n): " confirm_drop

      echo "Confirmation input: $confirm_drop"

      case $confirm_drop in
          [yY])
              rm -rf "$db_path" # recursively and forcefully remove the directory and its contents
              echo "Database '$db_name' dropped successfully."
              ;;
          [nN])
              echo "Dropping database '$db_name' canceled."
              ;;
          *)
              echo "Invalid choice. Dropping database '$db_name' canceled."
              ;;
      esac
    else
      echo "Database '$db_name' does not exist."
    fi
  else
    echo "Invalid database name. Please use only letters, numbers, and underscores."
  fi
mainmenu
}



function Insert_into_Table() { 
	
	echo -e "\n"
        List_Tables
	read -p "Enter the table name: " TBname

	if ! [[ -f "$DATABASE_DIR/$db_name/$TBname" ]] 
	then
		echo_adv "The table isn't existed"
		Connect_Database
	fi	

	sep="|"
	data=""
	valid=0

	colnums=$(cat "$DATABASE_DIR/$db_name/$TBname-meta.txt" | wc -l)

	for (( i=1; i<$colnums; i++ ))
	do
		colname=$(awk 'BEGIN{FS="'$sep'"}{if (NR=='$i') print $1}' "$DATABASE_DIR/$db_name/$TBname-meta.txt")
		data_type=$(awk 'BEGIN{FS="'$sep'"} {if (NR=='$i') print $2}' "$DATABASE_DIR/$db_name/$TBname-meta.txt")
		pkey=$(awk 'BEGIN{FS="'$sep'"} {if (NR=='$i') print $3}' "$DATABASE_DIR/$db_name/$TBname-meta.txt")


		read -p "$i. $colname ($data_type): " value

		while [[ $valid == 0 ]]
		do
			if [[ $pkey == "PK" ]]
			then

				# validate the primary key isn't empty
				if [[ $value == "" ]]
				then
					echo -e "\n invalid data"
					echo "this field is a primary key and can't be empty"
					echo "enter new value"
					read -p "$i. $colname ($data_type): " value
					valid=0
					continue
				else
					valid=1
				fi

				# validate the primary key isn't repeated
				# Validate that the primary key isn't repeated
				flag=$(awk -v val="$value" 'BEGIN{FS="'$sep'"} {if ($'$i' == val) print $'$i'}' "$DATABASE_DIR/$db_name/$TBname")

				if [[ -n $flag ]]; then
				  echo -e "\nThis data already exists."
				  echo "This field is a primary key and can't be repeated."	
				  echo "Enter a new value:"
				  read -p "$i. $colname ($data_type): " value
				  valid=0
				  continue
				else
				  valid=1
				fi


			fi


			# validate the integer data type

			# Validate the integer data type
			if [[ $value != "" ]]; then
			    if [[ $data_type == "int" && ! $value =~ ^[0-9]+$ ]]; then
			        echo -e "\nInvalid data."
			        echo "This field is an integer. Enter a valid integer value."
			        read -p "$i. $colname ($data_type): " value
			        valid=0
			        continue
			    fi
			fi
			valid=1

		done


	

		
		if [[ $data == "" ]]
		then
			data=$value
		else
			data=$data$sep$value
		fi
		
	done

	echo -e $data >> $DATABASE_DIR/$db_name/$TBname

	echo "The data inserted successfully."
        Connect_Database

}

function Select_From_Table() {
    List_Tables
    echo "----- select ----- "
    read -p "Enter the table name: " table_name

    if ! name_validation "$table_name"; then
        echo "Invalid table name."
        Connect_Database
    fi

    if [[ ! -f "$DATABASE_DIR/$db_name/$table_name" ]]; then
        echo "Table '$table_name' does not exist."
        Connect_Database
    fi

     echo "Columns in '$table_name':"
     awk -F'|' '$1 != "" { print NR")", $1 }' "$DATABASE_DIR/$db_name/$table_name-meta.txt"


    read -p "Choose the number of the column: " column_number

    read -p "Enter data for column $column_number: " search_data

    # Get the name of the selected column
    selected_column=$(awk -F'|' -v col_num="$column_number" 'NR==col_num {print $1}' "$DATABASE_DIR/$db_name/$table_name-meta.txt")

    # Display rows that match the entered data
     matched_rows=$(awk -F'|' -v search="$search_data" -v col_num="$column_number" 'NR > 1 && $col_num == search {print}' "$DATABASE_DIR/$db_name/$table_name")
    
    if [[ -z "$matched_rows" ]]; then
        echo "No data found where '$selected_column' is '$search_data'."
    else
        echo "Rows in '$table_name' where '$selected_column' is '$search_data':"
        echo "$matched_rows"
    fi
    Connect_Database


}
function Delete_From_Table() {
    echo "----- Delete ----- "
    List_Tables
    read -p "Enter the table name: " table_name

    if ! name_validation "$table_name"; then
        echo "Invalid table name."
        Connect_Database
    fi

    if [[ ! -f "$DATABASE_DIR/$db_name/$table_name" ]]; then
        echo "Table '$table_name' does not exist."
        Connect_Database
    fi

    echo "Columns in '$table_name':"
    awk -F'|' '$1 != "" { print NR")", $1 }' "$DATABASE_DIR/$db_name/$table_name-meta.txt"

    read -p "Choose the number of the column: " column_number

    read -p "Enter data for column $column_number: " search_data

    # Get the name of the selected column
    selected_column=$(awk -F'|' -v col_num="$column_number" 'NR==col_num {print $1}' "$DATABASE_DIR/$db_name/$table_name-meta.txt")

    # Display rows that match the entered data along with their primary keys
    matched_rows=$(awk -F'|' -v search="$search_data" -v col_num="$column_number" 'NR > 1 && $col_num == search {print NR")", $0}' "$DATABASE_DIR/$db_name/$table_name")

    if [[ -z "$matched_rows" ]]; then
        echo "No data found where '$selected_column' is '$search_data'."
    else
        echo "Rows in '$table_name' where '$selected_column' is '$search_data':"
        echo "$matched_rows"

        # Prompt the user to choose the number of the row to delete
        read -p "Choose the number of the row to delete: " row_number

        # Validate the row number
        if ! [[ $row_number =~ ^[0-9]+$ ]] || [[ $row_number -lt 1 ]] || [[ $row_number -gt $(echo "$matched_rows" | wc -l) ]]; then
            echo "Invalid row number."
            Connect_Database
        fi

        # Extract the row number from the displayed list
        db_row_number=$(echo "$matched_rows" | awk -v row="$row_number" 'NR == row {print $1}' | tr -d ')')

        # Prompt for confirmation before deleting the row
        read -p "Are you sure you want to delete row $row_number? (y/n): " confirm_delete

        case $confirm_delete in
            y|Y)
                # Delete the corresponding row
                awk -v row="$db_row_number" 'NR != row' "$DATABASE_DIR/$db_name/$table_name" > "$DATABASE_DIR/$db_name/$table_name.tmp" && mv "$DATABASE_DIR/$db_name/$table_name.tmp" "$DATABASE_DIR/$db_name/$table_name"
                echo "Row $row_number deleted successfully." ;;
            n|N)
                echo "Deletion faild." ;;
            *)
                echo "Invalid choice. Deletion faild." ;;
        esac
    fi
    Connect_Database
}

function Update_Table() {
     echo "----- Update ----- "
     List_Tables
    read -p "Enter the table name: " table_name

    if ! name_validation "$table_name"; then
        echo "Invalid table name."
        Connect_Database
    fi

    if [[ ! -f "$DATABASE_DIR/$db_name/$table_name" ]]; then
        echo "Table '$table_name' does not exist."
        Connect_Database
    fi

    echo "Columns in '$table_name':"
    awk -F'|' '$1 != "" { print NR")", $1 }' "$DATABASE_DIR/$db_name/$table_name-meta.txt"

    read -p "Choose the number of the column to update: " column_number

    # Validate the column number
    if ! [[ $column_number =~ ^[0-9]+$ ]] || [[ $column_number -lt 1 ]] || [[ $column_number -gt $(awk -F'|' 'END{print NR}' "$DATABASE_DIR/$db_name/$table_name-meta.txt") ]]; then
        echo "Invalid column number."
        Connect_Database
    fi

    read -p "Enter data for column $column_number: " search_data

    # Get the name of the selected column
    selected_column=$(awk -F'|' -v col_num="$column_number" 'NR==col_num {print $1}' "$DATABASE_DIR/$db_name/$table_name-meta.txt")

    # Display rows that match the entered data along with their primary keys
    matched_rows=$(awk -F'|' -v search="$search_data" -v col_num="$column_number" 'NR > 1 && $col_num == search {print NR")", $0}' "$DATABASE_DIR/$db_name/$table_name")

    if [[ -z "$matched_rows" ]]; then
        echo "No data found where '$selected_column' is '$search_data'."
    else
        echo "Rows in '$table_name' where '$selected_column' is '$search_data':"
        echo "$matched_rows"

        # Prompt the user to choose the number of the row to update
        read -p "Choose the number of the row to update: " row_number

        # Validate the row number
        if ! [[ $row_number =~ ^[0-9]+$ ]] || [[ $row_number -lt 1 ]] || [[ $row_number -gt $(echo "$matched_rows" | wc -l) ]]; then
            echo "Invalid row number."
            Connect_Database
        fi

        # Extract the row number from the displayed list
        db_row_number=$(echo "$matched_rows" | awk -v row="$row_number" 'NR == row {print $1}' | tr -d ')')

        read -p "Enter the new value for column $selected_column: " new_value

        # Validate the new value
        if ! [[ -n "$new_value" ]]; then
            echo "Invalid new value. Please enter a non-empty value."
            Connect_Database
        fi

        # Read the entire table file, update the specific row, and write the modified content back
        awk -v row="$db_row_number" -v new_val="$new_value" -F'|' -v col_num="$column_number" '
            NR == row {
                split($0, arr, "|");
                arr[col_num] = new_val;
                $0 = "";
                for (i in arr) {
                    if (i == length(arr)) {
                        printf "%s\n", arr[i]
                    } else {
                        printf "%s|", arr[i]
                    }
                }
            }
            NR != row
        ' "$DATABASE_DIR/$db_name/$table_name" > "$DATABASE_DIR/$db_name/$table_name.tmp" \
        && mv "$DATABASE_DIR/$db_name/$table_name.tmp" "$DATABASE_DIR/$db_name/$table_name"

        echo "Row $row_number updated successfully."
    fi
    Connect_Database
}



 
function Create_Database() {
  read -p "Enter the name of the new database: " db_name

   if name_validation "$db_name" && ! [[ "$db_name" =~ [[:space:]] ]]; then
         if [ ! -d "$DATABASE_DIR" ]; then
         mkdir "$DATABASE_DIR"
         fi
	if [ -d "$DATABASE_DIR/$db_name" ]; then
  	echo "This database name already exists."
  	mainmenu
	else
  	mkdir $DATABASE_DIR/$db_name
  	echo "Your database is created successfully."
  	mainmenu
	fi
  else
	echo "Your database name shouldn't start with a number or include any symbols."
	mainmenu
  fi
}

function List_Databases() {
  echo "Existing databases:"
  for db_name in "$DATABASE_DIR"/*/; do
    echo "$(basename "$db_name")"
  done

}




function Connect_Database() {
  echo -e "\n"
  List_Databases
  read -p "Enter the database name to connect: " db_name

  if ! name_validation "$db_name"; then
	echo "Invalid database name. Please use only letters, numbers, and underscores."
	return
  fi

  db_path="$DATABASE_DIR/$db_name"

  if [ -d "$db_path" ]; then
	table_options=("Create_Table" "List_Tables" "Drop_Table" "Insert_into_Table" "Select_From_Table" "Delete_From_Table" "Update_Table" "back_to_mainmenu")

	echo -e "\n"
	echo "Please choose an option from 1 to 8"
	select table_com in "${table_options[@]}"; do
  
  	case $REPLY in
    	1) Create_Table ;;
    	2) List_Tables ;;
    	3) Drop_Table ;;
    	4) Insert_into_Table ;;
    	5) Select_From_Table ;;
    	6) Delete_From_Table ;;
    	7) Update_Table ;;
    	8) mainmenu ;;
    	*) echo "Invalid option" ;;
  	esac
	done
  else
	echo "This database does not exist."
        Connect_Database
  fi
}

function mainmenu() {
  echo -e "\nPlease choose an option from 1 to 5"

  options=("Create_Database" "List_Databases" "Connect_Database" "Drop_Database" "Exit")
 
  select com in "${options[@]}"; do
	case $REPLY in
  	1) Create_Database ;;
  	2) List_Databases ;;
  	3) Connect_Database ;;
  	4) Drop_Database ;;
  	5) exit  ;;
  	*) echo "Invalid option" ;;
	esac
  done
mainmenu
}

mainmenu

