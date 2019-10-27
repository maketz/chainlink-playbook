# Custom VPC

Having a custom VPC will let you have more control over Elastic
Beanstalk security rules, such as default open ports and allowed IP
addresses (a.k.a. Security Groups).

Official docs on how to create a VPC:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Tutorials.WebServerDB.CreateVPC.html

## Create VPC

1. Open AWS console and navigate to VPC Dashboard
2. On left, make sure you have "Your VPCs" open and then click on
   Create VPC.
3. Give it a fitting name like "ChainlinkTestVPC" or "chainlink-test-vpc"
  - Sidenote: There is no general rule for AWS naming usually, but often
    times the dashed version is preferred for IDs/tags and CamelCase for
    names.
4. For IPv4 CIRD block use `10.0.0.0/16`. It should give us enough
   addresses for a lifetime or two.
5. Tenancy can be left as default.
6. Click on Create.
7. Click your newly created VPC active, then open actions menu and
   click on edit DNS hostnames.
8. Enable DNS hostnames and click on Save.

## Create VPC subnets

First you'll create the public network.

1. After creating VPC, click on Subnets on the left menu.
2. Start creating a subnet with Create subnet.
3. Give it a fitting name, like "ChainlinkPublicSubnet"
4. Choose your newly created VPC for the subnetwork.
5. For availability zone, pick one and remember it
  - You can always create more subnets for each availability zones later
6. For IPv4 CIDR block, you can use `10.0.0.0/24`.
7. Click on Create.

Now do this again for the IPv4 CIDR block `10.0.1.0/24` and give it
a more private-like name "ChainlinkPrivateSubnet". We'll use this
subnet for internal traffic from EC instances to databases.

And then again, create third subnet `10.0.2.0/24` and give it again
a more private-like name "ChainlinkPrivateSubnet2". **IMPORTANT:** AWS
RDS requires two subnets in different availability zones for RDS usage,
so make sure the availability zone is different than the previous
subnets' zone.


## Internet Gateway

You'll need to create an internet gateway for your VPC, so you can
have access to your network from outside the network.

1. Open Internet Gateways from VPC left menu.
2. Click on Create internet gateway.
3. Give it a fitting name like "InternetGW"

Then you'll need to attach the gateway to your network:

1. Check the box on the left of your new network gateway and uncheck all
   other gateways that might be selected by default.
2. Open actions menu and click on Attach to VPC.
3. Choose your newly created VPC.


## Route table

Route tables define where your traffic can flow in your networks.
We'll create one for your public network and one for your private
network.

1. Open Route Tables from VPC Dashboard left menu.
2. Click on Create route table.
3. Give it a fitting name like "PublicRTB"
4. Choose your newly created VPC
5. Click on Create
6. On the main Route Tables page, click your newly created route table
   and navigate to botton of the page. Open the tab Routes.
7. You should see 10.0.0.0/16 as the default route. Click on edit.
8. Click on Add route and enter `0.0.0.0/0` as destination.
9. For target, click on the menu and choose "Internet Gateway" and then
   click on your previously created internet gateway.
10. Click on Save routes.
11. Open Subnet Associations tab and click on Edit subnet associations.
12. Check your public subnet active and Save.

## Rename Main route table

The VPC was given a blank main route table on creation. You can see
it on Route Tables with the same VPC ID as your VPC on "Your VPCs"
page. You can also click the "Main route table" on "Your VPCs" to view
the main route table.

Since the name is blank, it's probably a good idea to give it
a distinguishable name. You can edit the table name by hovering on top
of the blank name field and then entering it. Give it a fitting name
like "ChainlinkVPCMainRTB".

## Security groups

Next you should create the security groups, that will define what IP
addresses are allowed to access your AWS resources on your VPC and
what gateways are allowed.

First one up is EC2 HTTP/HTTPS access:

1. On VPC Dashboard, open Security Groups from the left menu.
2. Click on Create security group
3. First security group will be for the EC2 instances (your node), so
   give it a securty group name like "ChainlinkPublicSG".
4. Description can be something like "Allows GUI HTTP/HTTPS access"
5. For VPC, choose your newly created VPC.
6. Click on Create.
7. Give your new Security Group a distinguishable name by hovering over
   the blank name field and editing the name.
8. On the bottom you can see "Inbound rules" tab. Open it.
9. Click on "Edit rules" and the add the following rules:
  - Type: HTTP, Source: My ip
    - Sidenote: You can remove this rule later, if you don't want to
      keep HTTP open, but having HTTPS upgrade on EC2 instance for HTTP
      requests is just as fine. For testing and debugging it might be
      easier to keep HTTP traffic allowed.
  - Type: HTTPS, Source: My IP
  - Type: SSH, Source, My IP
10. Save.

Next one is database access:

1. Create a new security group:
  - Security Group Name: ChainlinkPostgresSG
  - Description: Allows Postgres Database connections
  - VPC: Your newly created VPC
2. Edit the name, like: ChainlinkRDSAccess
3. Copy the group id from public security group.
4. Add inbound rules:
  - Type: PostgreSQL, Source: Your copied public security group ID, description: Something fitting

## Database subnet groups

You'll need to create DB subnet group in order to get your database
working on the custom VPC.

1. Open Amazon RDS and click on Subnet Groups on the left menu
2. Click on Create DB Subnet Group.
3. Give it a fitting name like "chainlink-DB-subnet-group" and a fitting
   description like "DB Subnet Group for Chainlink"
   - DB subnets will be lowercase and dashed, wether you like it or not.
4. Choose your newly created VPC as the VPC.
5. On "Add subnets" section, set both of the private subnetworks from
   above as subnets:
   - `10.0.1.0/24` from first availability zone
   - `10.0.2.0/24` from second availability zone
6. Click on Create.

Okeydokey, you should be all set, for now.
