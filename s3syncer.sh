#!/bin/bash

#Written by John Fitzpatrick

#This script installs and config's s3cmd if not already installed
#It then parses the ('&' delimited) file 'accounts' to get RightScale Account Number (accountnum) and corresponding AWS Key & Secret Key
#Then uploads the contents of 'labfiles' directory to a bucket in this account called 'rsed-accountnum'

accountsfile=accounts

if ! which s3cmd 2>/dev/null ; then

echo "Installing S3 Tools"
yum -y install s3cmd

cat > /root/.s3cfg << EOF
[default]
access_key = $AWS_ACCESS_KEY_ID
bucket_location = US
cloudfront_host = cloudfront.amazonaws.com
cloudfront_resource = /2010-07-15/distribution
default_mime_type = binary/octet-stream
delete_removed = False
dry_run = False
encoding = ANSI_X3.4-1968
encrypt = False
follow_symlinks = False
force = False
get_continue = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase = jane101106
guess_mime_type = True
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
human_readable_sizes = False
list_md5 = False
log_target_prefix =
preserve_attrs = True
progress_meter = True
proxy_host =
proxy_port = 0
recursive = False
recv_chunk = 4096
reduced_redundancy = False
secret_key = $AWS_SECRET_ACCESS_KEY
send_chunk = 4096
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 300
urlencoding_mode = normal
use_https = False
verbosity = WARNING

EOF

else
 echo "s3cmd already installed"

#Read in the file accounts
while read line           
do           
 account=`echo -e "$line"| awk '{split($0,array,"&")} END{print array[1]}'`
 key=`echo -e "$line"| awk '{split($0,array,"&")} END{print array[2]}'`
 secret=`echo -e "$line"| awk '{split($0,array,"&")} END{print array[3]}'`    
 bucket=rsed-$account

 echo
 echo "Account is $account"
 echo "Key is $key"
 echo "Secret is $secret"
 echo "Bucket is $bucket"
 echo
 echo "Configuring s3cmd for account $account"
 cp /root/.s3cfg /root/.s3cfg.ORIG
 sed -i '/access_key/d' /root/.s3cfg
 sed -i '/secret_key/d' /root/.s3cfg
  
  cat >> /root/.s3cfg << EOF
access_key = $key
secret_key = $secret
EOF

 #Tester - Just to check keys are set correctly
 grep key /root/.s3cfg

 for file in `ls labfiles` 
  do

  echo
  echo "++++++START++++++"
  echo "*** Working on the following file"
  file labfiles/$file
  echo "** Uploading $file to S3 using this command"
  echo "** s3cmd -v put labfiles/$file s3://$bucket/$file"
  s3cmd -v put labfiles/$file s3://$bucket/$file
  echo "++++++END++++++"
  echo
  done

cp /root/.s3cfg.ORIG /root/.s3cfg
done <$accountsfile
fi

# To Do: Create the S3 Bucket Credential in the Account using the API
# http://reference.rightscale.com/api1.5/resources/ResourceCredentials.html

