# Copyright 2016 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

$ErrorActionPreference = "Stop"

#| Split-Path

$scriptPath =Split-Path -Parent $MyInvocation.MyCommand.Definition 

$scriptPath

Push-Location $scriptPath

git -C $scriptPath submodule update --init
if ($LASTEXITCODE) {
    throw "Failed to update git modules."
}


Import-Module .\WinImageBuilder.psm1
Import-Module .\Config.psm1
Import-Module .\UnattendResources\ini.psm1
try {
    Join-Path -Path $scriptPath -ChildPath "\WinImageBuilder.psm1" | Remove-Module -ErrorAction SilentlyContinue
    Join-Path -Path $scriptPath -ChildPath "\Config.psm1" | Remove-Module -ErrorAction SilentlyContinue
    Join-Path -Path $scriptPath -ChildPath "\UnattendResources\ini.psm1" | Remove-Module -ErrorAction SilentlyContinue
} finally {
    Join-Path -Path $scriptPath -ChildPath "\WinImageBuilder.psm1" | Import-Module
    Join-Path -Path $scriptPath -ChildPath "\Config.psm1" | Import-Module
    Join-Path -Path $scriptPath -ChildPath "\UnattendResources\ini.psm1" | Import-Module
}

# The Windows image file path that will be generated
# $windowsImagePath = "C:\images\win10-1903-AP.qcow2"
$windowsImagePath = "..\..\windows-openstack-images\images\win10-1903-AP.VHDX"

# The wim file path is the installation image on the Windows ISO
# $wimFilePath = "E:\Sources\install.wim"
$wimFilePath = "..\..\windows-openstack-images\extractedISOs\win10\sources\install.wim"

# VirtIO ISO contains all the synthetic drivers for the KVM hypervisor
$virtIOISOPath = "..\..\windows-openstack-images\virtio\virtio.iso"

# Note(avladu): Do not use stable 0.1.126 version because of this bug https://github.com/crobinso/virtio-win-pkg-scripts/issues/10
# Note (atira): Here https://fedorapeople.org/groups/virt/virtio-win/CHANGELOG you can see the changelog for the VirtIO drivers
$virtIODownloadLink = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/virtio-win-0.1.141.iso"

# Download the VirtIO drivers ISO from Fedora
#(New-Object System.Net.WebClient).DownloadFile($virtIODownloadLink, $virtIOISOPath)

# Extra drivers path contains the drivers for the baremetal nodes
# Examples: Chelsio NIC Drivers, Mellanox NIC drivers, LSI SAS drivers, etc.
# The cmdlet will recursively install all the drivers from the folder and subfolders
$extraDriversPath = "..\..\windows-openstack-images\drivers"

# Every Windows ISO can contain multiple Windows flavors like Core, Standard, Datacenter
# Usually, the second image version is the Standard one
$image = (Get-WimFileImagesInfo -WimFilePath $wimFilePath)[1]

# Make sure the switch exists and it allows Internet access if updates
# are to be installed
$switchName = 'external'

# The path were you want to create the config fille
$configFilePath = Join-Path $scriptPath "config.ini"
New-WindowsImageConfig -ConfigFilePath $configFilePath

# Customs resources path
$customResourcesPath = Join-Path $scriptPath "custom_resources"
$customResourcesPath

# Customs scripts path
$customScriptsPath = Join-Path $scriptPath "custom_scripts"
$customScriptsPath

# cloudbase_init MSI path
$cloudbase_initPath = Join-Path $scriptPath "Cloudbase-Init-MSI\CloudbaseInitSetup_0_9_11_x64.msi"

#This is an example how to automate the image configuration file according to your needs
## Default
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "wim_file_path" -Value $wimFilePath
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "image_name" -Value $image.ImageName
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "image_path" -Value $windowsImagePath

# Select between VHD, VHDX, QCOW2, VMDK or RAW formats.
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "virtual_disk_format" -Value "VHDX"

# This parameter allows to choose between MAAS, KVM, VMware and Hyper-V specific images.
# For HYPER-V, cloudbase-init will be installed and the generated image should be in vhd or vhdx format.
# For MAAS, in addition to cloudbase-init, the curtin tools are installed
# and the generated image should be in raw.tgz format.
# For KVM, in addition to cloudbase-init, the VirtIO drivers are installed
# and the generated image should be in qcow2 format
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "image_type" -Value "HYPER-V"

# This parameter can be set to either BIOS or UEFI.
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "disk_layout" -Value "BIOS"
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "install_maas_hooks" -Value "False"
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "custom_resources_path" -Value "$customResourcesPath"
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "custom_scripts_path" -Value "$customScriptsPath"
Set-IniFileValue -Path $configFilePath -Section "Default" -Key "enable_active_mode" -Value "True"
## vm
Set-IniFileValue -Path $configFilePath -Section "vm" -Key "cpu_count" -Value 4
Set-IniFileValue -Path $configFilePath -Section "vm" -Key "ram_size" -Value (4GB)
Set-IniFileValue -Path $configFilePath -Section "vm" -Key "disk_size" -Value (30GB)
Set-IniFileValue -Path $configFilePath -Section "vm" -Key "external_switch" -Value $switchName
## drivers
Set-IniFileValue -Path $configFilePath -Section "drivers" -Key "virtio_iso_path" -Value $virtIOISOPath
Set-IniFileValue -Path $configFilePath -Section "drivers" -Key "drivers_path" -Value $extraDriversPath
## updates

# Set "install_updates" -Value "True" for production builds, disabled to speed up testing
Set-IniFileValue -Path $configFilePath -Section "updates" -Key "install_updates" -Value "False"
Set-IniFileValue -Path $configFilePath -Section "updates" -Key "purge_updates" -Value "True"
## sysprep
Set-IniFileValue -Path $configFilePath -Section "sysprep" -Key "disable_swap" -Value "True"
## cloudbase_init
Set-IniFileValue -Path $configFilePath -Section "cloudbase_init" -Key "msi_path" -Value "$cloudbase_initPath"


# This scripts generates ...

#New-WindowsOnlineImage -ConfigFilePath $configFilePath
New-WindowsCloudImage -ConfigFilePath $configFilePath

Pop-Location