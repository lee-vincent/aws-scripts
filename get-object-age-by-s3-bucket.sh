#! /bin/bash

print_help() {
    echo "  script prepends an age in days column to standard aws s3 ls output"
    echo Usage:
    echo -e "  get-object-age-by-s3-bucket s3-bucket-name [aws-profile]"
    echo -e "  get-object-age-by-s3-bucket -help"
    exit $1
}

if [ "$#" -eq 0 ] || [ "$1" == "-help" ]; then
    print_help 0
elif [[ ! -z "$2" ]]; then
    _profile="--profile $2"
fi

_bucket="$1"
_objects_file="/tmp/$_bucket-objects.txt"
_ages_file="/tmp/$_bucket-ages.txt"
_objects_ages_file="/tmp/$_bucket-objects-age.txt"
echo -n > $_objects_file

aws s3 ls $_bucket $_profile > $_objects_file

# put timestamps into a string variable
created_timestamps="$(cat $_objects_file | cut -d ' ' -f 1)"
# convert the variable to an array
created_timestamps_array=($created_timestamps)

for (( i=0; i<${#created_timestamps_array[@]}; i++ )); do
    datum1=`date -d "${created_timestamps_array[$i]}" "+%s"`
    datum2=`date "+%s"`
    diff=$(($datum2-$datum1))
    days=$(($diff/(60*60*24)))
    echo $days >> $_ages_file
done

paste $_ages_file $_objects_file > $_objects_ages_file
cat $_objects_ages_file
rm -rf $_objects_file
rm -rf $_ages_file
rm -rf $_objects_ages_file

exit 0