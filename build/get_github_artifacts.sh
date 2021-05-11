#!/bin/bash

EXPECTED_ARGS=2
E_BADARGS=65

if [ $# -lt $EXPECTED_ARGS ]
then
    clear
    #echo "Usage: ./`basename $0` {run_id} {password_token}"
    echo "Usage: $0 {run_id} {password_token}"
    echo "Where: [run_id] = ########"
    echo "       [password_token] = Users Github password or token"
    echo
    echo "Example:"
    echo
    #echo "./`basename $0` 832176399 b133llcd44faf86966567f3gb3c23733943a3456"
    echo "$0 832176399 b133llcd44faf86966567f3gb3c23733943a3456"
    exit $E_BADARGS
fi

run_id=$1
password_token=$2

# Use the run id to get a list of artifacts
curl -H "Authorization: token ${password_token}" -sL \
https://api.github.com/repos/SKuhlmanns/steves-test-repo/actions/runs/${run_id}/artifacts \
-o artifacts.txt
# Strip out the name and id from the curl output
cat artifacts.txt | grep '"name":' | cut -d'"' -f4 > name.txt
cat artifacts.txt | grep '"id":' | cut -d':' -f2 | cut -d"," -f1 > id.txt
paste -d "" name.txt id.txt > artifacts.lst
rm id.txt name.txt artifacts.txt
cat artifacts.lst
# Use the artifact id download artifacts, unzip them and remove the zip file
while IFS= read -r line; do
    filename=`echo $line | cut -d" " -f1`
    artifact_id=`echo $line | cut -d" " -f2`
    # Download artifacts, except the file with the run id
    if [[ "${filename}" != *"run_id-"* ]]; then
        curl -H "Authorization: token ${password_token}" -sLJO \
https://api.github.com/repos/SKuhlmanns/steves-test-repo/actions/artifacts/${artifact_id}/zip
        unzip ${filename}.zip
        rm ${filename}.zip
    fi
done < artifacts.lst
rm artifacts.lst
