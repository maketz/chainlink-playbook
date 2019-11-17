# Amazon Elastic Beanstalk

This document focuses on deploying your node with Elastic
Beanstalk on AWS.

Elastic Beanstalk is a fully automated system for deploying your
Web applications without having to manually configure every aspect of
your app every time. You just update your configs, deploy, and switch
environments. Chainlink Node infrastructure is very similar to
a traditional web application so Elastic Beanstalk is a very powerful
tool for managing your node.

Before proceeding with this documentation, you should set your database
and VPC ready. More info on VPCs can be found on [vpc.md](./vpc.md)
and info on AWS databases can be found on
[rds_ropsten.md](./rds_ropsten.md).

Also, if you haven't used Elastic Beanstalk before, spinning up an
Elastic Beanstalk test application on AWS console is preferred,
so all default AWS configurations are created.

Make sure your preferred region has t2.micro instances available, for example:
- EU Frankfurt
- EU Ireland
- Canada (Central)
- All US regions

**IMPORTANT**

This document describes how to create single setup for AWS.
You should create separate setups for testing and production
environments. In practice this means, that each setup should have
their own dedicated resources:

- Database
- Custom VPC
- Custom Elastic Beanstalk application
  - 2 EC instances (1 for active node, 1 for failover)
- Private S3 bucket
- EB CLI configuration
- SSL Certificate

## Create IAM user

You'll need an IAM user to connect to Elastic Beanstalk without having
too wide permissions. This user is used to connect to AWS with
Programmatic Access.

1. Open IAM from AWS console dashboard.
2. Open up "Users" from left menu.
3. Click on "Add user":
    - User name: Whatever you like
    - Access type:
        - Both "Programmatic access" and AWS Management Console access
    - Password: Strong and long.
4. Click on "Next: Permissions"
5. On permissions page, click on Create group:
    - Group name: Give it a fitting name, like EB-access
    - Search for AWSElasticBeanstalkFullAccess and tick the checkbox
    - Click on "Create group"
6. Proceed with "Next: Tags". Skip tags with "Next: Review" for now.
7. Finish up with "Create user".
8. On success page, grab the Access key ID and Secret access key to
   notepad. You'll need them later on.
9. Click on "Close".

## EB CLI

### Create Elastic Beanstalk application

Before you start configuring EB CLI, you should have a EB application
ready, so you won't have to deal with it later, when setting up
EB CLI configurations.

1. Open up Elastic Beanstalk on AWS console.
2. Click on "Create new application"
3. Give it a fitting name and a description.
4. Finish with "Create".

### EB CLI Installation

EB CLI is used to programmatically access and manage your Elastic
Beanstalk applications. It uses Python as the base programming language,
so you can use it with any custom Python script you create to
automate or manage your application.

The EB CLI  is a bit tricky to install, since it differs for every OS.
You'll want at least Python 3.6.8 installed with pip package manager.
With both of those installed, you can install the eb cli package.
Check the official installation documentation from AWS:

https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install-linux.html
https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install-osx.html
https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install-windows.html

**IMPORTANT:** You'll also want the pip package manager

Verify your installation by running `eb --version`.

### Create node config folder and configure EB CLI

This section explains how to configure EB CLI configuration on a
specific location.

Official doc from AWS:
https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html

1. Create a folder for your EB Chainlink node configuration files. For
   Vagrant users I'd suggest to somewhere inside the shared folders, like
   `/vagrant/mynode` if you are using the default shared folder.
2. Navigate to the folder on your CLI tool and run `eb init`.
    - This will activate the interactive prompt for creating your Elastic Beanstalk
      configuration file `.elasticbeanstalk/config.yml`.
3. Select the region where your DB is located.
4. Select the application we created before
5. Select Docker as platform
6. Select yes for SSH.
7. You can change the keypair name, if you like
8. Give the SSH key a strong password.
9. Now you'll be prompted this password again, so the key pair can be
   pushed to AWS.

## HTTPS Certs for Load Balancer

Run the following:

```
openssl req -x509 -out  server.crt  -keyout server.key \
  -newkey rsa:2048 -nodes -sha256 -days 365 \
  -subj '/CN=localhost' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```

