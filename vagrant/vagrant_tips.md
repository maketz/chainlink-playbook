# Tips & Tricks

## Vagrant up

Instead of starting up command prompt, navigating to vagrant folder and
manually typing `vagrant up --no-provision`, you can create a desktop
shortcut, that can do that much faster for you.

1. Create desktop shortcut via **Right-click->New->Shortcut**
2. Enter the path `C:\Windows\System32\cmd.exe`, or wherever your
   cmd.exe is. Click **Next**.
3. Give it a fitting name. Click **Finish**.
4. **Right-click** the shortcut and choose **Properties**.
5. In the **Target** field, write the following: `C:\Windows\System32\cmd.exe /k vagrant up --no-provision`
    - `/k` means that we want to execute following command after opening
6. Write in the **Start in** field the path to your vagrant file folder,
   e.g. `C:\Vagrant\Ubuntu`
7. Define your keyboard shortcut by clicking the **Shortcut key** active
   and pressing your favored combination there with your keyboard,
   e.g. Ctrl + Shift + O
8. Click **Apply->Ok**

Now you can start up vagrant via following ways:
1. Clicking the shortcut on your desktop
2. Pressing the Windows key and then typing in your shortcut name
3. Using your keyboard combination

If you're having file permission problems, you can run the icon with admin
privileges by doing the following:
1. Set icon's **Target** field to `C:\Windows\System32\cmd.exe /k cd VAGRANT_PATH && vagrant up --no-provision`
    - Change `VAGRANT_PATH` path to wherever your Vagrant file is
    - NOTE: `cd` command uses lowercase hard drive names in paths e.g. `c:\Vagrant\Ubuntu`
2. From the icon's **Advanced...** options check the **Run as administrator** option
3. Click **Apply->Ok**
4. Now the icon is run with admin privileges always

## Putty \w login

Instead of starting up putty every time and manually inserting credentials,
you can create a shortcut to do that for you. This manual works only
if you use username and password to establish SSH, not private keys.

1. Create desktop shortcut via **Right-click->New->Shortcut**
2. Enter the path `C:\Program Files\PuTTY\putty.exe`, or wherever you putty.exe is. Click **Next**.
3. Give it a fitting name. Click **Finish**.
4. Open up putty and create a saved session with IP 127.0.0.1, port: 2222
   (if you haven't done this already). Later you'll need to remember the
   name you give it.
5. Close putty and **Right-click** your new Putty shortcut, then choose **Properties**.
6. In the **Target** field, write the following: `"C:\Program Files\PuTTY\putty.exe" -load "YOURSAVEDPUTTYSESSION" -l vagrant`
    - Change `YOURSAVEDPUTTYSESSION` to whatever you named your session in phase 4.
    - `-load "YOURSAVEDPUTTYSESSION"` means that putty will start up using your named session
    - Double quotes are necessary, if your putty.exe exists in **Program Files**, because
      the path has a space in it
    - `-l` supplies your SSH username, which is by default **vagrant** in vagrant/bionic64 machines.
      Change accordingly if you have changed this.
7. Write in the **Start in** field the path to your putty folder if it isn't there by default.
8. Define your keyboard shortcut by clicking the **Shortcut key** active and
   pressing your favored combination there with your keyboard, e.g. Ctrl + Shift + P
9. Click **Apply->Ok**

Now you can start up Putty via following ways:
1. Clicking the shortcut on your desktop
2. Pressing the Windows key and then typing in your shortcut name
3. Using your keyboard combination

## Bash aliases

Bash aliases are help you run complex and often used commands with
short aliases (nicknames, in more simple terms).

You can add them by:

1. opening `~/.bash_aliases` with nano/other text editor
2. Inserting your aliases to the file
3. Updating the changes to your active bash with `. ~/.bashrc`

Check [.bash_aliases](.bash_aliases) for an example configuration file.

## Screen

**Screen** is a helpful tool you can use to open up multiple bash
terminals inside one terminal. For example, you can have one screen
for your ETH client, second for Chainlink and a third for miscellaneous
stuff. With the screen setup, you don't have to play around with
docker attach/detach so much.

### Screen setup:

1. Create a screen configuration file `nano ~/.screenrc-chainlink`.

2. Enter your configuration.

3. Sometimes vagrant has to be rebooted in order to get the changes
   working.

Check [.screenrc-chainlink](.screenrc-chainlink)
for an example configuration file.

### Screen commands

Screens can be navigated with `CTRL+A, 0`, `CTRL+A, 1`, `CTRL+A, 2`,
according to the screen tabs you have open.

You can open up new tabs with `screen` command or `CTRL+A, C`.

You can exit screen tabs with `exit` command or `CTRL+A, K`.

More information about screen can be found at the official manual
https://www.gnu.org/software/screen/manual/screen.html#Default-Key-Bindings
(Tip: "C-a" means CTRL+A)

## Sharing files between host and guest

If you want to share files between your host OS and Vagrant's guest OS,
you can place files inside vagrant installation folder. These files
and folders are visible at `/vagrant` folder inside the Vagrant.

It would be wise to have your Git repositories cloned inside the shared
folder, so you can edit the shared files with a better text editor on
your host machine.


## Git branch in command prompt

The following snippet will show your current Git branch in your bash.
Add it to the end of `.bashrc` file.

```
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
```
