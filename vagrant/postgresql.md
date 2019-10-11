# Installing local PostgreSQL server

This document refers to installation guide on:
https://computingforgeeks.com/install-postgresql-12-on-ubuntu/

**IMPORTANT**

Changing database for an existing node will lose all your previous
data, since the data won't be carried over the next database.

## Install PostgreSQL to Chainlink

1. Stop all nodes and ethereum client for now, if you have them running.

2. Update and upgrade:

```
sudo apt update
sudo apt -y install vim bash-completion wget
sudo apt -y upgrade
```

3. Shut down your VM (Close putty and use `vagrant halt`).

4. Add following configurations to `Vagrantfile` (if you don't have yet)

```
# PostgreSQL
config.vm.network "forwarded_port", guest: 5432, host: 5432

# Private outward network for host machine traffic
config.vm.network "private_network", ip: "192.168.33.1"
```

5. Boot up VM with `vagrant up --no-provision`

6. Add Postgresql 12 repository and install with following:

```
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-12 postgresql-client-12
```

## Configuring PostgreSQL

1. Switch to new user `postgres` with `sudo su - postgres`

2. Open up postgres CLI with `psql`

3. Set password with `\password`. This will run you through interactive
   password configuration.

4. Create DB `chainlink` and role `chainlink` with:

```
CREATE DATABASE chainlink;
CREATE USER chainlink WITH ENCRYPTED PASSWORD 'supersecretpassword';
GRANT ALL PRIVILEGES ON DATABASE chainlink to chainlink;
```

5. Exit the CLI with `\q` and exit postgres user with `exit`.

6. Open PostgreSQL communications:

6.1. By editing `postgresql.conf` with
     `sudo nano /etc/postgresql/12/main/postgresql.conf` and uncommenting
     the following:

```
listen_addresses = '*'
```

6.2. And edit `pg_hba.conf` with `sudo nano /etc/postgresql/12/main/pg_hba.conf`
     by adding the following on bottom of the file:

```
host    all             all             0.0.0.0/0               md5
```

7. Restart your VM. Vagrant might have issues with PostgreSQL changes,
   so it's easier to restart the whole VM.


## Configure your node

1.  Modify your chainlink configuration `.env` file with
    `nano ~/.chainlink-ropsten/.env` and add following

```
DATABASE_URL=postgresql://chainlink:some_password@192.168.33.1:5432/chainlink
```

**NOTE:** IP and may be different, if you used different configuration.

2. Remove your previous chainlink containers with:

```
docker rm chainlink
```

**NOTE:** Repeat for all chainlink containers

3. Boot up chainlink containers with your docker configuration. Here
   is the example bootup from [vagrant_ropsten.md](../vagrant/vagrant_ropsten.md):

```
cd ~/.chainlink-ropsten && docker run --name chainlink -p 6788:6689 -v ~/.chainlink-ropsten:/chainlink -it --env-file=.env smartcontract/chainlink local n -p /chainlink/.password -a /chainlink/.api
cd ~/.chainlink-ropsten && docker run --name secondary -p 6787:6689 -v ~/.chainlink-ropsten:/chainlink -it --env-file=.env smartcontract/chainlink local n -p /chainlink/.password -a /chainlink/.api
```

Your nodes should be running on Postgres.
