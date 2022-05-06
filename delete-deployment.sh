#!/bin/bash
#We need to install gitbash and github cli for the gh commands to work
# Deployment name format: appname-pr-prnumber-node-pr-prnumber, ex: test-pr-20-node-pr-20
FOLDER=
URL=GitHub Application Repository URL

#Check the repository is exist or not
if [ ! -d "$FOLDER" ];then
 git clone $URL $FOLDER
else
 cd "$FOLDER"
 git pull $URL
fi

#Check the merged PR requests from GitHub and save in myfile2.txt file
cd apprepofolder
gh pr list --state "closed" | grep -i Merged > prlogs.txt
awk '{print $1}' prlogs.txt > myfile2.txt

#List the K8s Deployment PRs from cluster and save in myfile1.txt file
kubectl get deployment -o go-template --template '{{range .items}}{{.metadata.name}} {{.metadata.creationTimestamp}}{{"\n"}}{{end}}' -n namespacename | awk '$2 <= "'$(date -d'now-1 hours' -Ins --utc | sed 's/+0000/Z/')'" { print $1 }' | grep -i appname-pr-* | cut -d "-" -f3 > myfile1.txt

#List out the matched PRs from both the files and delete the deployment if the age is more than 1 hour
filename=myfile1.txt
LINES=$(cat $filename)

for LINE in $LINES
do
grep $LINE myfile2.txt
if [ $? = 0 ]
then
echo "appname-pr-"$LINE"-node-pr-"$LINE > final_match.txt 
var=$(cat final_match.txt)
echo "$var"
#kubectl get deployment $var -n namespacename
kubectl delete deployment $var -n namespacename
else 
echo "value not found"
fi
done

#Deleting the cloned repo
cd ..
rm -rf apprepofolder
echo "repo deleted"
