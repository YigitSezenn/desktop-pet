using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;
using DesktopPet.Services;

namespace DesktopPet;

public partial class MainWindow : Window
{
    private const int GwlExstyle = -20;
    private const int WsExToolwindow = 0x00000080;
    private const int WsExNoactivate = 0x08000000;

    private const double RoamZoneWidth = 400;
    private const double EdgeMarginLeft = 16;
    private const double EdgeMarginBottom = 8;
    private const double WanderSpeed = 1.6;
    private const double ArrivalDistance = 6;
    private const double JumpHeight = 30;

    private readonly DispatcherTimer _wanderTimer;
    private readonly DispatcherTimer _speechTimer;
    private readonly Random _random = new();
    private readonly PetSettings _settings;
    private readonly PetAnimator _petAnimator;
    private readonly TrayService _trayService;
    private readonly PetMenuBuilder _menuBuilder;

    private double _targetX;
    private bool _isDragging;
    private bool _isWanderingPaused;
    private bool _isPerformingAction;
    private System.Windows.Point _dragOffset;
    private double _groundTop;

    public MainWindow()
    {
        InitializeComponent();

        _settings = PetSettings.Load();
        _petAnimator = new PetAnimator(PetImage);
        _trayService = new TrayService(this, _settings);
        _menuBuilder = new PetMenuBuilder(this, _settings, _trayService);

        _wanderTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(33) };
        _wanderTimer.Tick += OnWanderTick;

