#!/bin/bash


#colors
alert=$'\e[1;31m'
info=$'\e[1;33m'
end=$'\e[0m'

BRANCH=main
OWNER=devops
POLL=no
BUILD_CONFIGURATION=testing
REPOSITORY=devops-repo
PIPELINE="pipeline.json"


inputUserData() {
    read -e -p "Please, enter json pipeline name: " -i "$PIPELINE"  pipeline
    if [ ! -f $pipeline ]
    then echo "${pipeline} doesn't exist."; exit 1
    else
        fields="Branch Owner PollForSourceChanges Repo"
        for field in $fields
        do 
            value=$(jq "..|.${field}? | select(. !=null)" $pipeline)
            if [[ $value == "" ]]
            then echo "${pipeline} has invalid configuration format. There is no ${field} field"; exit 1
            fi
        done
    fi

    read -e -p "Please, enter BUILD_CONFIGURATION: " -i "$BUILD_CONFIGURATION" build

    read -e -p "Enter a GitHub owner/account: " -i "$OWNER" owner

    read -e -p "Enter a GitHub repository name: " -i "$REPOSITORY" repository
    
    read -e -p "Enter a GitHub branch name: " -i "$BRANCH" branch

    read -e -p "Do you want the pipeline to poll for changes (yes/no)?: " -i "$POLL" pollForSourceChanges
    if [[ $pollForSourceChanges == 'no' ]]
    then pollForSourceChanges=false
    else pollForSourceChanges=true
    fi
}

type jq > /dev/null 2>&1
exitCode=$?
if [[ $exitCode != 0 ]]
then
   printf "    ${alert}jq not found!\n${end}"
   printf "    Run ${info}sudo apt install jq${end} for Ubuntu.\n"
   printf "    Visit ${info}https://stedolan.github.io/jq/download/'${end} for other instullation guides.\n"
   exit
else inputUserData
fi


resultFile="$(date +%F)-$pipeline"
result=$(jq "del(.metadata) | .pipeline.version += 1 | .pipeline.stages[0].actions[0].configuration.Branch = \"$branch\" | .pipeline.stages[0].actions[0].configuration.Owner = \"$owner\" | .pipeline.stages[0].actions[0].configuration.PollForSourceChanges = \"$pollForSourceChanges\" | .pipeline.stages[0].actions[0].configuration.Repo = \"repository\"" $pipeline)

echo $result | jq > $resultFile 

jq "(.. | .EnvironmentVariables[]? | select(.values | contains(\"BUILD_CONFIGURATION\"))).value |= \"$build\"" $resultFile > $resultFile
