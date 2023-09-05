configuration webserver {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node localhost
    {
        # Install web server
        WindowsFeature WebServer
        {
            Ensure  = "Present"
            Name    = "Web-Server"
        }

        File HTMLFile {
            DestinationPath = "C:\inetpub\wwwroot\index.html"
            Ensure          = "Present"
            Contents        = 
'<html>
<body>
   <h2>Azure Tenta Nummer 4 Klar!</h2>
   <img src="https://www.typit.se/app/uploads/webb-arthit-saengsuriyachat-700x571.jpg">
</body>
</html>'
        }
    }
}