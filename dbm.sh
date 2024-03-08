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
  read -p "Enter the table name: " TBname

  if ! name_validation "$TBname"; then
    mainmenu
  fi

  if [[ -f "$DATABASE_DIR/$db_name/$TBname" ]]; then
    echo_adv "Error: Table '$TBname' already exists in the current database."
    mainmenu
  fi


  read -p "Enter the number of columns: " TBcolnum

  counter=1
  sep="|"
  lsep="\n"
  col_names=()
  metadata=""
  PK=""

  while [ $counter -le $TBcolnum ]; do
    read -p "Enter the name of column $counter: " TBcolname

    if ! name_validation "$TBcolname"; then
      continue
    fi

    echo "Choose the data type for $TBcolname"
    select choice in "int" "string"; do
      case $REPLY in
        1) data_type="int"; break ;;
        2) data_type="string"; break ;;
        *) echo -e "\nInvalid option, please try again." ;;
      esac
    done

    col_names+=("$TBcolname")

    if [[ $metadata == "" ]]; then
      metadata=$TBcolname$sep$data_type
    else
      metadata=$metadata$lsep$TBcolname$sep$data_type
    fi

    let counter=$counter+1

  done


# Ask about the primary key using a while loop
echo "List of columns:"
index=1
for col_name in "${col_names[@]}"; do
  echo "$index. $col_name"
  let index=index+1
done

while true; do
  read -p "Choose a column number for the primary key (1-$TBcolnum): " col_choice_index

  if [[ $col_choice_index =~ ^[1-9]$|^1[0-9]$|^20$ ]] && [ $col_choice_index -le $TBcolnum ]; then
    col_choice=${col_names[$((col_choice_index-1))]}
    echo -e "\nSetting '$col_choice' as the primary key."
    PK="$col_choice"
    col_choice=$(echo "$col_choice" | cut -d'|' -f 1)
    sed -i "s/$col_choice|[^|]*|/$col_choice|int|PK|/" "$DATABASE_DIR/$db_name/$TBname-meta.txt"
    break
  else
    echo -e "\nInvalid choice, please enter a valid column number."
  fi
done

  metadata="$metadata$lsep the PrimaryKey is : $PK"
  # Join array elements into a string
  colnames=$(IFS=$sep; echo "${col_names[*]}")

  echo -e $metadata > "$DATABASE_DIR/$db_name/$TBname-meta.txt"
  echo -e $colnames > "$DATABASE_DIR/$db_name/$TBname"


  echo_adv "Table '$TBname' created successfully."
  mainmenu
}

function Drop_Table() {
  read -p "Enter the name of the table to be dropped: " table_name

  if name_validation "$table_name"; then
	table_path="$db_path/$table_name"
        meta_path="$db_path/$table_name-meta.txt"

	if [ -f "$table_path" ]; then
  	rm "$table_path"
  	echo "Table '$table_name' dropped successfully."

         if [ -f "$meta_path" ]; then
          rm "$meta_path"
        fi

	else
  	echo "Table '$table_name' does not exist."
	fi

  else
	echo "Invalid table name. Please use only letters, numbers, and underscores."
  fi
       
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

function Drop_Database() {
  read -p "Enter the database name that you want to dropp: " db_name
  if name_validation "$db_name"; then
    db_path="$DATABASE_DIR/$db_name"
    if [ -d "$db_path" ]; then
      rm -rf "$db_path" #powerful tool for recursively and forcefully removing directories and their contents.
      echo "Database '$db_name' dropped successfully."
    else
      echo "Database '$db_name' does not exist."
    fi
  else
    echo "Invalid database name. Please use only letters, numbers, and underscores."
  fi
}



function Connect_Database() {
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
  	echo -e "Choose an option from the menu"
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
  fi
}

function mainmenu() {
  echo -e "\nPlease choose an option from 1 to 5"

  options=("Create_Database" "List_Databases" "Connect_Database" "Drop_Database" "Exit")
  echo -e "Choose an option from the menu"
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
}

mainmenu

