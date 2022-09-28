using namespace System.Windows.Forms
using namespace System.Drawing

$refAssemblies = @(
    'System.Drawing'
)
if($PSVersionTable.PSVersion.Major -ge 6) {
    $refAssemblies += 'System.Drawing.Common'
}

Add-Type -AssemblyName System.Windows.Forms
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

function Get-CustomCredential {
    [Application]::EnableVisualStyles()

    $DPI    = [math]::round([dpi]::scaling(),2) * 100
    $bounds = [Screen]::PrimaryScreen.WorkingArea
    $bounds.Width  = $bounds.Width / 100 * $DPI
    $bounds.Height = $bounds.Height / 100 * $DPI

    $mainForm = [Form]@{
        StartPosition   = 'CenterScreen'
        FormBorderStyle = 'Sizable'
        Text            = 'Get Custom Credential'
        WindowState     = 'Normal'
        KeyPreview      = $true
        Font            = [Font]::new('Calibri', 12, [FontStyle]::Regular)
        Icon            = [Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
        MinimumSize     = [Size]::new($bounds.Width / 4.5, $bounds.Height/4.5)
        MaximumSize     = [Size]::new($bounds.Width, $bounds.Height/4.5)
        MaximizeBox     = $false
    }
    $mainForm.Size = $mainForm.MinimumSize

    $credentialMsg = [Label]@{
        Location   = [Point]::new(10, 10)
        Size       = [Size]::new($mainForm.Width - 30, 30)
        Text       = 'Supply values for the following parameters:'
    }
    $mainForm.Controls.Add($credentialMsg)

    $userLbl = [Label]@{
        Location = [Point]::new(10, 50)
        Size     = [Size]::new(80, 30)
        Text     = 'Username'
    }
    $mainForm.Controls.Add($userLbl)

    $userTxtBox = [TextBox]@{
        Location = [Point]::new($userLbl.Width + 10, 50)
        Size     = [Size]::new($mainForm.Width - 120, 60)
    }
    $mainForm.Controls.Add($userTxtBox)

    $passwordLbl = [Label]@{
        Location = [Point]::new(10, $userLbl.Location.Y + 40)
        Size     = [Size]::new(80, 30)
        Text     = 'Password'
    }
    $mainForm.Controls.Add($passwordLbl)

    $passwordTxtBox = [TextBox]@{
        Location              = [Point]::new($passwordLbl.Width + 10, $userTxtBox.Location.Y + 40)
        Size                  = [Size]::new($mainForm.Width - 120, 60)
        UseSystemPasswordChar = $true
        Anchor                = 'top, left'
    }
    $mainForm.Controls.Add($passwordTxtBox)

    $cancelBtn = [Button]@{
        Location = [Point]::new($mainForm.Width - 110, $passwordTxtBox.Location.Y + 40)
        Size     = [Size]::new(80, 35)
        Text     = '&Cancel'
        Anchor   = 'right, bottom'
    }
    $cancelBtn.Add_Click({
        $mainForm.DialogResult = 'Cancel'
    })
    $mainForm.Controls.Add($cancelBtn)

    $okBtn = [Button]@{
        Location = [Size]::new($cancelBtn.Location.X - $cancelBtn.Width - 5, $passwordTxtBox.Location.Y + 40)
        Size     = $cancelBtn.Size
        Text     = '&OK'
        Anchor   = $cancelBtn.Anchor
        Enabled  = $false
    }
    $okBtn.Add_Click({
        $mainForm.DialogResult = 'OK'
    })
    $mainForm.Controls.Add($okBtn)

    $okBtnEnableEvent = {
        if([string]::IsNullOrWhiteSpace($userTxtBox.Text) -or [string]::IsNullOrWhiteSpace($passwordTxtBox.Text)) {
            $okBtn.Enabled = $false
            return
        }
        $okBtn.Enabled = $True

    }
    $userTxtBox.Add_TextChanged($okBtnEnableEvent)
    $passwordTxtBox.Add_Textchanged($okBtnEnableEvent)

    $mainForm.Add_Resize({
        $userTxtBox.Size     = [Size]::new($this.Width - 120, 60)
        $passwordTxtBox.Size = [Size]::new($this.Width - 120, 60)
    })
    $mainForm.AcceptButton = $okBtn
    $mainForm.CancelButton = $cancelBtn
    $mainForm.Add_Shown({ $this.Activate() })

    if('OK' -eq $mainForm.ShowDialog()) {
        $passw = ConvertTo-SecureString $passwordTxtBox.Text.Trim() -AsPlainText -Force
        [System.Management.Automation.PSCredential]::new($userTxtBox.Text.Trim(), $passw)
    }

    $mainForm.Dispose()
}

Get-CustomCredential