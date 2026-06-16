using System.IO;
using System.Linq;
using System.Windows.Controls;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace DesktopPet.Services;

public enum PetAnimationState
{
    Idle,
    Walk,
    Jump,
    Sleep
}

public sealed class PetAnimator
{
    private const int WalkFrameMs = 180;
    private const int SleepFrameMs = 650;

    private readonly System.Windows.Controls.Image _petImage;
    private readonly DispatcherTimer _animationTimer;
    private BitmapImage _idleFrame = null!;
    private BitmapImage _jumpFrame = null!;
    private BitmapImage[] _walkFrames = [];
    private BitmapImage[] _sleepFrames = [];

    private PetAnimationState _state = PetAnimationState.Idle;
    private int _frameIndex;

    public PetAnimator(System.Windows.Controls.Image petImage, string petId)
    {
        _petImage = petImage;
        _animationTimer = new DispatcherTimer();
        _animationTimer.Tick += (_, _) => AdvanceFrame();
        LoadSprites(PetCatalog.NormalizeId(petId));
    }

    public void Reload(string petId) => LoadSprites(PetCatalog.NormalizeId(petId));

    private void LoadSprites(string petId)
    {
        var assetsPath = ResolveAssetsPath(petId);

        _idleFrame = LoadSprite(Path.Combine(assetsPath, "pet_idle.png"));
        _jumpFrame = LoadSprite(Path.Combine(assetsPath, "pet_jump.png"));
        _walkFrames = Directory.GetFiles(assetsPath, "pet_walk_*.png")
            .OrderBy(f => f, StringComparer.OrdinalIgnoreCase)
            .Select(LoadSprite)
            .ToArray();
        _sleepFrames =
        [
            LoadSprite(Path.Combine(assetsPath, "pet_sleep_1.png")),
            LoadSprite(Path.Combine(assetsPath, "pet_sleep_2.png"))
        ];

        _state = PetAnimationState.Idle;
        _frameIndex = 0;
        _animationTimer.Stop();
        _petImage.Source = _idleFrame;
    }

    private static string ResolveAssetsPath(string petId)
    {
        var basePath = Path.Combine(AppContext.BaseDirectory, "Assets");
        var petFolder = Path.Combine(basePath, petId);
        if (Directory.Exists(petFolder))
        {
            return petFolder;
        }

        return basePath;
    }

    public void SetState(PetAnimationState state)
    {
        if (_state == state)
        {
            return;
        }

        _state = state;
        _frameIndex = 0;

        switch (_state)
        {
            case PetAnimationState.Idle:
                _animationTimer.Stop();
                _petImage.Source = _idleFrame;
                break;
            case PetAnimationState.Walk:
                _animationTimer.Interval = TimeSpan.FromMilliseconds(WalkFrameMs);
                _animationTimer.Start();
                AdvanceFrame();
                break;
            case PetAnimationState.Jump:
                _animationTimer.Stop();
                _petImage.Source = _jumpFrame;
                break;
            case PetAnimationState.Sleep:
                _animationTimer.Interval = TimeSpan.FromMilliseconds(SleepFrameMs);
                _animationTimer.Start();
                AdvanceFrame();
                break;
        }
    }

    private void AdvanceFrame()
    {
        switch (_state)
        {
            case PetAnimationState.Walk when _walkFrames.Length > 0:
                _petImage.Source = _walkFrames[_frameIndex];
                _frameIndex = (_frameIndex + 1) % _walkFrames.Length;
                break;
            case PetAnimationState.Sleep:
                _petImage.Source = _sleepFrames[_frameIndex];
                _frameIndex = (_frameIndex + 1) % _sleepFrames.Length;
                break;
        }
    }

    private static BitmapImage LoadSprite(string path)
    {
        var image = new BitmapImage();
        image.BeginInit();
        image.UriSource = new Uri(path, UriKind.Absolute);
        image.CacheOption = BitmapCacheOption.OnLoad;
        image.DecodePixelWidth = 32;
        image.DecodePixelHeight = 32;
        image.EndInit();
        image.Freeze();
        return image;
    }
}
