# How to setup a Chainlink node with Vagrant

This documentation focuses on Ubuntu 18.0.4 (Bionic) installation for
Windows using Vagrant and VirtualBox.

## Why use Vagrant/VM?

Vagrant provides an easy-to-use commands, that can help you configure
different virtual machines on your host operating system (the one you
use to boot up your computer).

If you manage to corrupt a virtual machine, you'll be able to set up
a new one in a matter of minutes/hours. If you manage to corrupt your
host machine, it can take hours/days to recover.

Virtualbox snapshots can be helpful for recovery, after your done with
the setup, but those are out of this document's scope.

**Requirements (at the time of writing):**
- 256GB free space on SSD , if you are planning on running a local
  Ethereum client


## Vagrant installation

### Install Vagrant and Virtualbox

1. Load the latest Vagrant installer from https://www.vagrantup.com/downloads.html
2. Load the latest virtualbox from https://www.virtualbox.org/wiki/Downloads
3. Install the .msi

### Configure Virtualbox folders

If you want to change the location of the installed virtual machines,
you should change the settings before proceeding with Vagrant. Later on
it can get messy, if you try to change the location. Preferably set the
location on a SSD.

1. Open "Oracle VM Virtualbox" from Windows start menu.
2. Open File > Preferences
3. Choose a location for "Default Machine Folder". This is where your
   Ubuntu machine will be installed.
4. Press Ok. You can close the manager.

### Install Ubuntu box on Vagrant

1. Open up command prompt as Administrator
2. Navigate to desired folder on your Windows machine. This location
   will be used & shared with the Ubuntu box.
3. Run command `vagrant box add ubuntu/bionic64` to download latest
   Bionic 64-bit release for Vagrant.
4. Run command `vagrant init ubuntu/bionic64` to create configuration
   file for the vagrant box
5. Run command `vagrant plugin install vagrant-disksize` to add
   vagrant-disksize plugin, so your ETH client won't clog up the
   machine so fast.
6. Edit the newly created Vagrantfile according to your needs with a
   text editor. !IMPORTANT! You will have to add the following
   configuration:

```
config.disksize.size = '256GB' # Assign a decent amount of disk space, required by ETH client

# Chainlink nodes, HTTPS
# Ports are 67xx to differentiate from HTTP configurations in docs
config.vm.network "forwarded_port", guest: 6788, host: 6788 # Chainlink GUI
config.vm.network "forwarded_port", guest: 6787, host: 6787 # Secondary GUI

# Create a private network, which allows host-only access to the machine
# using a specific IP.
config.vm.network "private_network", ip: "192.168.33.1"
```

Check out the [Vagrantfile](../vagrant/Vagrantfile) for example configuration.

## Connecting to your Vagrant machine

This section focuses on PuTTY. You can also choose any other SSH client to your
liking

### Creating private key for authentication

Bionic box uses SSH-key for default authentication, so you'll have to
create a private key for the box. Luckily the key already exists, but
it is not in .ppk format. You'll have to convert it first with
PuTTYgen.

1. Download PuTTY from https://www.putty.org/ and install it
2. Open up PuTTYgen (use windows search for quick access)
3. Click load and navigate to `..\.vagrant\machines\default\virtualbox`
4. Choose to show All files from bottom right corner
5. Open `private_key`
6. (Optional) Set a passphrase for the private key.
7. Save your private key.

### Connecting to the Vagrant box

Now you'll boot up the machine and connect to it with Putty.

1. Navigate with command prompt to your vagrant box's root folder, where
   Vagrantfile is located.
2. Run command `vagrant up`. This will boot up your machine. You'll
   probably need to wait for half a minute for it to load. Prompt is
   is available after it has finished.
3. Open up PuTTY.
4. Set "Host Name (or IP address)" to 127.0.0.1 and port as 2222
5. From Category-menu open Connection->SSH and click Auth.
6. Set the Private key (.ppk file you created) as "Private key file for
   authentication"
7. Enter a name for "Saved sessions" and click save.
8. Now click Open. Enter `vagrant` as username.

You should now see Ubuntu login information on your SSH client.

### Finishing touches

Once you're inside the machine run `sudo apt-get update` to get the
latest update definitions for your machine.

