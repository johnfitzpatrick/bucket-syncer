#!/bin/bash

echo "Install S3 Tools"
cd /root
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

while read line           
do           
    account=`echo -e "$line"| awk '{split($0,array,"&")} END{print array[1]}'`
    key=`echo -e "$line"| awk '{split($0,array,"&")} END{print array[2]}'`
    secret=`echo -e "$line"| awk '{split($0,array,"&")} END{print array[3]}'`
    
    bucket=rsed-$account
    echo "+++"

    echo "Account is $account"
    echo "Key is $key"
    echo "Secret is $secret"
    echo "Bucket is $bucket"

echo "Configuring s3cmd for the account"
cp /root/.s3cfg /root/.s3cfg.ORIG
sed '/access_key/d' /root/.s3cfg
sed '/secret_key/d' /root/.s3cfg
  
cat >> /root/.s3cfg << EOF
access_key = $key
secret_key = $secret
EOF

#Just to check keys are set correctly
grep key /root/.s3cfg

echo "Now the for loop!!!!!"

for file in `ls labfiles` 
do
echo
echo labfiles/$file
#See if its a real file
wc labfiles/$file

echo "running s3cmd for file"
echo "s3cmd -v put labfiles/$file s3://$bucket/$file"
   s3cmd -v put labfiles/$file s3://$bucket/$file

  done

cp /root/.s3cfg.ORIG /root/.s3cfg

done <accounts