        _speechTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(12) };
        _speechTimer.Tick += (_, _) => MaybeSaySomething();

        Loaded += OnLoaded;
        Closed += (_, _) => _trayService.Dispose();
    }

    public void UpdatePetName(string name)
    {
        PetNameText.Text = name;
        NameBubble.Visibility = string.IsNullOrWhiteSpace(name)
            ? Visibility.Collapsed : Visibility.Visible;
    }

    public void PauseWandering()
    {
        _isWanderingPaused = true;
        _petAnimator.SetState(PetAnimationState.Idle);
    }

    public void ResumeWandering()
    {
        _isWanderingPaused = false;
        PickNewWanderTarget();
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        PlaceAtBottomLeft();
        UpdatePetName(_settings.PetName);

        if (_settings.StartWithWindows)
            StartupService.SetEnabled(true);

        var handle = new WindowInteropHelper(this).Handle;
        var ext = GetWindowLong(handle, GwlExstyle);
        SetWindowLong(handle, GwlExstyle, ext | WsExToolwindow | WsExNoactivate);

        PickNewWanderTarget();
        _wanderTimer.Start();
        _speechTimer.Start();
    }

    // ─── Hareket döngüsü ───────────────────────────────────────────────────
    private void OnWanderTick(object? sender, EventArgs e)
    {
        if (_isDragging || _isWanderingPaused || _isPerformingAction) return;

        Top = _groundTop;                      // Y sabit — sadece sağ-sol
        var dx = _targetX - Left;
        var dist = Math.Abs(dx);

        if (dist < ArrivalDistance)
        {
            _petAnimator.SetState(PetAnimationState.Idle);
            TryRandomAction();
            return;
        }

        _petAnimator.SetState(PetAnimationState.Walk);
        Left += Math.Sign(dx) * WanderSpeed;
        UpdateFacing(dx);
    }

    private void TryRandomAction()
    {
        var roll = _random.Next(100);

        if (roll < 25)       { _ = PlaySleepAsync(); return; }
        if (roll < 50)       { _ = PlayJumpAsync();  return; }
        PickNewWanderTarget();
    }

    private async Task PlayJumpAsync()
    {
        _isPerformingAction = true;
        _petAnimator.SetState(PetAnimationState.Jump);

        const int steps = 20;
        var ground = _groundTop;
        for (var i = 0; i <= steps; i++)
        {
            Top = ground - Math.Sin(i / (double)steps * Math.PI) * JumpHeight;
            await Task.Delay(25);
        }
        Top = ground;

        _petAnimator.SetState(PetAnimationState.Idle);
        _isPerformingAction = false;
        PickNewWanderTarget();
    }

    private async Task PlaySleepAsync()
    {
        _isPerformingAction = true;
        _petAnimator.SetState(PetAnimationState.Sleep);

        await Task.Delay(_random.Next(3000, 6000));

        _petAnimator.SetState(PetAnimationState.Idle);
        _isPerformingAction = false;
        PickNewWanderTarget();
    }

    private void PickNewWanderTarget()
    {
        var workArea = SystemParameters.WorkArea;
        var minX = workArea.Left + EdgeMarginLeft;
        var maxX = minX + Math.Max(0, RoamZoneWidth - Width);
        _targetX = minX + _random.NextDouble() * (maxX - minX);
    }

    private void PlaceAtBottomLeft()
    {
        var workArea = SystemParameters.WorkArea;
        Left = workArea.Left + EdgeMarginLeft;
        Top = workArea.Bottom - Height - EdgeMarginBottom;
        _groundTop = Top;
    }

    private void ClampToWorkArea()
    {
        var workArea = SystemParameters.WorkArea;
        Left = Math.Clamp(Left, workArea.Left, workArea.Right - Width);
        Top  = Math.Clamp(Top,  workArea.Top,  workArea.Bottom - Height);
    }

    private void UpdateFacing(double dx)
    {
        // Sprite varsayilan olarak SOLA bakiyor; saga giderken aynala
        PetVisual.RenderTransformOrigin = new System.Windows.Point(0.5, 0.5);
        PetVisual.RenderTransform = dx > 0
            ? new ScaleTransform(-1, 1)
            : new ScaleTransform(1, 1);
    }

    // ─── Fare olayları ─────────────────────────────────────────────────────
    private void OnMouseDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ChangedButton != MouseButton.Left) return;
        _isDragging = true;
        _dragOffset = e.GetPosition(this);
        _petAnimator.SetState(PetAnimationState.Walk);
        CaptureMouse();
    }

    private void OnMouseMove(object sender, System.Windows.Input.MouseEventArgs e)
    {
        if (!_isDragging) return;
        var sp = PointToScreen(e.GetPosition(this));
        var prevLeft = Left;
        Left = sp.X - _dragOffset.X;
        Top  = sp.Y - _dragOffset.Y;
        ClampToWorkArea();
        if (Math.Abs(Left - prevLeft) > 0.1)
            UpdateFacing(Left - prevLeft);
    }

    private void OnMouseUp(object sender, MouseButtonEventArgs e)
    {
        if (e.ChangedButton != MouseButton.Left || !_isDragging) return;
        _isDragging = false;
        _petAnimator.SetState(PetAnimationState.Idle);
        ReleaseMouseCapture();
        _groundTop = Top;
        PickNewWanderTarget();
    }

    // ─── Konuşma balonu ────────────────────────────────────────────────────
    private void MaybeSaySomething()
    {
        if (_isDragging || _isWanderingPaused) return;
        if (_random.Next(100) >= 55) return;

        string[] lines =
        [
            "voff!", "neresi?", "kovalıyorum~",
            "zzzz...", "bu böyle olmaz!", "hey!",
            "koşuyorum!", "dur bakalım..."
        ];
        SetSpeech(lines[_random.Next(lines.Length)]);
        _ = Task.Run(async () =>
        {
            await Task.Delay(2800);
            Dispatcher.Invoke(() => SetSpeech(null));
        });
    }

    private void SetSpeech(string? text)
    {
        PetSpeechText.Text = text ?? "";
        SpeechBubble.Visibility = string.IsNullOrWhiteSpace(text)
            ? Visibility.Collapsed : Visibility.Visible;
    }

    private void OnDoubleClick(object sender, MouseButtonEventArgs e)
    {
        _menuBuilder.ShowRenameDialog();
        e.Handled = true;
    }

    private void OnRightClick(object sender, MouseButtonEventArgs e)
    {
        var menu = _menuBuilder.BuildWpfMenu();
        menu.PlacementTarget = PetRoot;
        menu.IsOpen = true;
        e.Handled = true;
    }

    [DllImport("user32.dll")]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
}
