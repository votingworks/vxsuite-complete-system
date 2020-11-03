# VxSuite Hardware-Specific Docs

## Surface Go Tablets

VxEncode and VxPrint run in production on Surface Go tablets.

### Booting from USB 

Booting off USB for these tablets is particularly challenging.

First, you need to allow the system to boot from USB by going into the
Surface Go BIOS and setting the appropriate boot order. Surprisingly,
that won't be enough, but you still have to do it. To do so:

* press the volume up key and, while pressed, power up the tablet.

* stop pressing the volume up key the moment you see the windows icon.

* you should be in the BIOS. Set the boot order appropriately.

* reboot / shut down.

#### First Install from USB

The Surface Go's come with Windows. The simplest way to boot from USB is as follows:

* *Insert Bootable USB stick*: you'll want a USB hub that plugs into
  the USB-C and lets you plug in a USB keyboard and a bootable USB
  stick.

* *Force into recovery mode*: power up the tablet, then, as soon as
  the Windows logo appears, force shut it down by holding down the
  power button continuously until the tablet shuts down. Do this 2 or
  3 times until the booting process says "starting recovery" or a
  similar message (it varies by exact model.)
  
* *Boot from USB*: choose to boot from a device and choose "Linpus
  Lite". You're good to go.


#### Later Install from USB

Once Linux is installed, reinstallation is different:

* *Insert Bootable USB stick*: just like above, you'll need a USB hub
  that plugs into the USB-C and lets you plug in a keyboard and a
  bootable USB stick.
  
* *Get to Grub command line*: repeatedly press the `Esc` key while
  booting until you get to a Grub command line.

* *Tell Grub to Boot from USB stick*: At grub command line, type:

```
set root=(hd0,
```

and use `tab` to autocomplete. If you did everything right and you have a FAT32 bootable USB stick (which is what you want), you should see `msdos0` or `msdos1` as the first autocompletion. So your command ends up as:

```
set root=(hd0,msdos0)
```

then:

```
chainloader /efi/boot/grubx64.efi
```

the `/efi/...` path should be tab-auto-completable.

And finally:

```
boot
```

you should now be booting off USB.
