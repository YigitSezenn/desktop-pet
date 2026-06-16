using System.Windows.Controls;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace DesktopPet.Services;

public enum NpcAnimationState
{
    Idle,
    Walk,
    Attack
}

public sealed class NpcAnimator
{
    private readonly System.Windows.Controls.Image _npcImage;
    private readonly DispatcherTimer _animationTimer;
    private readonly BitmapImage _idleFrame;
    private readonly BitmapImage[] _walkFrames;
    private readonly BitmapImage[] _attackFrames;

    private NpcAnimationState _state = NpcAnimationState.Idle;
    private int _frameIndex;

    public NpcAnimator(System.Windows.Controls.Image npcImage)
    {
        _npcImage = npcImage;

        var assetsPath = System.IO.Path.Combine(AppContext.BaseDirectory, "Assets");
        _idleFrame = LoadSprite(System.IO.Path.Combine(assetsPath, "npc_idle.png"));
        _walkFrames =
        [
            LoadSprite(System.IO.Path.Combine(assetsPath, "npc_walk_1.png")),
            LoadSprite(System.IO.Path.Combine(assetsPath, "npc_walk_2.png"))
        ];
        _attackFrames =
        [
            LoadSprite(System.IO.Path.Combine(assetsPath, "npc_attack_1.png")),
            LoadSprite(System.IO.Path.Combine(assetsPath, "npc_attack_2.png"))
        ];

        _npcImage.Source = _idleFrame;

        _animationTimer = new DispatcherTimer();
        _animationTimer.Tick += (_, _) => AdvanceFrame();
    }

    public void SetState(NpcAnimationState state)
    {
        if (_state == state)
        {
            return;
        }

        _state = state;
        _frameIndex = 0;

        switch (_state)
        {
            case NpcAnimationState.Idle:
                _animationTimer.Stop();
                _npcImage.Source = _idleFrame;
                break;
            case NpcAnimationState.Walk:
                _animationTimer.Interval = TimeSpan.FromMilliseconds(170);
                _animationTimer.Start();
                AdvanceFrame();
                break;
            case NpcAnimationState.Attack:
                _animationTimer.Interval = TimeSpan.FromMilliseconds(120);
                _animationTimer.Start();
                AdvanceFrame();
                break;
        }
    }

    private void AdvanceFrame()
    {
        switch (_state)
        {
            case NpcAnimationState.Walk:
                _npcImage.Source = _walkFrames[_frameIndex];
                _frameIndex = (_frameIndex + 1) % _walkFrames.Length;
                break;
            case NpcAnimationState.Attack:
                _npcImage.Source = _attackFrames[_frameIndex];
                _frameIndex++;
                if (_frameIndex >= _attackFrames.Length)
                {
                    SetState(NpcAnimationState.Idle);
                }
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

