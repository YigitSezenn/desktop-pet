using Microsoft.Win32;

namespace DesktopPet.Services;

public static class StartupService
{
  private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
  private const string AppName = "DesktopPet";

  public static bool IsEnabled()
  {
    using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, false);
    return key?.GetValue(AppName) is string;
  }

  public static void SetEnabled(bool enabled)
  {
    using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, true);
    if (key is null)
    {
      return;
    }

    if (enabled)
    {
      var exePath = Environment.ProcessPath
          ?? System.IO.Path.Combine(AppContext.BaseDirectory, "DesktopPet.exe");
      key.SetValue(AppName, $"\"{exePath}\"");
      return;
    }

    key.DeleteValue(AppName, false);
  }
}
