namespace DesktopPet.Services;

public sealed record PetDefinition(string Id, string DisplayName, string DefaultName);

public static class PetCatalog
{
    public static IReadOnlyList<PetDefinition> All { get; } =
    [
        new("fox", "Tilki", "Mochi"),
        new("wolf", "Kurt", "Koda"),
        new("cat", "Kedi", "Luna"),
        new("dog", "Köpek", "Buddy"),
        new("penguin", "Penguen", "Pipo")
    ];

    public static PetDefinition? Find(string id) =>
        All.FirstOrDefault(p => string.Equals(p.Id, id, StringComparison.OrdinalIgnoreCase));

    public static string NormalizeId(string? id) =>
        Find(id ?? "")?.Id ?? All[0].Id;
}
