#!/bin/bash

# Use this script to download and unzip github artifacts by run d.

EXPECTED_ARGS=2
E_BADARGS=65

if [ $# -lt $EXPECTED_ARGS ]
then
    clear
    echo "Usage: $0 {run_id} {password_token} '[artifact_list]'"
    echo "Where: [run_id] = ########"
    echo "       [password_token] = Users Github password or token"
    echo "       [artifact_list] = space separated list of artifacts between quotes"
    echo
    echo "Examples:"
    echo
    echo "$0 832176399 b133llcd44faf86966567f3gb3c23733943a3456"
    echo "$0 832176399 b133llcd44faf86966567f3gb3c23733943a3456 'version-num- version-'"
    exit $E_BADARGS
fi

run_id=${1}
password_token=${2}
artifact_list=${3}
build_dir=`dirname $0`

# Check to see if a artifact_list has been entered by the user.
# If not, use the github artifacts list in the build directory.
if [ -z "${artifact_list}" ]; then
    artifact_list=`cat ${build_dir}/github_artifact.lst`
fi

# Use the run id to get a list of artifacts to download from github.
rm -f artifacts.lst
curl -H "Authorization: token ${password_token}" -sL \
https://api.github.com/repos/SKuhlmanns/steves-test-repo/actions/runs/${run_id}/artifacts \
-o artifacts.txt

# Strip out the name and id from the curl output; generate an artifact list file.
cat artifacts.txt | grep '"name":' | cut -d'"' -f4 > name.txt
cat artifacts.txt | grep '"id":' | cut -d':' -f2 | cut -d"," -f1 > id.txt
paste -d "" name.txt id.txt > artifacts.lst
rm id.txt name.txt artifacts.txt
cat artifacts.lst

# Use the artifact list file and to download artifact zip files.
for artifact_name in ${artifact_list}
do
    while IFS= read -r line; do
        filename=`echo $line | cut -d" " -f1`
        artifact_id=`echo $line | cut -d" " -f2`
        # Download the artifact if it does not already exist
        if [ ! -f ${filename}.zip ]; then
            if [[ "${filename}" == *"${artifact_name}"* ]]; then
                curl -H "Authorization: token ${password_token}" -sLJO \
https://api.github.com/repos/SKuhlmanns/steves-test-repo/actions/artifacts/${artifact_id}/zip
            fi
        fi
    done < artifacts.lst
done

# Unzip and delete the downloaded zip files.
while IFS= read -r line; do
    filename=`echo $line | cut -d" " -f1`
    if [ -f ${filename}.zip ]; then
        unzip -u ${filename}.zip
        rm ${filename}.zip
    fi
done < artifacts.lst

# Delete the generated artifacts list file.
rm -f artifacts.lst
