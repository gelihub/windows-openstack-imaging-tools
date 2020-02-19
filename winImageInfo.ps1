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

#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

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
# $windowsImagePath = "C:\images\win10-1903-AP.VHDX"
#$windowsImagePath = "..\..\windows-openstack-images\images\server2019.VHDX"

# The wim file path is the installation image on the Windows ISO
# $wimFilePath = "E:\Sources\install.wim"
$wimFilePath = "..\..\windows-openstack-images\extractedISOs\server2019\sources\install.wim"

# VirtIO ISO contains all the synthetic drivers for the KVM hypervisor
$virtIOISOPath = "..\..\windows-openstack-images\virtio\virtio.iso"

# Note(avladu): Do not use stable 0.1.126 version because of this bug https://github.com/crobinso/virtio-win-pkg-scripts/issues/10
# Note (atira): Here https://fedorapeople.org/groups/virt/virtio-win/CHANGELOG you can see the changelog for the VirtIO drivers
#$virtIODownloadLink = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/virtio-win-0.1.141.iso"

# Download the VirtIO drivers ISO from Fedora
#(New-Object System.Net.WebClient).DownloadFile($virtIODownloadLink, $virtIOISOPath)

# Extra drivers path contains the drivers for the baremetal nodes
# Examples: Chelsio NIC Drivers, Mellanox NIC drivers, LSI SAS drivers, etc.
# The cmdlet will recursively install all the drivers from the folder and subfolders
$extraDriversPath = "..\..\windows-openstack-images\drivers"

# Every Windows ISO can contain multiple Windows flavors like Core, Standard, Datacenter
# Usually, the second image version is the Standard one
$image = (Get-WimFileImagesInfo -WimFilePath $wimFilePath)[1]
$image


# The path were you want to create the config fille
$configFilePath = Join-Path $scriptPath "config.ini"
New-WindowsImageConfig -ConfigFilePath $configFilePath

# Customs resources path
$customResourcesPath = Join-Path $scriptPath "custom_resources"
$customResourcesPath

# Customs scripts path
$customScriptsPath = Join-Path $scriptPath "custom_scripts"
$customScriptsPath


Pop-Location