Keep the newly created `server.key` and  `server.crt` files available,
as you will soon need them.

Open AWS Certificate Manager and do the following:
1. If this is your first time using Certificate manager, choose
   Provision certificates->Get started.
2. There's a blue box on the top of the page with "Import a certificate".
   Click on it.
3. Copy the `server.crt` contents to Certificate body.
4. Copy the `server.key` contents to Certificate private key.
5. Click on Review and import.
6. Click on Import.

## Node credentials on S3

AWS offers very little wiggle room on how to securely store and use
your wallet password and API credentials without setting them to public
environment variables.

1st and more recommended one is to store your credentials on
AWS Secrets Manager and then fetch those credentials to your deployments
via Parameter store using a custom script with a programming language
of your choosing. Unfortunately that Secrets Manager is not a free
service (only 1 month trial) and creating that script is a bit of a
hassle. You should keep this option in mind when creating a production
environment.

2nd option is to create credential files on S3 and this is fully
supported by free tier. This document will cover the S3 case, as
the focus is on the free services for this doc.

First we'll create log-bucket to store all kinds of log data.

1. Open up S3 on AWS management console.
2. Click on "Create bucket"
3. Give it a fitting name like "my-node-nickname-logs". Next.
4. Add a tag like "node-nickname"/"logs". Next.
5. Keep the "Block all public access checked. We do not need anyone
   going through the logs without explicit access. Set the
   "Manage system permissions" to "Grant Amazon S3 Log Delivery group
   write access to this bucket". It's okay to allow Amazon write log
   files to this bucket. Next.
6. Create bucket.

Okay, then create the credentials bucket.

1. Click on "Create bucket"
2. Give it a fitting name like "my-node-nickname-secrets". Next.
3. Click on "Server access logging"
    - Choose the log-bucket as target bucket
    - Give it a prefix like "secrets-log"
4. Add a tag like "node-nickname"/"secrets".
5. Check the "Default encryption" box and you can leave it at AES-256,
   if you don't have multiple users or projects in using S3.
    - This doc will not cover KMS, but if you need to limit access
      and secure your credentials from other projects/people using the
      same AWS, you should use KMS instead.
6. Click Next.
7. For permissions, keep the "Block all public access". Next.
8. Create bucket.

Now, create your nodes api keys to following files in following formats:

.api

```
your@email.com
yourpassword
```

And same for the wallet password file:

.password

```
yourwalletpassword
```

We'll also upload the node variables in `chainlink.toml`, which will
also work like the `.env` file mentioned in official docs. Difference is,
that the .toml file contents will not be inserted as environmental
variables, because the node can read all the configuration from
this .toml file. Also we'll leave out the `ROOT` folder variable,
because that HAS to be an environmental variable (which will be set
with `.ebextensions` config files later).

**NOTE:** Dashes and double quotes around string are required.

chainlink.toml (Below is for ropsten. Set DATABASE_URL and ETH_URL yourself before upload!)
```
LOG_LEVEL = "debug"
ETH_CHAIN_ID = 3
MIN_OUTGOING_CONFIRMATIONS = 2
LINK_CONTRACT_ADDRESS = "0x20fe562d797a42dcb3399062ae9546cd06f63280"
ALLOW_ORIGINS = "*"
TLS_CERT_PATH = "/chainlink/tls/server.crt"
TLS_KEY_PATH = "/chainlink/tls/server.key"
DATABASE_TIMEOUT = 0
DATABASE_URL = "postgresql://YOUR_DB_USER:YOUR_USER_PASS@AMAZON_DB_ADDRESS:AMAZON_DB_PORT/DB_NAME"
ETH_URL = "YOU_SHOULD_CHANGE_THIS"
```

Providing these configuration variables via S3 saves you from exposing
the database connection string to AWS default logs.

ALSO, upload your server.crt and server.key to the secrets bucket.

---

After you are done, upload those file to the secrets-bucket. Those
files should be automatically encrypted by your bucket, if you enabled
the encryption.

## Policy for Elastic Beanstalk

Elastic Beanstalk will require an IAM Role for accessing the credentials
bucket created above. First we need to create a bucket policy.

