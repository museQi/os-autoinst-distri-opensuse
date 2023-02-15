PUBLIC CLOUD TOOLS IMAGE
========================

The Public Cloud Tools image is a modified SLES image with a pre-installed and configured set of various cloud related tools intended for testing of Cloud Service Providers (CSP) within openQA. It includes various tools like command-line interfaces for Azure, Amazon, OpenStack and Google Compute Platform (GCP). This Dockerfile helps to automatically generate the requirements for those utilities.

To generate such image, check the SUSE Confluence page [Public Cloud Tools Image](https://confluence.suse.com/pages/viewpage.action?spaceKey=qasle&title=Public+Cloud+Tools+Image).

The image creation is achieved running the test `create_hdd_autoyast_pc`, that is triggered running the command `trigger_public_cloud.pl`, as described in the page above, or cloning an old one.

From the Public Cloud main module **main_publiccloud.pm** setting PUBLIC_CLOUD_PREPARE_TOOLS=1 the *load_create_publiccloud_tools_image* routine is triggered; it calls **publiccloud/prepare_tools.pm**.

Here, the main tools are installed in a python virtualenv, based on the dependencies resources retrieved from the txt files in the folder `/var/lib/openqa/share/tests/opensuse/data/publiccloud/venv`.

The resulting qcow2 image, named as the parameter PUBLISH_HDD_1, is placed in the folder `/var/lib/openqa/share/factory/hdd`.

To use this new image in a proper test, assign the same name to the HDD_1 parameter and if the case set PUBLIC_CLOUD_SKIP_MU=1 too.


CSP CLI VIRTUALENV UPDATE
=========================

In order to update the dependency files in the virtualenvs, we use the following files:

- Dockerfile
- venv_inst.sh

The procedure is:

a) set the directory containing those files:
    
`% cd /var/lib/openqa/share/tests/opensuse/tools/pctools`

b) build the container using the current Dockerfile for BCI 15SP3 with python3:6 and assign a *name* for reference:

`% podman build . -t <name>` 

c) set a working directory, i.e. /tmp: `% cd /tmp`

d) run the container sharing the workdir with the one in SHARDIR defined in the Dockerfile, without any other parameter/command, so that the CMD instruction by default will run and copy here the files with the new versions:

`% podman run -it --rm -v $(pwd):/home/tmp <name>`

d) Compare the new generated txt and the corresponding existing txt files in the *venv* folder, to see the new versions: if all ok replace the **content** of each txt filename in venv with the new one, possibly using a new git branch before merging in master.
