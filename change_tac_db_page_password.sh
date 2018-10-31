#!/bin/bash

######
# This script changing the Talend database config page password.
# Wrote by Ilya Ulis, ilyaul@matribi.co.il
# Ver. 0.1 (04.01.2018)
#####

help() {
	echo "Usage: $0 [OPTION]..."
	echo "Change the Talend database config page password."
	echo
	echo "Options:"
	echo -e "\t -f, --file \t\t <TAC configuration file>\n"
}

while [[ -n $1 ]]; do
	case $1 in
		-h|--help)
			help
			exit 0
			;;
		-f|--file)
			if [[ -z $2 ]]; then
				echo "ERROR! Argument $1 should be provided by file name."
				exit 1
			fi
			password_file=$2
			shift 2
			;;
		*)
			echo -e "\n ERROR! Wrong argument \"$1\" \n"
			help
			exit 1
			;;
	esac
done

if [[ -z $password_file ]]; then
	password_file=/opt/Talend-6.4.1/tac/apache-tomcat/webapps/org.talend.administrator/WEB-INF/classes/configuration.properties
fi

if [[ ! -w $password_file ]]; then
	echo "ERROR! File $password_file not exist or there is no enough permissions to change it."
	exit 1
fi

current_pass=$(grep ^'database.config.password=' $password_file | awk -F'=' '{print $2}' | awk -F',' '{print $1}')

unset pass
until [[ $pass == "true" ]]; do
	read -s -p "Type the current password: " check_current_pass && echo 
	if [[ $(echo -n $check_current_pass | sha256sum | awk '{print $1}' | cut -c-32) != $current_pass ]]; then
		echo "ERROR! Inserted password not match the current one"
		echo "Try again."
	else
		pass="true"
	fi
done

unset pass
until [[ $pass == "true" ]]; do
	read -s -p "Type new password: " new_pass && echo
	read -s -p "Type new password again: " new_pass_2 && echo

	if [[ $new_pass != $new_pass_2 ]]; then
		echo "ERROR! The password not match"
		echo "Try again."
	else
		pass="true"
	fi
done

sed -i "s/^database.config.password=.*/database.config.password=$(echo -n $new_pass | sha256sum | awk '{print $1}' | cut -c-32),Encrypt/g" $password_file

if [[ $? -ne 0 ]]; then
	echo "ERROR! Password has not changed"
	exit 1
else
	echo "Password successfully changed"
	echo "To apply the new password, tomcat should be restarted."
fi

#EOF