Install git with `sudo apt-get install git`, if you plan on storing
something on your GitHub/other git repo. Ubuntu 18.0.4 should come with
it preinstalled.

Git configuration:
```
git config --global user.name "Your Name"
git config --global user.email your.email@example.com
```

Refer to your GitHub repo provider for SSH key configuration.
([GitHub](https://help.github.com/articles/connecting-to-github-with-ssh/))


## Chainlink node installation

This section focuses on chainlink node installation on the Vagrant VM.
All documentation and commands can be found at the official
documentation: https://docs.chain.link/docs/running-a-chainlink-node

### Docker install

1. Install docker:
`curl -sSL https://get.docker.com/ | sh`

2. Assign docker user permissions
`sudo usermod -aG docker $USER`

3. Close putty and reload vagrant from command prompt:
`vagrant reload`. TIP: you can also use `vagrant halt` to shut down
the machine and then `vagrant up` or `vagrant up --no-provision` to boot
up the machine.

4. Connect to your machine with PuTTY again.


### Ethereum client install, Option A: Geth

1. Install Geth docker box:
`docker pull ethereum/client-go:latest`

2. Create a local folder to persist the data
`mkdir ~/.geth-ropsten`

3. Boot up the GETH box:
```
docker run --name eth -p 8546:8546 -v ~/.geth-ropsten:/geth -it \
           ethereum/client-go --testnet --ws --ipcdisable \
           --wsaddr 0.0.0.0 --wsorigins="*" --datadir /geth
```

   It will take about 2-10 minutes for it to connect to peers and start
   downloading blocks and syncing. You have to be fully synced in order
   to see your Chainlink jobs being completed on your node.

   If you see more blocks being generated on https://ropsten.etherscan.io/
   than your machine can sync, it means your internet connection or hard
   disk is not quick enough to ever catch up with the latest blocks.
   You'll need an upgrade on your hardware or ISP.

4. Deattach from the docker box with `CTRL+P, CTRL+Q`. You can confirm
   that it is running with `docker ps`. If you want to, you can attach
   back with `docker attach eth`

5. To shutdown the container use `docker stop eth`.
   To kill the container you can use `CTRL+C` while attached.

6. To start up the container, use `docker start -i eth`.

### Ethereum client install, Option B: Parity

1. Install Parity docker box:
`docker pull parity/parity:stable`

2. Create a local folder to persist the data
`mkdir ~/.parity-ropsten`

3. Boot up the GETH box:
```
docker run --name eth -p 8546:8546 \
           -v ~/.parity-ropsten:/home/parity/.local/share/io.parity.ethereum/ \
           -it parity/parity:stable --chain=ropsten \
           --ws-interface=all --ws-origins="all" \
           --base-path /home/parity/.local/share/io.parity.ethereum/
```

   It will instatly start connecting to peers and downloading snapshots
   of ETH blocks. This will take several hours. After that it will
   start syncing. You have to be fully synced in order to see your
   Chainlink jobs being completed on your node.

   If you see more blocks being generated on https://ropsten.etherscan.io/
   than your machine can sync, it means your internet connection or hard
   disk is not quick enough to ever catch up with the latest blocks.
   You'll need an upgrade on your hardware or ISP.

4. Deattach from the docker box with `CTRL+P, CTRL+Q`. You can confirm
   that it is running with `docker ps`. If you want to, you can attach
   back with `docker attach eth`

5. To shutdown the container use `docker stop eth`.
   To kill the container you can use `CTRL+C` while attached.

6. To start up the container, use `docker start -i eth`.


### Ethereum client install, Option C: External

External clients may vary and connecting to them depends on the external
clients' API.

Chainlink's supported options can be found on the official documentation
https://docs.chain.link/docs/run-an-ethereum-client#section-external-services


### Chainlink node setup

This section focuses on node setups using local ethereum clients. Refer
to official documentation when setting up a node with an external
ethereum client provider
https://docs.chain.link/docs/running-a-chainlink-node#section-optional-set-the-remote-database_url-config

1. Create a folder to hold Chainlink data:
`mkdir ~/.chainlink-ropsten`

2. Create your chainlink environment file:
```
echo "ROOT=/chainlink
LOG_LEVEL=debug
ETH_CHAIN_ID=3
MIN_OUTGOING_CONFIRMATIONS=2
LINK_CONTRACT_ADDRESS=0x20fe562d797a42dcb3399062ae9546cd06f63280
CHAINLINK_TLS_PORT=0
SECURE_COOKIES=false
ALLOW_ORIGINS=*" > ~/.chainlink-ropsten/.env
```

3. Fetch ETH client ip address to a local variable:
`ETH_CONTAINER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(docker ps -f name=eth -q))`

4. Set the ip to your Chainlink environment file:
`echo "ETH_URL=ws://$ETH_CONTAINER_IP:8546" >> ~/.chainlink-ropsten/.env`

5. Add SSL support:

Following commands can be found at
https://docs.chain.link/docs/enabling-https-connections

5.1 Create a folder for certs: `mkdir ~/.chainlink-ropsten/tls`

5.2 Create certs inside the folder:

```
openssl req -x509 -out  ~/.chainlink-ropsten/tls/server.crt  -keyout ~/.chainlink-ropsten/tls/server.key \
  -newkey rsa:2048 -nodes -sha256 -days 365 \
  -subj '/CN=localhost' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```

5.3. Update .env file to contain certs:

```
echo "TLS_CERT_PATH=/chainlink/tls/server.crt
TLS_KEY_PATH=/chainlink/tls/server.key" >> .env
```

5.4 Remove TLS port env-configuration and enable secure cookies with:
```
sed -i '/CHAINLINK_TLS_PORT=0/d' .env

sed -i '/SECURE_COOKIES=false/d' .env
```

6. Boot up Chainlink node:
`cd ~/.chainlink-ropsten && docker run --name chainlink -p 6788:6689 -v ~/.chainlink-ropsten:/chainlink -it --env-file=.env smartcontract/chainlink local n`

   This command will start the chainlink node setup.

6.1. Enter a secure password for your keystore file.

6.2. Enter your email and a secure password. These work as your
     Chainlink node credentials, so remember them well!

7. Open up your browser and login with your credentials at
   `https://192.168.33.1:6788`.

8. You can boot up secondary Chainlink node with:
`cd ~/.chainlink-ropsten && docker run --name secondary -p 6787:6689 -v ~/.chainlink-ropsten:/chainlink -it --env-file=.env smartcontract/chainlink local n`

9. When you want to, you can stop containers with `docker stop chainlink`
   and `docker stop secondary`. To start he containers again, you can
   use `docker start -i chainlink` and `docker start -i secondary`

10. If you want to, you can save your credentials locally and use them on
   bootup.

   Official documentation uses echo, but this doc uses nano, because
   complex passwords get obliterated by the echo command.
   https://docs.chain.link/docs/miscellaneous#section-use-password-and-api-files-on-startup

10.1 Start editing a new file with `nano ~/.chainlink-ropsten/.api` and
    add your credentials on separate lines:

```
your@email.com
your_password
```

10.2 Add wallet password to a file similarly with
    `nano ~/.chainlink-ropsten/.password` and add your wallet password
    there.

```
your_wallet_pass
```

10.3 Upgrade your node containers accordingly:
```
docker rm chainlink && docker rm secondary
cd ~/.chainlink-ropsten && docker run --name chainlink -p 6788:6689 -v ~/.chainlink-ropsten:/chainlink -it --env-file=.env smartcontract/chainlink local n -p /chainlink/.password -a /chainlink/.api
cd ~/.chainlink-ropsten && docker run --name secondary -p 6787:6689 -v ~/.chainlink-ropsten:/chainlink -it --env-file=.env smartcontract/chainlink local n -p /chainlink/.password -a /chainlink/.api
```


You are done!

More info on the secondary node can be found here:
https://docs.chain.link/docs/performing-system-maintenance#section-failover-node-example

Now you have a fully functioning vagrant machine, that you can boot up
and shut down anytime. If you want to speed up your work with vagrant,
check out [vagrant_tips.md](../vagrant/vagrant_tips.md).

When you want to shut down vagrant machine, you can use `vagrant halt`
on command prompt.
