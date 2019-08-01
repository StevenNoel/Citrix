# Citrix-Morning-Report
This script was created to run as a scheduled task that runs every day.  It will create a log file that documents All App Layering Images and the layers that make up that image.  It will also document which PVS target devices uses which image.
Tested with App Layering 4.x


# Prerequisites
You will need to install Ryan Butler's App Layering SDK found here - https://www.powershellgallery.com/packages/ctxal-sdk/

ALso, you'll need to create your Credential files via https://github.com/StevenNoel/Credentials/tree/master/CreateSecureCredsFiles

# Examples
```
.\Image-List-Details.ps1' -PVSSites PVS1 -LogDir \\NAS\Share -Aplip AppLayering01 -AESPath \\NAS\Share\aes.txt -SecurePassPath \\NAS\Share\SecurePass.txt -AppLayeringModulePath \\NAS\Share\UnideskSDK-master\UnideskSDK-master\ctxal-sdk\ctxal-sdk.psm1
```
This Example runs the script against the App Layering server 'AppLayering01', it logs the output to \\NAS\Share\(date), uses the credentials stored in the AES.txt and Securepass.txt, and looks for App Layering Images on the PVS Server 'PVS1'
```
