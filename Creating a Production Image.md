To create images for production, I set up a virtual machine in virt-manager that relies on a `raw` disk image for its disk. This outlines how to do that. After the VM is set up, the machine can be build and locked down as in the [INSTALL.md](https://github.com/votingworks/vxsuite-complete-system/blob/main/INSTALL.md) script, and the disk image flashed as described in the [vx-iso](https://github.com/votingworks/vx-iso) process. 

<h2>Creating a production image that can be flashed</h2>

Start by creating a new VM in [`virt-manager`](https://virt-manager.org/). I'm assuming you know how to install it and set it up properly. I recommend using it with KVM, though VirtualBox or whatever should work too. 

Create the new VM from a local Debian ISO: 
![image](https://user-images.githubusercontent.com/2686765/158505721-49588394-9d83-43e2-aa80-c3115950bca4.png)
![image](https://user-images.githubusercontent.com/2686765/158505748-dc63992d-21f1-4deb-ba0d-f20d5740e9c7.png)

I normally try to mirror the specifications of our production machines, which is roughly 8G of RAM and 2-4 processor threads. However, there's nothing stopping you from picking higher values, and this may be desirable if you have many more cores and much more RAM to make build times faster. 
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
