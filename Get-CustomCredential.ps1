Add-Type -AssemblyName System.Windows.Forms

$refAssemblies = @(
    'System.Drawing'
)
if($PSVersionTable.PSVersion.Major -ge 6)
{
    $refAssemblies += 'System.Drawing.Common'
}

Add-Type -ReferencedAssemblies $refAssemblies -IgnoreWarnings -WarningAction Ignore -TypeDefinition @'
using System; 
using System.Runtime.InteropServices;
using System.Drawing;

public class DPI
{  
    [DllImport("gdi32.dll")]
    static extern int GetDeviceCaps(IntPtr hdc, int nIndex);

    public enum DeviceCap
    {
        VERTRES = 10,
        DESKTOPVERTRES = 117
    } 

    public static float scaling()
    {
        Graphics g = Graphics.FromHwnd(IntPtr.Zero);
        IntPtr desktop = g.GetHdc();
        int LogicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.VERTRES);
        int PhysicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.DESKTOPVERTRES);

        return (float)PhysicalScreenHeight / (float)LogicalScreenHeight;
    }
}
'@

[void][System.Windows.Forms.Application]::EnableVisualStyles()
$DPI = [math]::round([dpi]::scaling(),2) * 100
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$bounds.Width = ($bounds.Width / 100) * $DPI
$bounds.Height = ($bounds.Height / 100) * $DPI

$mainForm = [System.Windows.Forms.Form]::new()
$mainForm.StartPosition = 'CenterScreen'
$mainForm.FormBorderStyle = 'Sizable'
$mainForm.Text = 'Custom Get Credential'
$mainForm.WindowState = 'Normal'
$mainForm.KeyPreview = $True
$mainForm.Font = [System.Drawing.Font]::new('Calibri',12,[System.Drawing.FontStyle]::Regular)
$mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
$mainForm.MinimumSize = [System.Drawing.Size]::new(($bounds.Width/4.5),($bounds.Height/4.5))
$mainForm.MaximumSize = [System.Drawing.Size]::new($bounds.Width,($bounds.Height/4.5))
$mainForm.MaximizeBox = $false
$mainForm.Size = $mainForm.MinimumSize

$credentialMsg = [System.Windows.Forms.Label]::new()
$credentialMsg.Location = [System.Drawing.Size]::new(10,10)
$credentialMsg.Size = [System.Drawing.Size]::new(($mainForm.Width-30),30)
$credentialMsg.Text = 'Supply values for the following parameters:'
$mainForm.Controls.Add($credentialMsg)

$userLbl = [System.Windows.Forms.Label]::new()
$userLbl.Location = [System.Drawing.Size]::new(10,50)
$userLbl.Size = [System.Drawing.Size]::new(80,30)
$userLbl.Text = 'Username'
$mainForm.Controls.Add($userLbl)

$userTxtBox = [System.Windows.Forms.TextBox]::new()
$userTxtBox.Location = [System.Drawing.Size]::new(($userLbl.Width+10),50)
$userTxtBox.Size = [System.Drawing.Size]::new(($mainForm.Width-120),60)
$mainForm.Controls.Add($userTxtBox)

$passwordLbl = [System.Windows.Forms.Label]::new()
$passwordLbl.Location = [System.Drawing.Size]::new(10,($userLbl.Location.Y+40))
$passwordLbl.Size = [System.Drawing.Size]::new(80,30)
$passwordLbl.Text = 'Password'
$mainForm.Controls.Add($passwordLbl)

$passwordTxtBox = [System.Windows.Forms.TextBox]::new()
$passwordTxtBox.Location = [System.Drawing.Size]::new(($passwordLbl.Width+10),($userTxtBox.Location.Y+40))
$passwordTxtBox.Size = [System.Drawing.Size]::new(($mainForm.Width-120),60)
$passwordTxtBox.UseSystemPasswordChar = $True
$passwordTxtBox.Anchor = 'top,left'
$mainForm.Controls.Add($passwordTxtBox)

$cancelBtn = [System.Windows.Forms.Button]::new()
$cancelBtn.Location = [System.Drawing.Size]::new(($mainForm.Width-110),($passwordTxtBox.Location.Y+40))
$cancelBtn.Size = [System.Drawing.Size]::new(80,35)
$cancelBtn.Text = '&Cancel'
$cancelBtn.Anchor = 'right,bottom'
$cancelBtn.Add_Click({
    $mainForm.DialogResult = 'Cancel'
})
$mainForm.Controls.Add($cancelBtn)

$okBtn = [System.Windows.Forms.Button]::new()
$okBtn.Location = [System.Drawing.Size]::new(($cancelBtn.Location.X-$cancelBtn.Width-5),$passwordTxtBox.Location.Y+40)
$okBtn.Size = $cancelBtn.Size
$okBtn.Text = '&OK'
$okBtn.Anchor = $cancelBtn.Anchor
$okBtn.Enabled = $false
$okBtn.Add_Click({
    $mainForm.DialogResult = 'OK'
})
$mainForm.Controls.Add($okBtn)

$okBtnEnableEvent = {
    if(
        [string]::IsNullOrWhiteSpace($userTxtBox.Text) -or 
        [string]::IsNullOrWhiteSpace($passwordTxtBox.Text)
    )
    {
        $okBtn.Enabled = $false
    }
    else
    {
        $okBtn.Enabled = $True
    }
}
$userTxtBox.Add_TextChanged($okBtnEnableEvent)
$passwordTxtBox.Add_Textchanged($okBtnEnableEvent)

$mainForm.Add_Resize({
    $userTxtBox.Size = [System.Drawing.Size]::new(($this.Width-120),60)
    $passwordTxtBox.Size = [System.Drawing.Size]::new(($this.Width-120),60)
})

$mainForm.AcceptButton = $okBtn
$mainForm.CancelButton = $cancelBtn
$mainForm.Add_Shown({ $this.Activate() })

function New-PSCredential {
param(
    [string]$Username,
    [string]$Password
)
    
    $passw = ConvertTo-SecureString $Password.Trim() -AsPlainText -Force
    [System.Management.Automation.PSCredential]::new($Username.Trim(),$passw)
}

if('OK' -eq $mainForm.ShowDialog())
{
    New-PSCredential -Username $userTxtBox.Text -Password $passwordTxtBox.Text
}

$mainForm.Dispose()
