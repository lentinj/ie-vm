Windows evaluation VMs under KVM/QEMU
=====================================

Automates the process of getting the modern.ie images and converting them for
usage with KVM. There are 3 scripts:

fetch.sh (url)
    Given a URL to a VM .zip file, uncompress and convert into a QCOW2 file for use with QEMU,
    which will be waiting for you in the current directory.
start.sh (QCOW image)
    Fetch virtio.iso if not already there, and start the image with reasonable
    options

Prerequisites
-------------

wget & QEMU must be installed.

Debian / apt-based distributions::

    apt install wget unzip qemu-system-x86 qemu-system-gui qemu-utils ovmf

Visit the Microsoft web-pages first and inspect the EULAs you are implicitly accepting:

* https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/
* https://www.microsoft.com/evalcenter/evaluate-windows-10-enterprise
* https://www.microsoft.com/evalcenter/evaluate-windows-11-enterprise

Preparing a VM image
--------------------

#. Run ``fetch.sh 'https://aka.ms/windev_VM_virtualbox'`` and wait. You can break
   out of the download and resume it at a later point if necessary.
#. Run ``start.sh (name of image)``. Or omit the name if you want to run the
   most recent QCOW2 file. Use ``start.sh -h`` to see available options.
#. Install virtIO drivers (if you did not specify ``--no-virtio``):

      #. Go to "Settings" -> "Device Manager"
      #. For each unknown device, as well as for the display adapter, right-click and select "Update driver"
      #. Select "Browse my computer for the driver software"
      #. Select the CD drive (D: virtio-win-x.x), Windows will work out which driver within to install

#. Disable Windows Defender AV:

      #. Settings -> "Windows Defender Settings" -> "Virus & threat protection"
      #. Untick all the sliders
      #. Start menu -> type in "gpedit.msc"
      #. "Computer Configuration" -> "Administrative Templates" -> "Windows Components" -> "Microsoft Defender Antivirus" (or "Windows Defender Antivirus")
      #. "Turn off Windows Defender Antivirus" policy
      #. "Enable" and OK

#. Miscallaneous:

     #. Set screen resolution
     #. Set home page to ``http://10.0.2.2:8000`` (your laptop's port 8000)

#. Shut down windows, note qemu is still running.
#. At the QEMU monitor console (in the terminal you ran ``./start.sh`` from),
   run ``commit ide0-hd0`` to write changes back to the QCOW2 file.
#. Quit QEMU with ``quit`` at the console
#. Delete the ``workdir-*`` once you're happy everything worked.

Running a VM image
------------------

Run ``./start.sh (name of .qcow2 file)``. By default any changes to the VM will
be written to a temporary file, so the machine will always start up in the same
state. Use ``commit virtio0`` if you wish to update the QCOW2 image.

Once you have prepared your VM image, including installing the VirtIO SCSI
controller, add ``--disk-virtio`` to the start.sh arguments in order to use it.

For better performance, you may want to customise the number of CPUs (default: 1)
and amount of memory (default 4GB) granted to the VM. This can be done as
follows, for example::

    EXTRA_ARGS='-smp cpus=4' ./start.sh --disk-virtio --ram 2GB "MSEdge - Win10.qcow2"

If you want to have a VM that's customised for your project somehow, you could
just copy the .qcow2, however that's a lot of diskspace. Instead you can create
a new image that's based on the contents of another file, for example::

    qemu-img create -f qcow2 -F qcow2 -b WinDev2308Eval.qcow2 MyProject.IE9.Win7.qcow2

Passing through laptop's touchscreen
------------------------------------

My laptop has a multitouch touchscreen:

    # lsusb -d 1fd2:6007
    Bus 001 Device 006: ID 1fd2:6007 Melfas LGDisplay Incell Touch

If I temporarily grant read-write to the usb device:

    # ls -l /dev/bus/usb/001/006
    crw-rw-r-- 1 root root 189, 5 Apr 21 10:31 /dev/bus/usb/001/006
    # chmod a+rw /dev/bus/usb/001/006

...then QEMU can claim it and I can use it directly under QEMU, testing pinch-zoom effects:

    EXTRA_ARGS="-device usb-host,vendorid=0x1fd2,productid=0x6007" ./start.sh . . .