1. Open S3 so you can look up names for the new policy later.
2. Next open IAM management and then go to Policies. Create Policy.
3. Choose S3 as the service.
4. Choose read for accesss level and open the read menu.
5. Untick all except GetObject.
5. Click on resources and click on "Add ARN" for the object.
6. Write your bucket name from S3 to the Bucket name field. Then write
   the `.api` for Object name. This will grant this policy access
   to the `.api` file.
7. Repeat the Add ARN process for `.password`, `.env`, `server.crt` and
   `server.key` files.
8. Move to next by clicking on Review.
9. Give your policy a fitting name like `NodeCredentialsAccess` and
   description "Gives access to node credentials on S3".
10. Create the policy.

Then you should attach this policy to an AWS role.

1. Open Roles on IAM.
2. Click on `aws-elasticbeanstalk-ec2-role`.
    - If you don't see this role, you should open Elastic Beanstalk,
      create a demo application using the Getting started guide for
      docker and come back then. AWS should have created the role after that.
3. Click on Attach policies.
4. Search for your newly created Node-policy, and check it.
5. Click on Attach policy.

Your default Elastic Beanstalk EC2 role should now have access to your
secret objects in S3 secrets bucket.

## Creating the node

If you have your database up and running and S3 bucket configured, you
should be able to create your Elastic Beanstalk configuration files.
All of the previous work will be pieced together in the following
steps.

**IMPORTANT:** If you haven't run elastic beanstalk on a test project
yet, you should really do so before proceeding. We need the default
Elastic Beanstalk bucket for the following configs. Spin up a test
project on Elastic Beanstalk using the AWS console and come back after
that. You can confirm that you have a default bucket by looking up
S3 and seeing that you have `elasticbeanstalk-some-region-XXXX` bucket
created.

1. Open up the directory, where you opened up EB CLI.
2. Create a file called `Dockerrun.aws.json` and insert the following:

```
{
    "AWSEBDockerrunVersion": "1",
    "Image": {
        "Name": "smartcontract/chainlink:latest"
    },
    "Ports": [
        {"ContainerPort": "6688"}
    ],
    "Volumes": [
        {
            "HostDirectory": "/var/.chainlink-ropsten",
            "ContainerDirectory": "/chainlink"
        }
    ],
    "Entrypoint": "chainlink",
    "Command": "local node -p /chainlink/.password -a /chainlink/.api"
}
```

3. Create a folder called `.eb-extensions` and create `00-chainlink.config`
   file with following contents:

```
commands:
  00_create_dir:
    command: mkdir -p /var/.chainlink-ropsten

Resources:
  AWSEBAutoScalingGroup:
    Metadata:
      AWS::CloudFormation::Authentication:
        S3Auth:
          type: "s3"
          buckets: ["your-secrets-bucket-name"]
          roleName:
            "Fn::GetOptionSetting":
              Namespace: "aws:autoscaling:launchconfiguration"
              OptionName: "IamInstanceProfile"
              DefaultValue: "aws-elasticbeanstalk-ec2-role"

files:
    # Create API configuration
    '/var/.chainlink-ropsten/.api':
        mode: '000644'
        owner: root
        group: root
        authentication: "S3Auth"
        source: YOUR_S3_API_FILE_ADDRESS

    # Enter wallet password
    '/var/.chainlink-ropsten/.password':
        mode: '000644'
        owner: root
        group: root
        authentication: "S3Auth"
        source: YOUR_S3_PASSWORD_FILE_ADDRESS

    # Create env file
    '/var/.chainlink-ropsten/chainlink.toml':
        mode: '000644'
        owner: root
        group: root
        authentication: "S3Auth"
        source: YOUR_CHAINLINK_TOML_FILE_ADDRESS

    # Supply node with cert
    '/var/.chainlink-ropsten/tls/server.crt':
        mode: '000644'
        owner: root
        group: root
        authentication: "S3Auth"
        source: YOUR_S3_SERVER_CERT_FILE_ADDRESS

    # Supply node with cert key
    '/var/.chainlink-ropsten/tls/server.key':
        mode: '000644'
        owner: root
        group: root
        authentication: "S3Auth"
        source: YOUR_S3_SERVER_KEY_FILE_ADDRESS

option_settings:
    - option_name: ROOT
      value: /chainlink
```

