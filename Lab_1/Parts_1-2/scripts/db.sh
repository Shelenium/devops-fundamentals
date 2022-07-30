#!/bin/bash

dbName=users.db
dbDir=../data/
dbPath="${dbDir}${dbName}"
backupDir="${dbDir}backups/"
noBackupMessage="No backup files found"

checkDir() {
    if [ ! -d $1 ]
    then 
        if [ $2 ]
        then mkdir $1
        else echo $noBackupMessage; exit
        fi
    fi
}

checkDb() {
    if [ ! -f $dbPath ]
    then 
        echo "There is no database yet. Create datadase? :"
        select yn in "Yes" "No"; do
            case $yn in
                Yes) checkDir $dbDir 0; touch $dbPath; break;;
                No) exit;;
            esac
        done
    fi
}

validation() {
    if [[ $1 =~ ^[A-Za-z_]+$ ]]
    then return 0;
    else 
        echo "$2 must contains lattin letters only. Please, try again."
        return 1;
    fi
}

add() {
    checkDb
    while true
    do
        read -p "Enter user name: " username
        validation $username "Name"
        if [[ $? == 0 ]]; then break; fi
    done

    while true
    do
        read -p  "Enter ${username} role: " role
        validation $role "Role"
        if [[ $? == 0  ]]; then break; fi
    done
    echo "${username}, ${role}" >> $dbPath 
    echo "User ${username} with role ${role} was succesfully added in the database."    
}

backup() {
    checkDb
    checkDir $backupDir 0
    cat $dbPath > "${backupDir}%$(date +%F)%-${dbName}.backup"
    echo "Database backup was successfully created $(date +%F)"
}

restore() {
    checkDb
    checkDir $backupDir
    latest=$(ls $backupDir -At | head -1)
    if [ latest ]
    then
        cat $backupDir$latest > $dbPath
        echo "Database was restored with ${latest}"
     else echo $noBackupMessage
     fi
}

list() {
    checkDb
    if [[ $1 == --inverse ]]
    then cat -n $dbPath | tac
    else cat -n $dbPath
    fi
}

find(){
    read -p "Enter user name for search: "  searchTerm
    result=$(grep -i -n -w  "${searchTerm}," $dbPath)
    if [[ -z $result ]]
    then
        echo "User not found"
    else 
        echo $result
    fi
}
    
help() {
    echo
    echo "Script works with database."
    echo "Syntax: db.sh [command] [optional param]"
    echo
    echo "List of commands:"
    echo 
    echo "add"
    echo "Add user with role in database. Latin letters allows only"
    echo
    echo "backup"
    echo "Create backup for darabase"
    echo
    echo "restore"
    echo "Restore database with latest backup"
    echo
    echo "find"
    echo "Find user by provided name"
    echo
    echo "list"
    echo "Show database content. Records appears from oldest to latest by default. To view records from latest to oldest apply optional parameter --reverse." 
}

case $1 in
    add) add;;
    backup) backup;;
    restore) restore;;
    find) find;;
    list) list $2;;
    help | '' | *)  help;;
esac
