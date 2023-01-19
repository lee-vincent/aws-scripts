#! /bin/bash

set -eo pipefail

trap cleanup EXIT

cleanup() {
    exit_code=$?
    if [[ ${exit_code} -eq 252 ]]; then
       echo -e "\t***error: did you set your aws region and profile correctly?***"
     elif [[ ${exit_code} -eq 255 ]]; then
       echo -e "  ***error: did you set your aws region and profile correctly?***"
    fi
    if [ "$exit_code" -ne "0" ]; then
        print_help $exit_code
    fi
}

print_help() {
    echo Usage:
    echo -e "  get-all-ebs region|help [aws-profile]"
    exit $1
}

if [ "$#" -eq 0 ] || [ "$1" == "help" ]; then
    print_help 0
elif [[ ! -z "$2" ]]; then
    _profile="--profile $2"
fi

_region="$1"

# get all instance ids, their AZ, volumes and volume sizes saved to /tmp/instances-$_region.txt
# us-east-1a      i-0259717a7d755a9c8     vol-0d1b71c3a58d8ef82   8
# us-east-1a      i-0259717a7d755a9c8     vol-06cf3217eb695745a   8
# us-east-1a      i-0259717a7d755a9c8     vol-0b81025312a0ededb   5
# us-east-1a      i-04168adbd4456da39     vol-089522b279fbe12d5   5
# us-east-1a      i-04168adbd4456da39     vol-0a7b9c4f4bb34fe73   8
# us-east-1a      i-04168adbd4456da39     vol-090d2168c63491af6   8
aws ec2 describe-volumes --output text --query 'Volumes[*].[AvailabilityZone, Attachments[0].InstanceId, VolumeId, Size]' $_profile --region $_region > /tmp/instances-$_region.txt
# put all the instance ids into a string variable
aws_instances="$(cat /tmp/instances.txt | cut -f 2)"

# convert the string variable to an array
aws_instances_array=($aws_instances)

# get the VpcId and SubnetId for each instance id in the aws_instances_array saved to /tmp/instances_vpc_subnet-$_region.txt
echo -n > /tmp/instances_vpc_subnet-$_region.txt # just make sure it is empty since next command appends using >> redirection
for (( i=0; i<${#aws_instances_array[@]}; i++ )); do aws ec2 describe-instances --instance-ids "${aws_instances_array[$i]}" --output text --query 'Reservations[*].Instances[*].[VpcId,SubnetId]' $_profile --region $_region >> /tmp/instances_vpc_subnet-$_region.txt; done

# combine the columns from /tmp/instances-$_region.txt and /tmp/instances_vpc_subnet-$_region.txt into /tmp/ebs-volume-details-$_region.txt
paste /tmp/instances-$_region.txt /tmp/instances_vpc_subnet-$_region.txt > /tmp/ebs-volume-details-$_region.txt

exit 0