**NOTE:** The config in this documentation doesn't actually execute
HTTPS at the instance, so the certs for the node may be unnecessary.

4. Modify the `00-chainlink.config` file:
    - Change the `your-secrets-bucket-name` to whatever you named your
      secrets bucket in S3
    - Change ALL of the sources on `YOUR_S3_*` values to object urls
      from S3. You can copy the addresses from S3 by navigating to your
      file in S3 and copying the "Object URL" from the Overview-tab.
    - Note, that the configuration is setting environment variable
      `ROOT` here with the `option_settings`. This is why `chainlink.toml`
      doesn't need that configuration.

5. You need to allow access to DB with a security group, so create a
   `securitygroup.config` to your `.ebextensions` folder with following
   contents (remember to change the values accordingly):

```
option_settings:
  aws:ec2:vpc:
    VPCId: "YOUR_VPC_ID"
    Subnets: "YOUR_PUBLIC_SUBNET_ID"
    ELBSubnets: "YOUR_PUBLIC_SUBNET_ID"
    AssociatePublicIpAddress: true
  aws:elb:loadbalancer:
    SecurityGroups: "YOUR_PUBLIC_SECURITY_GROUP_ID"
    ManagedSecurityGroup: "YOUR_PUBLIC_SECURITY_GROUP_ID"
  aws:autoscaling:launchconfiguration:
    SecurityGroups: "YOUR_PUBLIC_SECURITY_GROUP_ID"
```

6. It's better to have forced HTTPS upgrade on HTTP requests, so create
   following files inside `.ebextensions`:

https-instancecert-docker-sc.config (remember to change S3 addresses)
```
Resources:
  # Use instance profile to authenticate to S3 bucket that contains the private key
  AWSEBAutoScalingGroup:
    Metadata:
      AWS::CloudFormation::Authentication:
        S3Auth:
          type: "s3"
          roleName:
            "Fn::GetOptionSetting":
              Namespace: "aws:autoscaling:launchconfiguration"
              OptionName: "IamInstanceProfile"
              DefaultValue: "aws-elasticbeanstalk-ec2-role"

Resources:
  sslSecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupId: {"Fn::GetAtt" : ["AWSEBSecurityGroup", "GroupId"]}
      IpProtocol: tcp
      ToPort: 443
      FromPort: 443
      CidrIp: 0.0.0.0/0

files:
  /etc/pki/tls/certs/server.crt:
    mode: "000400"
    owner: root
    group: root
    authentication: "S3Auth"
    source: YOUR_S3_SERVER_CERT_FILE_ADDRESS

  /etc/pki/tls/certs/server.key:
    mode: "000400"
    owner: root
    group: root
    authentication: "S3Auth"
    source: YOUR_S3_SERVER_KEY_FILE_ADDRESS

  /etc/nginx/conf.d/https.conf:
    mode: "000644"
    owner: root
    group: root
    content: |
      # HTTPS Server

      server {
        listen 443 ssl;
        server_name localhost;

        ssl_certificate /etc/pki/tls/certs/server.crt;
        ssl_certificate_key /etc/pki/tls/certs/server.key;

        ssl_session_timeout 5m;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;

        location / {
          proxy_pass http://docker;
          proxy_http_version 1.1;

          proxy_set_header Connection "";
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
        }
      }

container_commands:
  01restart_nginx:
    command: "service nginx restart"
    ignoreErrors: true
```

https-lb-passthrough.config
```
option_settings:
  aws:elb:listener:443:
    ListenerProtocol: TCP
    InstancePort: 443
    InstanceProtocol: TCP
```

