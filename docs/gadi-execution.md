## User guide: NCI Gadi execution

* [Set up the repository](#set-up)
* [Obtain a copy of your input data](#obtain-required-input-files)
* [Execute the workflow](#execute-the-workflow)
* [Monitor your execution](#monitor-your-execution)
* [Examine the results](#examine-the-results)
* [Troubleshooting errors](#troubleshooting-errors)

### Set up 

Navigate to your working directory on NCI Gadi: 

```bash
cd /scratch/<project>
```

Clone the repository and move into it: 

```bash
git clone https://github.com/Sydney-Informatics-Hub/ONT-bacpac-nf.git
cd ONT-bacpac-nf
```

Make a directory for your raw data files: 

```bash
mkdir data
```

### Obtain required input files 

Transfer your files to the working directory on Gadi from their original source: 

#### From your local machine  

Easiest way to transfer data between your local machine and an HPC is to use the FileZilla client. 

1. Go to the [Filezilla downloads page](https://filezilla-project.org/) and follow instructions to install on your computer
2. Open Filezilla and enter the following in the 'Host' field: sftp://gadi-dm.nci.org.au
3. Enter your username and password in the respective fields and click 'Quickconnect'
4. Navigate to the local site directory of choice
5. Navigate to the remote site directory of choice
6. To copy a file between local and remote, right click on the file and select 'Upload' or double click the file or drag and drop it to the desired location

#### From Sharepoint/OneDrive

Easiest way to transfer and deal with all the security settings for OneDrive/Sharepoint is to use Rclone. 

1. Go to the [Rclone downloads page](https://rclone.org/downloads/)
2. Right click on Intel/AMD - 64 bit and copy the link address 
3. Download using wget: 

```bash
wget https://downloads.rclone.org/v1.67.0/rclone-v1.67.0-linux-amd64.zip
```

4. Unzip the downloaded file:
  
```bash
unzip rclone-v1.67.0-linux-amd64.zip
```   

5. Move into the extracted directory: 

```bash
cd rclone-v1.67.0-linux-amd64
```

6. Copy the rclone binary to your bin directory, if you don't have one, create one: 

```bash
mkdir -p ~/bin
cp rclone ~/bin/
```

7. Add the bin directory to your PATH and reload your `.bashrc` to apply the changes:

```bash
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

8. Verify the installation: 

```bash 
rclone --version
```

9. Add an alias to your shell configuration file to make it easier to transfer files to Gadi: 

```bash
echo 'alias rclone="$HOME/bin/rclone"' >> ~/.bashrc
source ~/.bashrc
```

Once Rclone is installed, follow [these instructions](https://sydney-informatics-hub.github.io/tidbits/cli-transfer-to-onedrive.html) to configure your set up to transfer files from Sharepoint/OneDrive to Gadi. 

#### From RDS to Gadi

See scripts and instructions [here](https://github.com/Sydney-Informatics-Hub/Bio-toolkit/tree/main/Data-movement) for transferring files between RDS and Gadi.

### Execute the workflow

### Monitor your execution

### Examine the results

### Troubleshooting errors 