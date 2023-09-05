# Install the web server
Install-WindowsFeature Web-Server -IncludeManagementTools

# Start the web server
Start-Service W3SVC
set-service W3SVC -StartupType Automatic