using System.Text.Json;

namespace DesktopPet.Services;

public sealed class PetSettings
{
  private static readonly string SettingsDirectory = System.IO.Path.Combine(
      Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
      "DesktopPet");

  private static readonly string SettingsPath = System.IO.Path.Combine(SettingsDirectory, "settings.json");

  public string PetId { get; set; } = "fox";
  public string PetName { get; set; } = "Mochi";
  public bool StartWithWindows { get; set; } = true;

  public static PetSettings Load()
  {
    try
    {
      if (!System.IO.File.Exists(SettingsPath))
      {
        return new PetSettings();
      }

      var json = System.IO.File.ReadAllText(SettingsPath);
      return JsonSerializer.Deserialize<PetSettings>(json) ?? new PetSettings();
    }
    catch
    {
      return new PetSettings();
    }
  }

  public void Save()
  {
    System.IO.Directory.CreateDirectory(SettingsDirectory);
    var json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
    System.IO.File.WriteAllText(SettingsPath, json);
  }
}
