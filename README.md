# Get-CustomCredential

### DESCRIPTION
Similar to the builtin PowerShell cmdlet [`Get-Credential`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-credential?view=powershell-5.1) but this one allows resizing. Initially posted as answer to [this question](https://stackoverflow.com/questions/68240512/is-there-another-way-to-ask-for-credentials-in-powershell-but-get-credential/68240960) on StackOverflow.
    
### OUTPUTS
- [`System.Management.Automation.PSCredential`](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.pscredential?view=powershellsdk-7.0.0)

### REQUIREMENTS
- PowerShell v5.1+ (Untested on PS Core)</li>

### EXAMPLE

![examplegif](/Example/customGetCred.gif?raw=true)

### CEDITS

- Sources for DPI awareness C# code:
   - https://hinchley.net/articles/get-the-scaling-rate-of-a-display-using-powershell/
   - https://www.osdeploy.com/modules/pshot/technical/resolution-scale-and-dpi
- Special thanks to [mklement0](https://stackoverflow.com/users/45375/mklement0) for helping me improve the code.
