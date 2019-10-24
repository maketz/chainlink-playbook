# Amazon RDS

Most information on this doc can also be found here:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.PostgreSQL.html#CHAP_GettingStarted.Creating.PostgreSQL

This document is a simple rundown on how to create PostgreSQL server
on AWS for your node. This documentation is focused on free tier setup.

Make sure your preferred region has t2.micro instances available, for example:
- EU Frankfurt
- Canada (Central)
- All US regions

**NOTE:** If you choose anything outside the free tier, you WILL be
charged for your usage. Only 1 DB allowed at a time for free tier.

More info about free RDS specs:
https://aws.amazon.com/rds/free/

## Creating PostgreSQL DB on Amazon RDS

### Creating the database

1. Login to AWS console and open up Amazon RDS
2. Click "Create database" on the page.
3. Choose a database creation method: Standard create.
4. Configuration:
    - Engine type: PostgreSQL
    - Version: PostgreSQL 11.5-R1
    - Templates: Free tier
    - DB instance identifier: Whatever you like
    - Master username: Preferrably long and strong.
    - Password: Preferrably long and strong.
    - Connectivity->Additional connectivity configuration:
        - Publicly accessible: Yes
        - VPC security group (Can skip):
            If you already have VPC security group created, choose
            the one that suits you the best. If you do not have any
            custom VPC security group yet, default is ok for now.
    - Additional Configuration:
        - Initial database name:
            Preferrably keep to alphabetical numbers (A-Z, a-z, 0-9),
            or you'll have trouble setting up DB connection from your
            node.
6. Click on Create database.

Your database should now be booting up. While you're waiting, you can
do your security group now, if you haven't already.


### Creating VPC security group

1. Open Databases in Amazon RDS (Left menu).
2. Click on your DB identifier to open up the database information.
3. Open a new tab from the VPC security groups name link
4. On the new tab, click on "Create a security group"
5. Add following info:
    - Security group name
    - Description
6. Click on "Add rule" and set following:
    - Set port to 5432
    - Change the source to My IP
    - Give it a fitting description
7. Create.

Your DB should be ready by now. Info should show a green "Available"
text under Info-title. Now we'll set the newly created security group
for the DB, so connections can be made from your IP.

### Update the database

**IMPORTANT:** Even if your VPC security groups are set, you'll still
want to do AWS certificate authority update to the newest. So don't
skip this step.

