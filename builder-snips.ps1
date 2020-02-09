Import-Module .\WinImageBuilder.psm1
Import-Module .\Config.psm1
Import-Module .\UnattendResources\ini.psm1
# Create a config.ini file using the built in function, then set them accordingly to your needs
$ConfigFilePath = ".\config.ini"
New-WindowsImageConfig -ConfigFilePath $ConfigFilePath

# To automate the config options setting:
Set-IniFileValue -Path (Resolve-Path $ConfigFilePath) -Section "DEFAULT" `
                                      -Key "wim_file_path" `
                                      -Value "E:\Sources\install.wim"
# Use the desired command with the config file you just created

New-WindowsOnlineImage -ConfigFilePath $ConfigFilePath





$virtIOISOPath = "C:\images2\virtio.iso"
# Note(avladu): Do not use stable 0.1.126 version because of this bug https://github.com/crobinso/virtio-win-pkg-scripts/issues/10
# Note (atira): Here https://fedorapeople.org/groups/virt/virtio-win/CHANGELOG you can see the changelog for the VirtIO drivers
$virtIODownloadLink = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/virtio-win-0.1.141.iso"

# Download the VirtIO drivers ISO from Fedora
(New-Object System.Net.WebClient).DownloadFile($virtIODownloadLink, $virtIOISOPath)