using System.Drawing;
using System.Windows.Forms;
using Application = System.Windows.Application;

namespace DesktopPet.Services;

public sealed class TrayService : IDisposable
{
    private readonly NotifyIcon _notifyIcon;
    private readonly MainWindow _mainWindow;

    public TrayService(MainWindow mainWindow, PetSettings settings)
    {
        _mainWindow = mainWindow;

        var menuBuilder = new PetMenuBuilder(mainWindow, settings, this);

        _notifyIcon = new NotifyIcon
        {
            Icon = LoadTrayIcon(),
            Text = $"Desktop Pet - {settings.PetName}",
            Visible = true,
            ContextMenuStrip = menuBuilder.BuildTrayMenu()
        };

        _notifyIcon.DoubleClick += (_, _) => ShowPet();
    }

    public void UpdateTooltip(string petName)
    {
        _notifyIcon.Text = $"Desktop Pet - {petName}";
    }

    public void ShowPet()
    {
        _mainWindow.Show();
        _mainWindow.ResumeWandering();
    }

    public void HidePet()
    {
        _mainWindow.Hide();
        _mainWindow.PauseWandering();
    }

    public void ExitApp()
    {
        Application.Current.Shutdown();
    }

    public void Dispose()
    {
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
    }

    private static Icon LoadTrayIcon()
    {
        var assetsPath = System.IO.Path.Combine(AppContext.BaseDirectory, "Assets");
        var iconPath = System.IO.Path.Combine(assetsPath, "pet.ico");
        if (System.IO.File.Exists(iconPath))
        {
            return new Icon(iconPath);
        }

        var pngPath = System.IO.Path.Combine(assetsPath, "pet_idle.png");
        if (System.IO.File.Exists(pngPath))
        {
            using var bitmap = new Bitmap(pngPath);
            return Icon.FromHandle(bitmap.GetHicon());
        }

        return SystemIcons.Application;
    }
}
