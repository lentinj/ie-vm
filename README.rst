modern.ie VMs under KVM/QEMU
============================

Automates the process of getting the modern.ie images and converting them for
usage with KVM. There are 3 scripts:

ie-urls.sh
    Attempt to parse the relevant "Batch File Download" URLs from the modern.ie
    page
fetch.sh (url)
    Given a URL to a .txt file full of URLs (like what MS link to), fetch all
    files within, uncompress and convert into a QCOW2 file for use with QEMU,
    which will be waiting for you in the current directory.
start.sh (QCOW image)
    Fetch virtio.iso if not already there, and start the image with reasonable
    options

Using
-----

#. Ensure depenencies are installed with
   ``apt-get install wget unrar dos2unix qemu-system-x86 qemu-utils``
#. Run ``ie-urls.sh`` to list available Windows / IE images, or go to http://modern.ie
   and copy the "Batch File Download" URL for the Linux/VirtualBox VM for the version of IE you want.
#. Run ``fetch.sh http://../IE11.Win8.1.For.LinuxVirtualBox.txt`` and wait.
   The multiple wgets will fight for the screen somewhat.
#. Run ``start.sh (name of image)``.
#. Install the virtio drivers from the CD drive. Change anything else you fancy
   whilst you're there, e.g. home page to ``http://10.0.2.2:8000`` (your laptop's
   port 8000).
#. Shut down windows, note qemu is still running.
#. At the QEMU command prompt, run ``commit ide0-hd0`` to write changes back to
   the QCOW2 file.
#. Delete the ``workdir-*`` once you're happy everything worked. If
   something went wrong you can run ``./fetch.sh`` again to regenerate the
   QCOW2 file. It will not re-download files.

After this, you won't ever need to shut windows down properly, since by default
start.sh writes changes to a temporary file and does not change the QCOW2 file.

Code 39 when installing VirtIO drivers
--------------------------------------

Vista and WinXP can use the Win8 driver incorrectly. Select the directory manually
and then install.

Creating a specialised VM
-------------------------

If you want to have a VM that's customised for your project somehow, you could
just copy the .qcow2, however that's a lot of diskspace. Instead you can create
a new image that's based on the contents of another file, for example::

    qemu-img create -f qcow2 -b "IE9 - Win7.qcow2" MyProject.IE9.Win7.qcow2
