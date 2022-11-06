This file explains getting VxSuite up and running in Debian 11.2, along with setting up security features like Secure Boot, dm-verity, and TPM2-TOTP. 

<h2>Preseed Installer</h2>

This repo provides a preseed file that can be used for an automated install of Debian that installs the software and partitions the disks in the manner necessary to create a production machine. In future we will also provide a development machine preseed, but for now we just provide a production one. To use the production preseed file to configure a machine, navigate to the automated install option in GRUB after booting the Debian iso:
![Screenshot_VxMarkProdBase_2022-03-21_21:10:57](https://user-images.githubusercontent.com/2686765/159756779-68452a49-3352-4c95-892e-6d544778118d.png)
![Screenshot_VxMarkProdBase_2022-03-21_21:11:07](https://user-images.githubusercontent.com/2686765/159756788-aa6be79d-1142-455f-8218-418c17bf36d8.png)

Then, type the URL for the preseed file into the box provided by the installer. The URL is 

```
https://raw.githubusercontent.com/votingworks/vxsuite-complete-system/main/production-preseed.cfg
```
![Screenshot_VxMarkProdBase_2022-03-23_13:13:34](https://user-images.githubusercontent.com/2686765/159757265-6ff662b1-87d8-43fd-ba05-0e9e95ab8d17.png)

Clicking "Continue" should result in a full install of the system, which automatically reboots into a login prompt. The login credentials are

```
login: vx
password: insecure
```
**NOTE**: These credentials are deleted as part of the production setup process and are not usable on deployed machines.

From there, clone this git repo and proceed with a normal installation. 

<h2>Manual Installer</h2>

The manual install process can follow the usual path of the Debian installer. The only modification that needs to be made is as follows:

Set the machine's hostname to be "Vx":
![image](https://user-images.githubusercontent.com/2686765/156217619-95165aca-da51-406d-8c93-4630a5e50a63.png)

On the disk partitioning screen, select “Setup LVM”

![image](https://user-images.githubusercontent.com/2686765/156217724-78ada600-fb7b-4b93-b9f1-6ac5d1bd3f0d.png)

Select the disk in question:
![image](https://user-images.githubusercontent.com/2686765/156218657-7e0a8327-6791-4f5e-a8d5-497e013671d3.png)

Use separate partitions for `/home`, `/var`, and `/tmp`
![image](https://user-images.githubusercontent.com/2686765/156218692-8b62b4dd-aa13-49ce-8553-38636c7b3970.png)

Make the changes:
![image](https://user-images.githubusercontent.com/2686765/156218723-4eadaa21-4706-45bb-a6cd-4985f4908375.png)

Use the whole disk for LVM:
![image](https://user-images.githubusercontent.com/2686765/156218741-8d788793-0bc5-4f5e-bb4f-4daddbd21881.png)

**IMPORTANT**: do not persist these changes, we're not done yet!
![image](https://user-images.githubusercontent.com/2686765/156218759-bfd4589b-8869-4778-a1be-0ac3a8dc7801.png)

On this screen, scroll to the top and click "Configure LVM":
![image](https://user-images.githubusercontent.com/2686765/156218789-3adc2403-8017-4c86-8188-58368df9e234.png)
![image](https://user-images.githubusercontent.com/2686765/156218984-b75458ad-8006-4913-8f4a-b25e01ea68c9.png)

Now it's okay to write the changes to disk:
![image](https://user-images.githubusercontent.com/2686765/156219108-c32f6890-e671-4038-b1a0-88b03d311225.png)

Start by deleting the swap partition:
![image](https://user-images.githubusercontent.com/2686765/156219126-87d39e66-718a-4374-91df-44543f68715f.png)
![image](https://user-images.githubusercontent.com/2686765/156219143-ebe05a13-464a-404f-9823-33ee80c75855.png)

Now add a `hashes` partition in its place: 
![image](https://user-images.githubusercontent.com/2686765/156219159-5e54ec45-48ed-45e1-8983-5225e3d4f949.png)
![image](https://user-images.githubusercontent.com/2686765/156219166-0ad2a46f-a3c4-4d4e-b1ab-d72ad0d7b8c4.png)
![image](https://user-images.githubusercontent.com/2686765/156219190-1bda80c0-fe77-42ae-9d9c-d10bebd422e1.png)
![image](https://user-images.githubusercontent.com/2686765/156219210-ba23cf55-f0c2-4734-8a1c-6acb865fbc49.png)

Now we're done!
![image](https://user-images.githubusercontent.com/2686765/156219231-c051bb0f-a816-4dfe-871a-7e4edb6c4780.png)
![image](https://user-images.githubusercontent.com/2686765/156219254-c00b5fe9-53c7-411d-88c2-c6cf798fa665.png)

Note: there may be a screen asking if we want to install with a UEFI-based bootloader. Say yes. Afterwards, continue through the rest of the install as normal. 

<h2>First boot</h2>
Since Debian does not have the same packages as Ubuntu (i.e. no PPAs), some modifications are needed from the usual VxSuite build process. First, you’ll have to add your user to the sudoers group using `usermod -a -G sudo ${USER}`

```bash
sudo apt install git build-essential rsync cups cryptsetup efitools 
usermod -a -G lpadmin $USER
```

Add export `PATH=$PATH:/sbin/` to your `.bashrc`

```bash
reboot
```

<h2>Setting up VxSuite</h2>

Now we're ready to setup VxSuite. After rebooting into the OS,

```bash
git clone git@github.com:votingworks/vxsuite-complete-system
cd vxsuite-complete-system
make node
make checkout
make build
./setup-machine.sh
```

After this point, the machine will be locked down, and should automatically reboot. After reboot, ensure that your secure boot keys are on a USB drive connected to the machine and go into the admin screen (TTY2). Select the lockdown option:
![image](https://user-images.githubusercontent.com/2686765/156222053-16c5ed78-75b6-486d-b5cc-753110badf41.png)

This should setup everything for you, except TPM2-TOTP, and reboot the machine. On reboot, make sure you go back into the firmware interface and turn on Secure Boot. If that works, it should boot into the new dm-verity-backed lockdown. On the tty2, you should now see
![image](https://user-images.githubusercontent.com/2686765/156222216-ea909f42-00de-4097-b134-650ffcbcd3c9.png)

And if you `^C` you should see the following when running `lsblk`:
![image](https://user-images.githubusercontent.com/2686765/149411997-202e2a72-d8d4-492e-a19e-d43c7508e95a.png)


