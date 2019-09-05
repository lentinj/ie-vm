modern.ie VMs under KVM/QEMU
============================

Automates the process of getting the modern.ie images and converting them for
usage with KVM. There are 3 scripts:

ie-urls.sh
    Attempt to parse the relevant .zip download URLs from the modern.ie
    page
fetch.sh (url)
    Given a URL to a VM .zip file, uncompress and convert into a QCOW2 file for use with QEMU,
    which will be waiting for you in the current directory.
    Will also support a URL to a .txt file full of .zip part URLs, although MS seem to have deprecated this.
start.sh (QCOW image)
    Fetch virtio.iso if not already there, and start the image with reasonable
    options

Prerequisites
-------------

wget & QEMU must be installed.
In addition `OVMF <https://github.com/tianocore/tianocore.github.io/wiki/OVMF>`__
is needed for running Win10 VMs.

Debian / apt-based distributions::

    apt install wget qemu-system-x86 qemu-system-gui ovmf

Using
-----

#. Ensure depenencies are installed with
   ``apt-get install wget unzip qemu-system-x86 qemu-utils``
#. Run ``ie-urls.sh`` to list available Windows / IE images, or go to http://modern.ie
   and select the VM you require and "Virtualbox", and copy the .zip location in the
   download link.
#. Run ``fetch.sh http://../IE11/IE11.Win7.VirtualBox.zip`` and wait. You can break
   out of the download and resume it at a later point if necessary.
   If you have an old version of qemu-img installed, you may need to specify ``--vmdk2``
   to patch the VMDK file before converting it.
#. Run ``start.sh (name of image)``. Or omit the name if you want to run the
   most recent QCOW2 file.
#. If the VM asks you for a login, it should be ``IEUser`` / ``Passw0rd!``.
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
