modern.ie VMs under KVM/QEMU
============================

Automates the process of getting the modern.ie images and converting them for
usage with KVM. There are 3 scripts:

fetch.sh (url)
    Given a URL to a .txt file full of URLs (like what MS link to), fetch all
    files within and run convert.sh on them.
convert.sh (directory)
    Given a directory containing a RAR file, convert contents into a QCOW2 file
    ready for use with QEMU
start.sh (QCOW image)
    Fetch virtio.iso if not already there, and start the image with reasonable
    options

Using
-----

#. Ensure depenencies are installed with ``apt-get install wget unrar qemu-system-x86 qemu-utils``
#. Run ``fetch.sh http://../IE11.Win8.1.For.LinuxVirtualBox.txt`` and wait.
   The multiple wgets will fight for the screen somewhat.
#. Run ``start.sh (name of image)``.
#. Install the virtio drivers from the CD drive. Change anything else you fancy
   whilst you're there, e.g. home page.
#. Shut down windows, note qemu is still running.
#. At the QEMU command prompt, run ``commit ide0-hd0`` to write changes back to
   the QCOW2 file.
#. Delete the ``ie-vm-fetch-workdir`` once you're happy everything worked. If
   something went wrong you can run ``./convert.sh ie-vm-fetch-workdir`` again
   to regenerate the QCOW2 file.

After this, you won't ever need to shut windows down properly, since by default
start.sh writes changes to a temporary file and does not change the QCOW2 file.

Code 39 when installing VirtIO drivers
--------------------------------------

Vista and WinXP can use the Win8 driver incorrectly. Select the directory manually
and then install.
