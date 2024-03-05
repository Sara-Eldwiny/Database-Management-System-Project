#!/bin/bash



function name_validation {
  if [[  ! $1 =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo_adv "Invalid name. Names should not be empty, and must start with a letter or underscore, and only contain letters, numbers, or underscores without any spaces."
    return 1
  fi
  return 0
}



function Create_Database() {

read -p "Enter the name of the new database :" db_name
if name_validation $db_name;
 then
 if [ -d "./$db_name" ];
  then
  echo "this database name is already exist"
  else 
  mkdir ./$db_name 
  echo "your database is created successfully"
  fi
else 
 echo "your database name shouldn't start with number , or include any symbols "
fi
}
function Connect_Database() {

read -p "Enter the database name to connect: " db_name

  if ! name_validation "$db_name"; then
      echo "Invalid database name. Please use only letters, numbers, and underscores."
      return
  fi

db_path="./$db_name"



if [ -d "$db_path" ]; then

table_options=( "Create_Table" "List_Tables" "Drop_Table" "Insert_into_Table" "Select_From_Table" "Delete_From_Table" "Update_Table" "back_to_mainmenu")

echo -e "\n"
echo "Please choose an option from 1 to 8"
select table_com in "${table_options[@]}"

    do
    echo -e "choose an option from menu"
    case $REPLY in
        1)
            Create_Table
            ;;
        2)
            List_Tables
            ;;
        3)
            Drop_Table
            ;;
        4)
            Insert_into_Table
            ;;
        5)
            Select_From_Table
            ;;
        6)
            Delete_From_Table
            ;;
        7)
            Update_Table
            ;;
        8)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done

else
	echo "this database not exist"
fi
	

}

echo -e "\n"
echo "Please choose an option from 1 to 9"

options=("Create_Database" "List_Databases" "Connect_Database" "Drop_Database" "Exit")
echo -e "choose an option from menu"
select com in "${options[@]}" 
do

    case $REPLY in
        1)
            Create_Database
            ;;
        2)
            List_Databases
            ;;
        3)
            Connect_Database
            ;;
        4)
            Drop_Database
            ;;
        5)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