https-redirect-docker-sc.config
```
###################################################################################################
#### Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
####
#### Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file
#### except in compliance with the License. A copy of the License is located at
####
####     http://aws.amazon.com/apache2.0/
####
#### or in the "license" file accompanying this file. This file is distributed on an "AS IS"
#### BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#### License for the specific language governing permissions and limitations under the License.
###################################################################################################

###################################################################################################
#### This configuration file configures Nginx for Single Docker environments to redirect HTTP
#### requests on port 80 to HTTPS on port 443 after you have configured your environment to support
#### HTTPS connections:
####
#### Configuring Your Elastic Beanstalk Environment's Load Balancer to Terminate HTTPS:
####  http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/configuring-https-elb.html
####
#### Terminating HTTPS on EC2 Instances Running Docker:
####  http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/https-singleinstance-docker.html
###################################################################################################

files:
   "/etc/nginx/sites-available/elasticbeanstalk-nginx-docker-proxy.conf":
     owner: root
     group: root
     mode: "000644"
     content: |
       map $http_upgrade $connection_upgrade {
           default        "upgrade";
           ""            "";
       }

       server {
           listen 80;

           gzip on;
           gzip_comp_level 4;
           gzip_types text/html text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

           if ($time_iso8601 ~ "^(\d{4})-(\d{2})-(\d{2})T(\d{2})") {
               set $year $1;
               set $month $2;
               set $day $3;
               set $hour $4;
           }
           access_log /var/log/nginx/healthd/application.log.$year-$month-$day-$hour healthd;

           access_log    /var/log/nginx/access.log;

           location / {
               set $redirect 0;
               if ($http_x_forwarded_proto != "https") {
                 set $redirect 1;
               }
               if ($http_user_agent ~* "ELB-HealthChecker") {
                 set $redirect 0;
               }
               if ($redirect = 1) {
                 return 301 https://$host$request_uri;
               }

               proxy_pass            http://docker;
               proxy_http_version    1.1;

               proxy_set_header    Connection            $connection_upgrade;
               proxy_set_header    Upgrade                $http_upgrade;
               proxy_set_header    Host                $host;
               proxy_set_header    X-Real-IP            $remote_addr;
               proxy_set_header    X-Forwarded-For        $proxy_add_x_forwarded_for;
           }
       }
```

**NOTE:** Above configuration executes HTTPS on load balancer, not the
node.

Okay, time to test the environment creation.

1. Open the folder location with your CLI (where you
   created `Dockerrun.aws.json`).
2. Run command `eb create my-test-environment`. EB CLI will start
   creating and deploying your node on Elastic Beanstalk. This operation
   will take some time.
3. Open up Elastic Beanstalk on AWS console after it's finished.
4. You should see your environment as a green box on the EB console.
    - If it is red, it means something went wrong. You can see the main
      error message by clicking on the environment and looking at logs
      on bottom of the "Events" section.
        - For more information, you can open the "Logs" from left menu.
          Then click on "Request logs" dropdown and choose
          "Last 100 Lines". Then click on Download link for the provided
          log file. You can try figuring out what went wrong from these
          log files better.
    - If it gray, you probably have something wrong with your
      configuration files. Check the error message from EB CLI for more
      information.
5. Time to visit your node GUI. Click on the green environment box to
   open environment management page and then open up the URL from top
   of the page. You should be able to log in to your Node's GUI from
   here.
    - If you get "502 Bad Gateway" error, there is something wrong with
      your database connection.
        - Check that your security groups allow inbound traffic.
        - Check that your node is set to the DB security group.
          You can check this from environment management tab on EB
          console from Configuration->Instances. Your DB security group
          should be listed on "EC2 security groups"
    - If you can't login with your `.api` credentials, there is probably
      something wrong with your database connection string. Check that
      you can use `psql` to connect to your database with the same
      credentials you have on your DB connection string.
      - If you can use the DB credentials and you are sure the string
        is correct, check that your `chainlink.toml` is properly
        formatted with spaces around `=` and double quotes around
        strings.
    - If you get a 403 or some access denied error from browser, you
      need to add your own IP.

Your single node setup should now be ready for usage. If you want to
create a failover node, just spin up another environment with `eb create`.

## Failover

Free tier offers 750 hours of t2.micro usage each month, so running
a failover 24/7 will cost you. The 750 hours is enough for 1 EC2
instance running 24/7 each month.

Basic failover setup:
1. Boot up first node `eb create node1`
2. Boot up second node `eb create node2`
3. When updating, terminate the node which doesn't have a DB lock
  - You can use SSH to connect to your EC2 instance or look up the
    logs to see which node has lock on DB
4. Create updated node with `eb create updated_node1`
  - One naming scheme could be datestamping your environments like
    `eb create mainnode_yyyymmdd` and `eb create secondnode_yyyymmdd`