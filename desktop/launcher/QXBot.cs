// QXBot.exe: starts the GUI (python\pythonw.exe -m desktop) from this folder, no console window.
// Built by desktop/build_windows.sh with the C# compiler that ships with Windows (.NET Framework 4).
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

static class Launcher
{
    [STAThread]
    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string py = Path.Combine(dir, "python", "pythonw.exe");
        if (!File.Exists(py) || !Directory.Exists(Path.Combine(dir, "desktop")))
        {
            MessageBox.Show("Unzip the whole QXBot folder first, then open QXBot.exe inside it.\n\n" +
                            "فك ضغط مجلد QXBot كاملاً أولاً، ثم افتح QXBot.exe من داخله.", "QXBot",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        try
        {
            Process.Start(new ProcessStartInfo(py, "-m desktop") { WorkingDirectory = dir, UseShellExecute = false });
        }
        catch (Exception e)
        {
            MessageBox.Show("QXBot could not start: " + e.Message, "QXBot", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
