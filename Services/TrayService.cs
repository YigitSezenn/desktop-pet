using System.Drawing;
using System.Windows.Forms;
using Application = System.Windows.Application;

namespace DesktopPet.Services;

public sealed class TrayService : IDisposable
{
    private readonly NotifyIcon _notifyIcon;
    private readonly MainWindow _mainWindow;
    private readonly PetSettings _settings;
    private readonly PetMenuBuilder _menuBuilder;

    public TrayService(MainWindow mainWindow, PetSettings settings)
    {
        _mainWindow = mainWindow;
        _settings = settings;
        _menuBuilder = new PetMenuBuilder(mainWindow, settings, this, mainWindow.PetAnimator);

        _notifyIcon = new NotifyIcon
        {
            Icon = LoadTrayIcon(settings.PetId),
            Text = $"Desktop Pet - {settings.PetName}",
            Visible = true,
            ContextMenuStrip = _menuBuilder.BuildTrayMenu()
        };

        _notifyIcon.DoubleClick += (_, _) => ShowPet();
    }

    public void RefreshMenu()
    {
        _notifyIcon.ContextMenuStrip = _menuBuilder.BuildTrayMenu();
    }

    public void UpdateTooltip(string petName)
    {
        _notifyIcon.Text = $"Desktop Pet - {petName}";
    }

    public void UpdateIcon(string petId)
    {
        var oldIcon = _notifyIcon.Icon;
        _notifyIcon.Icon = LoadTrayIcon(petId);
        oldIcon?.Dispose();
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
        _notifyIcon.Icon?.Dispose();
        _notifyIcon.Dispose();
    }

    private static Icon LoadTrayIcon(string petId)
    {
        var assetsPath = ResolveAssetsPath(petId);
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

    private static string ResolveAssetsPath(string petId)
    {
        var basePath = System.IO.Path.Combine(AppContext.BaseDirectory, "Assets");
        var petFolder = System.IO.Path.Combine(basePath, PetCatalog.NormalizeId(petId));
        return System.IO.Directory.Exists(petFolder) ? petFolder : basePath;
    }
}
