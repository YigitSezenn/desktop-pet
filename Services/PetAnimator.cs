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
    private readonly System.Windows.Controls.Image _petImage;
    private readonly DispatcherTimer _animationTimer;
    private readonly BitmapImage _idleFrame;
    private readonly BitmapImage _jumpFrame;
    private readonly BitmapImage[] _walkFrames;
    private readonly BitmapImage[] _sleepFrames;

    private PetAnimationState _state = PetAnimationState.Idle;
    private int _frameIndex;

    public PetAnimator(System.Windows.Controls.Image petImage)
    {
        _petImage = petImage;

        var assetsPath = Path.Combine(AppContext.BaseDirectory, "Assets");
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

        _petImage.Source = _idleFrame;

        _animationTimer = new DispatcherTimer();
        _animationTimer.Tick += (_, _) => AdvanceFrame();
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
                _animationTimer.Interval = TimeSpan.FromMilliseconds(120);
                _animationTimer.Start();
                AdvanceFrame();
                break;
            case PetAnimationState.Jump:
                _animationTimer.Stop();
                _petImage.Source = _jumpFrame;
                break;
            case PetAnimationState.Sleep:
                _animationTimer.Interval = TimeSpan.FromMilliseconds(450);
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
        image.EndInit();
        image.Freeze();
        return image;
    }
}
