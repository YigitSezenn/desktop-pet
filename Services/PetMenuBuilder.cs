using System.Windows;
using System.Windows.Controls;
using DesktopPet.Views;

namespace DesktopPet.Services;

public sealed class PetMenuBuilder
{
    private readonly MainWindow _mainWindow;
    private readonly PetSettings _settings;
    private readonly TrayService _trayService;

    public PetMenuBuilder(MainWindow mainWindow, PetSettings settings, TrayService trayService)
    {
        _mainWindow = mainWindow;
        _settings = settings;
        _trayService = trayService;
    }

    public ContextMenu BuildWpfMenu()
    {
        var menu = new ContextMenu();
        AddCommonItems(menu.Items);
        return menu;
    }

    public System.Windows.Forms.ContextMenuStrip BuildTrayMenu()
    {
        var menu = new System.Windows.Forms.ContextMenuStrip();
        AddTrayItems(menu.Items);
        return menu;
    }

    private void AddCommonItems(ItemCollection items)
    {
        var showItem = new MenuItem { Header = "Göster" };
        showItem.Click += (_, _) => _trayService.ShowPet();
        items.Add(showItem);

        var hideItem = new MenuItem { Header = "Gizle" };
        hideItem.Click += (_, _) => _trayService.HidePet();
        items.Add(hideItem);

        items.Add(new Separator());

        var renameItem = new MenuItem { Header = "İsim Değiştir..." };
        renameItem.Click += (_, _) => RenamePet();
        items.Add(renameItem);

        var startupItem = new MenuItem { Header = "Windows ile başlat", IsCheckable = true };
        startupItem.IsChecked = _settings.StartWithWindows;
        startupItem.Click += (_, _) => ToggleStartup(startupItem);
        items.Add(startupItem);

        items.Add(new Separator());

        var exitItem = new MenuItem { Header = "Kapat" };
        exitItem.Click += (_, _) => _trayService.ExitApp();
        items.Add(exitItem);
    }

    private void AddTrayItems(System.Windows.Forms.ToolStripItemCollection items)
    {
        items.Add("Göster", null, (_, _) => _trayService.ShowPet());
        items.Add("Gizle", null, (_, _) => _trayService.HidePet());
        items.Add(new System.Windows.Forms.ToolStripSeparator());
        items.Add("İsim Değiştir...", null, (_, _) => RenamePet());
        items.Add(new System.Windows.Forms.ToolStripSeparator());

        var startupItem = new System.Windows.Forms.ToolStripMenuItem("Windows ile başlat")
        {
            CheckOnClick = true,
            Checked = _settings.StartWithWindows
        };
        startupItem.CheckedChanged += (_, _) => SetStartup(startupItem.Checked);
        items.Add(startupItem);

        items.Add(new System.Windows.Forms.ToolStripSeparator());
        items.Add("Kapat", null, (_, _) => _trayService.ExitApp());
    }

    public void ShowRenameDialog()
    {
        RenamePet();
    }

    private void RenamePet()
    {
        var dialog = new NameInputDialog(_settings.PetName)
        {
            Owner = _mainWindow
        };

        if (dialog.ShowDialog() != true)
        {
            return;
        }

        _settings.PetName = dialog.PetName;
        _settings.Save();
        _mainWindow.UpdatePetName(_settings.PetName);
        _trayService.UpdateTooltip(_settings.PetName);
    }

    private void ToggleStartup(MenuItem menuItem)
    {
        SetStartup(menuItem.IsChecked);
    }

    private void SetStartup(bool enabled)
    {
        _settings.StartWithWindows = enabled;
        _settings.Save();
        StartupService.SetEnabled(enabled);
    }
}
