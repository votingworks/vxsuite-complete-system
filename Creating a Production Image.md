To create images for production, I set up a virtual machine in virt-manager that relies on a `raw` disk image for its disk. I usually use an Arch Linux-based host system, though Ubuntu 20 and Debian 11 also work. This outlines how to do that. After the VM is set up, the machine can be build and locked down as in the [INSTALL.md](https://github.com/votingworks/vxsuite-complete-system/blob/main/INSTALL.md) script, and the disk image flashed as described in the [vx-iso](https://github.com/votingworks/vx-iso) process. 

<h2>Creating a production image that can be flashed</h2>

Start by creating a new VM in [`virt-manager`](https://virt-manager.org/). I'm assuming you know how to install it and set it up properly. I recommend using it with KVM, though VirtualBox or whatever should work too. 

Create the new VM from a local Debian ISO: 
![image](https://user-images.githubusercontent.com/2686765/158505721-49588394-9d83-43e2-aa80-c3115950bca4.png)
![image](https://user-images.githubusercontent.com/2686765/158505748-dc63992d-21f1-4deb-ba0d-f20d5740e9c7.png)

Minimally, the VMs should get similar specifications of our production machines, which is roughly 8G of RAM and 2-4 processor threads. However, there's nothing stopping you from picking higher values, and this may be desirable if you have many more cores and much more RAM to make build times faster. I usually use 8 cores and 16GB of RAM just to make things snappier, though my machine has more than enough cores and RAM to spare for that.  
![image](https://user-images.githubusercontent.com/2686765/158505778-2b6b17d0-35d4-4b9d-bdda-abfb36398215.png)

For the disk image, select "Select or create custom storage" and click manage:
![image](https://user-images.githubusercontent.com/2686765/158506424-951edd69-5409-47eb-bd2e-9808e37c5b18.png)

On the next screen, select a directory where you would like the raw disk image to live (if none are shown, click the `+` in the bottom left and enter a path). Once you have highlighted the correct place, click the `+` next to **Volumes** to create a new disk.
![image](https://user-images.githubusercontent.com/2686765/158506649-a59d2281-0820-4ae3-b55d-d40e5e26c05c.png)

In the dialog, give your new disk image a name (I typically pick one that corresponds to the type of production device I'm creating. In the "Format" drop down, select "raw". In the dialog shown below, this will create a disk image called `VxMark.img` that can be flashed onto hardware using [vx-iso](https://github.com/votingworks/vx-iso).

![image](https://user-images.githubusercontent.com/2686765/158506825-ca2c8ec0-24ed-4c59-9314-a7e4f294114d.png)

Also make sure to up the disk size to at least 50G, and ensure that "Allocate entire volume now" is selected. 
![image](https://user-images.githubusercontent.com/2686765/158507233-c25ada70-f4cc-4e19-91ca-f1c8cc5d1839.png)

Finally, ensure the newly created volume is selected on the previous dialog and click "Choose volume". 
![image](https://user-images.githubusercontent.com/2686765/158507435-fb736aff-9d1a-4b96-9f7a-ff6b306fff50.png)

We want to customize the install ahead of time so our Debian install knows to create an EFI system partition. 
![image](https://user-images.githubusercontent.com/2686765/158505957-694e4858-8d4d-4190-913b-a1b24fde34a1.png)

On the first customization screen, make sure you have [`edk2-ovmf`](https://github.com/tianocore/edk2) installed. This will allow you to select Secure Boot-compatible virtual firmware. (I don't think SB-compatibility is strictly necessary, so it might be the case that just standard UEFI virtual firmware will work). 
![image](https://user-images.githubusercontent.com/2686765/158506084-b01cd6b0-4d58-4f2f-a4fa-6b4671fd3299.png)

Other than that, you should be good to create the virtual machine using Debian. Follow the instructions [here](https://github.com/votingworks/vxsuite-complete-system/blob/main/INSTALL.md) to create a production-ready, locked down image. Then, compress your disk image using `lz4` and copy the compressed image to the install stick created in the [vx-iso](https://github.com/votingworks/vx-iso) process, and you should be ready to flash to hardware!

<h2>Troubleshooting</h2>
<h3>Dropped into an EFI shell after install</h3>
If you are dropped into an EFI shell after you've installed (or even before), this can be because the VM firmware isn't perfect at remembering what to boot. The EFI shell looks like this:

![Screenshot_VxBase-dev_2022-03-16_13:07:16](https://user-images.githubusercontent.com/2686765/158648023-894363d7-4ae3-46b7-bd87-d75713ae4295.png)

To proceed, you may either select the EFI executable to boot or simply type `exit` to get into the main firmware application. If you just want to boot from here, do the following. First, figure out what the device you're booting is called by the EFI shell. Usually it is something like `FS0:`. The shell provides a mapping table of devices to EFI shell names at the top of the shell. A helpful tip: the `Alias` field can be used to determine the type of device in the event that an ISO and a disk image are present. More on this below. 

Once you know the device your executable lives on, you can use `ls <device name>` to find the executable on the device. For debian, the executable lives somewhere like this:

![Screenshot_VxBase-dev_2022-03-16_13:07:27](https://user-images.githubusercontent.com/2686765/158648365-dd551859-c846-4cda-a793-6b792d590bab.png)

Running the above command in the EFI shell should start Debian shim and boot into the installed OS. If you're on an ISO, the process should be identical. If you read the EFI table here, you can see that `FS1:` has an alias `HD1b`, indicating it's a hard disk, while `FS0:` has an alias of `CD0...`, indicating it's an emulated CD drive. 
![Screenshot_VxBase-dev_2022-03-16_13:16:03](https://user-images.githubusercontent.com/2686765/158649067-d0d358b0-fb8e-49d5-8f5c-e3b0aa50c4ba.png)

If you would rather use the firmware interface to boot, simply type exit into the EFI shell
![Screenshot_VxBase-dev_2022-03-16_13:07:38](https://user-images.githubusercontent.com/2686765/158649158-1d3e44cf-57aa-4c2b-ad55-ce4cbac58cc8.png)


Once in the firmware interface, navigate to the "Boot Maintenance Manager"
![Screenshot_VxBase-dev_2022-03-16_13:07:48](https://user-images.githubusercontent.com/2686765/158649229-eba8d181-75bd-4375-85e7-8ca754b5830f.png)
![Screenshot_VxBase-dev_2022-03-16_13:07:54](https://user-images.githubusercontent.com/2686765/158649233-a22c3c39-6122-4bd8-ae71-460a38497ff7.png)  

On the next screen, select "Boot from File": 

![Screenshot_VxBase-dev_2022-03-16_13:08:00](https://user-images.githubusercontent.com/2686765/158649354-7300983a-826b-4ed4-905d-e5796175a77b.png)

Now find the EFI executable you wish to start, much like before in the EFI shell: 
![Screenshot_VxBase-dev_2022-03-16_13:08:04](https://user-images.githubusercontent.com/2686765/158649463-da6e8d7e-0d9e-4e8f-b604-950d2d452d1e.png)
![Screenshot_VxBase-dev_2022-03-16_13:08:09](https://user-images.githubusercontent.com/2686765/158649465-a5773493-8cbe-49e9-8796-b45fb79488d2.png)
![Screenshot_VxBase-dev_2022-03-16_13:08:14](https://user-images.githubusercontent.com/2686765/158649466-cdd9cb74-c78a-4a77-acf0-d4443fe7f10f.png)
![Screenshot_VxBase-dev_2022-03-16_13:08:20](https://user-images.githubusercontent.com/2686765/158649471-7eb49a00-da5f-4de9-99f9-1ddab30d09cc.png)


<h3> Debian install doesn't start</h3>
Sometimes the Debian install won't start after VM creation. Double check that the ISO is in the emulated disk drive on the VM, and browse to the install ISO on your local disk.

![image](https://user-images.githubusercontent.com/2686765/158649607-37cc04c2-8754-4299-833c-b7c71cd1d755.png)