1. Open up your DB on RDS console again
2. We'll modify the configuration for now from the upper right Modify:
    - Network & Security->Security group: Add your group here (if you haven't set the group already)
    - **Certificate authority:** rds-ca-2019
        - **Note:** When the warning pops, there will be a link to the
          newest AWS certificate files. Go and grab the 2019 from there.
          https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem
4. Continue and choose "Apply immediately". Reboot may take some time.

You should now be ready to connect to the DB with pgAdmin.

## Get the SSL certificate from AWS

If you didn't grab the SSL certificate from AWS yet, you should do it
now to ensure all your connections are secure in following steps.

https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem

## Creating proxy user, Option A: pgAdmin

We'll want to create a least privileged user for the database connection
between your chainlink node and database. This option covers how to
create that user with pgAdmin.

pgAdmin is more user-friendly option for managing your database, if
you prefer to use a graphic UI. It might be too much for basic user
creation, but it lets you peek at your database in a much more
friendlier way than psql.

To begin, download and install latest release from pgAdmin website:
https://www.pgadmin.org/

The installer wizard is relatively simple, so this doc won't be
explaining that.

### Setting up a connection with pgAdmin

1. Once you have pgAdmin installed, open it. On windows machines you
   should have quick-start icon on Windows start menu, if you can't
   find it.
2. Click on "Add new server"
3. Set a "Name" for the server, which will work like a nickname on
   pgAdmin server list.
4. Open up "Connection" tab and apply following:
    - Host name/address: Copy the database Endpoint address from AWS RDS
    - Port: Should be 5432, if you did not change it in RDS.
    - Maintenance database: `postgres` (RDS created this).
    - Username: Your master user username.
    - Password: Your master user password
5. On SSL tab:
    - SSL mode: Verify-Full
    - Root certificate: `rds-ca-2019-root.pem` from your file system
6. Save. You should now see your server on the left side of the pgAdmin.

**NOTE** If you cannot connect, make sure your Amazon
"VPC security groups" are correctly defined
(this was dicussed above).

### Creating the database user

A quick rundown on how to create the user.

1. From the server list on the left, open your server and Right-click
   on Login/Group Roles. Choose Create->Login/Group Role.
2. Simple rundown on the settings you'll want:
    - General:
        - Name: Whatever you like
            - Preferrably keep to alphabetical numbers (A-Z, a-z, 0-9),
              or you'll have trouble setting up DB connection username
              on your node
    - Definition:
        - Password: Whatever you like
          - Preferrably keep to alphabetical numbers (A-Z, a-z, 0-9),
            or you'll have trouble setting up DB connection password
            on your node
        - Connection limit: -1
            - -1 means infinite, but limiting it could cause trouble
              if some node crashes with an active connection on
    - Privileges:
        - Can login: Yes
        - All others: No
    - SQL:
        - Review the SQL before proceeding, to see if it makes sense.
3. Save.
4. Grant your master user privileges to your new user by right-click
   on your master user on the left menu and selecting "Properties..":
   4.1. Open "Membership" tab
   4.2. Add the master user
   4.3. Save

### Modifying database owner

Chainlink node prefers to have the connected user as the database
owner, according to the official documentation.

1. Right-click on your database. Choose "Properties".
2. Change the "Owner" to your newly created user/role.
3. On "Security" tab, add new row on "Privileges" and add your master
   user with all privileges, or you won't be able to connect to that
   database with your master user.
4. Save.

**NOTE:** The master user created by AWS is not actually a super-do-all
user, and you will effectively cut out master user access to the DB
if owner is changed and master user is not given privileges to the
database.

If you do get locked out of your DB, open up Query Tool on `postgres` DB
and enter following: `GRANT ALL PRIVILEGES ON DATABASE mydatabase TO mymasteruser;`

All done here.


## Creating proxy user, Option B: psql

This doc will not talk about how to acquire the psql tool for PostgreSQL.
That one is up to you.

1. Make sure you have your AWS rds certification available. This cert
   was mentioned in this document above.
2. Open up your database information on RDS. You'll need the Endpoint
   address next.
3. Connect to your database with psql using the following:

```
psql -h ENDPOINT_ADDRESS -p 5432 \
    "dbname=postgres user=YOUR_MASTER_USER sslrootcert=rds-ca-2019-root.pem sslmode=verify-full"
```

4. Check your databases with `\l` and you should see your created DB.
5. Execute the following SQL (change the values to match your config):

```
CREATE USER mydbuser WITH ENCRYPTED PASSWORD 'supersecretpassword';
ALTER DATABASE mydb OWNER TO mydbuser;
GRANT ALL PRIVILEGES ON DATABASE mydb TO mymasteruser;
```
6. Exit with `\q`.

All done here.


## Enforcing SSL

Forcing SSL connections provides sufficient encryption for your database
traffic. This means that without using the SSL certification, you
won't be able to connect to the database, so you won't forget to use it.

1. Open Amazon RDS.
2. From left menu bar, choose "Parameter group"
3. Click on "Create parameter group" on the right and apply following:
    - Parameter group family: postgres11
    - Type: DB parameter group
    - Group name: Whatever you like
    - Description: Whatever you like
4. Create.
5. Open the newly created parameter group for your database.
6. Search for parameter `force_ssl` and tick the checkbox and click
   on "Edit parameters".
5. Change the dropdown value from 0 to 1 and click on "Save changes".
6. Navigate to your DB instance in RDS and open up "Modify".
7. Change the DB parameter group to your newly created parameter group.
8. "Continue" and apply with "Modify DB Instance". Preferrably choose
   the "Apply immediately" option.