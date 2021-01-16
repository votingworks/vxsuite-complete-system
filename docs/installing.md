# Installing VxSuite

To build production VxSuite machines (BMD, BAS, Election Manager, etc.), follow these key steps:

* configure a first machine of a particular type, say BMD, on a particular piece of hardware. Call it Machine0.
* clone Machine0 as an image on an external hard drive.
* clone the image onto as many identical machines as needed.

The cloning process is done using [Clonezilla](https://clonezilla.org/).

## Configure Machine0

Set up the appropriate VxSuite machine type onto the desired hardware
by following the [README](../README.md). This involves installing
Ubuntu, then installing the VxSuite software. We call this Machine0.

Ensure Machine0 works exactly as expected. Test test test.

## Prepare a Clonezilla + images disk

You need a [Clonezilla Live
installation](https://clonezilla.org/clonezilla-live.php), which is
basically a bootable USB drive (can be a USB stick) that boots
straight into Clonezilla. You'll also need an external drive on which
to store the images. These two disks can be one and the same, or can
be separate.

To build a Clonezilla-Live + images disk all on one USB:

* strongly recommend a USB 3.0+ drive for speed.

* partition the drive: 1GB for Clonezilla, and the rest for
  images. The Clonezilla partition should be FAT32 and bootable, the
  images partition should be ext4. One straightforward way to do this is on Linux, using `fdisk`:
  * plug in USB stick, figure out where it's mounted, e.g. `/dev/sdb`
  * unmount it: `sudo umount /dev/sdb`
  * `sudo fdisk /dev/sda`
  * `p` to see the partition table, should just show one.
  * `d` to delete the single MSDOS partition.
  * `n` to create a new partition. Follow prompt to size it as 1GB.
  * `t` to set its type, type `b` for FAT32
  * `a` to make it active / bootable.
  * `n` to create a second partition. Rest of drive.
  * `w` to write the partition table.
  * `sudo fdisk -l` should show the partitions, unformatted.
  * `sudo mkfs.vfat -F 32 /dev/sda1`
  * `sudo mkfs.ext4 /dev/sda2`, which will take some time if the USB stick is large.
  * Unplug USB, replug it in, and it should be good to go.

* Once the partitions are mounted, install Clonezilla Live as per the
  documentation above onto the 1GB partition:
  `sudo unzip <clonezilla_file> -d /media/<mount_point>`
  `cd /media/<mount_point>/utils/linux`
  `sudo bash makeboot.sh /dev/sdb1`
  
You've now got a Clonezilla + images disk, ready to use.

## Clone Machine0 as an image

* Boot Machine0 from the Clonezilla + images disk created above. You
  should land into the Clonezilla menu.
  
* Follow these steps:
  * choose language and keyboard layout
  * "Start Clonezilla"
  * "device-image mode"
  * "local dev"
  * press Enter to confirm
  * once the drives show up, press ctrl-c
  * select the USB stick partition that holds the images (should be the second, larger one)
  * that partition's contents are now listed, just tab over to "Done" and press enter, then enter again to confirm.
  * "Beginner"
  * "savedisk"
  * Type a desired image name, e.g. 2020-01-15-vxmark-m11
  * confirm source drive (there should be only one)
  * choose whether to verify source disk (I haven't found it necessary, but you can do it, no harm)
  * choose to verify the created image (not strictly necessary, but I prefer to)
  * encrypt the image if you want but not necessary (you'll need to remember the passphrase if you do)
  * choose "poweroff"
  * confirm a few times
  * then the imaging should proceed
  * machine shuts down when done.

* You now have an image of Machine0 on the USB stick.

## Clone image onto identical hardware

* Select your next piece of hardware, Machine1, should be identical to
  Machine0 (it will still work if the hard drive is larger on
  Machine1, but not if it's larger on Machine0.)

* Boot Machine1 from the Clonezilla + images disk. You should land into the Clonezilla menu.

* Follow the same initial steps as before
  * choose language and keyboard layout
  * "Start Clonezilla"
  * "device-image mode"
  * "local dev"
  * press Enter to confirm
  * once the drives show up, press ctrl-c
  * select the USB stick partition that holds the images (should be the second, larger one)
  * that partition's contents are now listed, just tab over to "Done" and press enter, then enter again to confirm.
  * "Beginner"
  
* Now the steps that differ for the imaging of the drive:
  * "restoredisk"
  * select the image file to restore (e.g. 2020-01-15-vxmark-m11)
  * confirm the target drive (there should be only one). You'll have to confirm at least twice.
  * choose to verify the source image (not strictly necessary, but I prefer to)
  * choose "poweroff"
  * confirm a few times
  * then the imaging of the drive should proceed
  * machine shuts down when done.

You should now have Machine1 identical to Machine0.
