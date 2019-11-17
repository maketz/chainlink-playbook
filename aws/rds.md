# Amazon RDS

Before you begin, you should have your VPC configuration ready, or
else you will have to do extra work changing the VPC. Some database
options do not allow you to change VPC after a database has been
created. More info about VPC can be found on [vpc.md](./vpc.md).

Official install/setup information about RDS can be found here:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.PostgreSQL.html#CHAP_GettingStarted.Creating.PostgreSQL

This document is a simple rundown on how to create PostgreSQL server
on AWS for your node. This documentation is focused on free tier setup.

Make sure your preferred region has t2.micro instances available, for example:
- EU Frankfurt
- EU Ireland
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
    - Connectivity:
        - VPC: Your custom VPC (the one created in [vpc.md](./vpc.md))
        - Additional connectivity configuration:
            - Subnet group: Your custom Subnet Group (the one created in [vpc.md](./vpc.md))
            - Publicly accessible: Yes
            - VPC security group:
                1. Remove default...
                2. ...and use the one you defined for Postgres in VPC creation
    - Additional Configuration:
        - Initial database name:
            Preferrably keep to alphabetical numbers (A-Z, a-z, 0-9),
            or you'll have trouble setting up DB connection from your
            node.
6. Click on Create database.

Info should show a green "Available" text under Info-title, when your
DB is ready.

### Update the database

We'll update the DB instance to use newest SSL/TLS cert.

1. Open up your DB on RDS console again
2. We'll modify the configuration for now from the upper right Modify:
    - Network & Security->Security group: Add your group here (if you haven't set the group already)
    - **Certificate authority:** rds-ca-2019
        - **Note:** When the warning pops, there will be a link to the
          newest AWS certificate files. Go and grab the 2019 from there.
          https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem
4. Continue and choose "Apply immediately". Reboot may take some time.

You should now be ready to connect to the DB with pgAdmin or psql.

## Opening up your DB to the internet

You'll need your internet gateway for private subnets for a while,
so go to VPC dashboard and do the following:

1. Open route tables
2. Activate the public route table (created in [vpc.md](./vpc.md)) and
   edit Subnet Associations in the bottom tab.
3. Add your private subnets to the route table for a while.

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

All done here. You should modify the DB and remove public access
and remove private subnets from public route table association.


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

All done here. You should modify the DB and remove public access
and remove private subnets from public route table association.
