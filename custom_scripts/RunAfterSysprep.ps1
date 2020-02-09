#ps1

# Copy Autopilot profile
Copy-Item "$ENV:SystemDrive\UnattendResources\CustomResources\AutopilotConfigurationFile.json" -Destination "$ENV:SystemDrive\windows\provisioning\Autopilot" -Force