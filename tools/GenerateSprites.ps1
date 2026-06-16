Add-Type -AssemblyName System.Drawing

$assetsPath = Join-Path $PSScriptRoot "..\Assets"
New-Item -ItemType Directory -Force -Path $assetsPath | Out-Null

# Renk paleti — sevimli turuncu kedi
$T  = [System.Drawing.Color]::FromArgb(0,   0,   0,   0)    # şeffaf
$Bo = [System.Drawing.Color]::FromArgb(255, 255, 165,  80)   # ana turuncu gövde
$Bs = [System.Drawing.Color]::FromArgb(255, 220, 130,  50)   # gölge/koyu turuncu
$Bh = [System.Drawing.Color]::FromArgb(255, 255, 200, 140)   # highlight/açık
$Wh = [System.Drawing.Color]::FromArgb(255, 255, 245, 230)   # beyaz (göbek/yüz)
$Ey = [System.Drawing.Color]::FromArgb(255,  30,  30,  60)   # göz siyahı
$Eg = [System.Drawing.Color]::FromArgb(255,  80, 200, 120)   # yeşil iris
$Ns = [System.Drawing.Color]::FromArgb(255, 240, 130, 150)   # pembe burun
$Mo = [System.Drawing.Color]::FromArgb(255,  80,  40,  20)   # ağız/bıyık
$Zz = [System.Drawing.Color]::FromArgb(255, 160, 200, 255)   # uyku Zz rengi

# NPC (savaşçı) paleti
$Nk = [System.Drawing.Color]::FromArgb(255, 40, 40, 55)      # outline
$Ns2 = [System.Drawing.Color]::FromArgb(255, 170, 190, 220)  # metal
$Ng2 = [System.Drawing.Color]::FromArgb(255, 110, 130, 160)  # metal gölge
$Nr = [System.Drawing.Color]::FromArgb(255, 190, 60, 70)     # pelerin
$Nb = [System.Drawing.Color]::FromArgb(255, 120, 80, 45)     # kemer/deri
$Ny = [System.Drawing.Color]::FromArgb(255, 255, 220, 150)   # ten

$colorMap = @{
    '.' = $T
    'o' = $Bo
    's' = $Bs
    'h' = $Bh
    'w' = $Wh
    'e' = $Ey
    'g' = $Eg
    'n' = $Ns
    'm' = $Mo
    'z' = $Zz
    'k' = $Nk
    'A' = $Ns2   # metal (A)  NOTE: PowerShell keys are case-insensitive; avoid m/M, g/G
    'C' = $Ng2   # metal gölge (C)
    'R' = $Nr
    'b' = $Nb
    'y' = $Ny
}

function New-FrameBitmap {
    param([string[]]$Rows, [int]$Size = 32)

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $Size; $y++) {
        $row = if ($y -lt $Rows.Length) { $Rows[$y] } else { '.' * $Size }
        for ($x = 0; $x -lt $Size; $x++) {
            $ch = if ($x -lt $row.Length) { $row[$x] } else { '.' }
            $color = if ($colorMap.ContainsKey("$ch")) { $colorMap["$ch"] } else { $T }
            $bitmap.SetPixel($x, $y, $color)
        }
    }
    return $bitmap
}

function Save-Frame {
    param([string]$Name, [string[]]$Rows)
    $bitmap = New-FrameBitmap -Rows $Rows
    $path = Join-Path $assetsPath $Name
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    Write-Host "Created $path"
}

# ================================================================
#  IDLE — duruyor, gözler açık, kuyruk aşağıda
# ================================================================
$idle = @(
    "................................",  #  0
    "................................",  #  1
    "....ss..............ss..........",  #  2
    "...ssss............ssss.........",  #  3
    "...sooo............oooo.........",  #  4
    "....oooooooooooooooooo..........",  #  5
    "...oooooooooooooooooooo.........",  #  6
    "..ooooooooooooooooooooos........",  #  7
    "..ooohhoooooooooohhoooos........",  #  8
    "..ooohhoooooooooohhoooos........",  #  9
    "..oooooooooooooooooooooos.......",  # 10
    "..ooowwwwooooooowwwwoooos.......",  # 11
    "..oooweegwooooowgeewoooos.......",  # 12
    "..oooweegwooooowgeewoooos.......",  # 13
    "..ooowwwwooooooowwwwoooos.......",  # 14
    "..oooooooonoooooooooooos........",  # 15
    "...oooooommmooooooooooo.........",  # 16
    "...oooooooooooooooooooo.........",  # 17
    "...ooooooooooooooooooo..........",  # 18
    "....oooooooooooooooooo..........",  # 19
    ".....oooooooooooooooo...........",  # 20
    ".....soooooooooooooos...........",  # 21
    ".....sooo......oooos............",  # 22
    ".....ssos......soos.............",  # 23
    ".....ss.........ss..............",  # 24
    "................................",  # 25
    "................................",  # 26
    "..............................ss",  # 27
    ".............................soos",  # 28 kuyruk
    "............................sooos",  # 29
    ".............................soos",  # 30
    "..............................ss"   # 31
)

# ================================================================
#  WALK 1 — sol bacak öne
# ================================================================
$walk1 = @(
    "................................",
    "................................",
    "....ss..............ss..........",
    "...ssss............ssss.........",
    "...sooo............oooo.........",
    "....oooooooooooooooooo..........",
    "...oooooooooooooooooooo.........",
    "..ooooooooooooooooooooos........",
    "..ooohhoooooooooohhoooos........",
    "..ooohhoooooooooohhoooos........",
    "..oooooooooooooooooooooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooweegwooooowgeewoooos.......",
    "..oooweegwooooowgeewoooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooooooonoooooooooooos........",
    "...oooooommmooooooooooo.........",
    "...oooooooooooooooooooo.........",
    "...ooooooooooooooooooo..........",
    "....oooooooooooooooooo..........",
    ".....oooooooooooooooo...........",
    ".....soooooooooooooos...........",
    "....ssoos......oooss............",
    "...ssoos.......ooss.............",
    "...ss...........ss..............",
    "..ss............s...............",
    "..s....................s.........",
    ".............................ss..",
    "............................soos.",
    "...........................sooos.",
    "............................soos.",
    ".............................ss.."
)

# ================================================================
#  WALK 2 — sağ bacak öne
# ================================================================
$walk2 = @(
    "................................",
    "................................",
    "....ss..............ss..........",
    "...ssss............ssss.........",
    "...sooo............oooo.........",
    "....oooooooooooooooooo..........",
    "...oooooooooooooooooooo.........",
    "..ooooooooooooooooooooos........",
    "..ooohhoooooooooohhoooos........",
    "..ooohhoooooooooohhoooos........",
    "..oooooooooooooooooooooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooweegwooooowgeewoooos.......",
    "..oooweegwooooowgeewoooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooooooonoooooooooooos........",
    "...oooooommmooooooooooo.........",
    "...oooooooooooooooooooo.........",
    "...ooooooooooooooooooo..........",
    "....oooooooooooooooooo..........",
    ".....oooooooooooooooo...........",
    ".....soooooooooooooos...........",
    ".....ooss......ssoo.............",
    ".....oss........sso.............",
    ".....ss..........ss.............",
    "......s...........s.............",
    ".............................ss..",
    "............................soos.",
    "...........................sooos.",
    "............................soos.",
    ".............................ss..",
    "................................"
)

# ================================================================
#  JUMP — zıplama, bacaklar açık aşağıda
# ================================================================
$jump = @(
    "................................",
    "....ss..............ss..........",
    "...ssss............ssss.........",
    "...sooo............oooo.........",
    "....oooooooooooooooooo..........",
    "...oooooooooooooooooooo.........",
    "..ooooooooooooooooooooos........",
    "..ooohhoooooooooohhoooos........",
    "..ooohhoooooooooohhoooos........",
    "..oooooooooooooooooooooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooweegwooooowgeewoooos.......",
    "..oooweegwooooowgeewoooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooooooonoooooooooooos........",
    "...oooooommmooooooooooo.........",
    "...oooooooooooooooooooo.........",
    "...ooooooooooooooooooo..........",
    "....oooooooooooooooooo..........",
    ".....sooooooooooooooos..........",
    "....ss.ooooooooooooo.ss.........",
    "...ss..ooooooooooooo..ss........",
    "..ss...soos.....soos...ss.......",
    ".ss....sss.......sss....ss......",
    "ss......ss.......ss......ss.....",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

# ================================================================
#  SLEEP 1 — gözler kapalı, rahat
# ================================================================
$sleep1 = @(
    "................................",
    "................................",
    "....ss..............ss..........",
    "...ssss............ssss.........",
    "...sooo............oooo.........",
    "....oooooooooooooooooo..........",
    "...oooooooooooooooooooo.........",
    "..ooooooooooooooooooooos........",
    "..ooohhoooooooooohhooos.........",
    "..ooohhoooooooooohhooos.........",
    "..oooooooooooooooooooooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooweemwooooowmeewoooos.......",   # m = kapalı göz (___) 
    "..ooowwwwooooooowwwwoooos.......",
    "..oooooooonoooooooooooos........",
    "...oooooommmooooooooooo.........",
    "...oooooooooooooooooooo.........",
    "...ooooooooooooooooooo..........",
    "....oooooooooooooooooo..........",
    "....soooooooooooooooos..........",
    "....sooooooooooooooos...........",
    "....soos.......sooos............",
    "....sss.........ssss............",
    "...............z................",   # Zz
    "..............zz................",
    ".............zzz................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

# ================================================================
#  SLEEP 2 — gözler kapalı, hafif farklı Zz pozisyonu
# ================================================================
$sleep2 = @(
    "................................",
    "................................",
    "....ss..............ss..........",
    "...ssss............ssss.........",
    "...sooo............oooo.........",
    "....oooooooooooooooooo..........",
    "...oooooooooooooooooooo.........",
    "..ooooooooooooooooooooos........",
    "..ooohhoooooooooohhooos.........",
    "..ooohhoooooooooohhooos.........",
    "..oooooooooooooooooooooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooweemwooooowmeewoooos.......",
    "..ooowwwwooooooowwwwoooos.......",
    "..oooooooonoooooooooooos........",
    "...oooooommmooooooooooo.........",
    "...oooooooooooooooooooo.........",
    "...ooooooooooooooooooo..........",
    "....oooooooooooooooooo..........",
    "....soooooooooooooooos..........",
    "....sooooooooooooooos...........",
    "....soos.......sooos............",
    "....sss.........ssss............",
    "..............z..................",
    ".............zz..................",
    "............zzz..................",
    "...........zzzz..................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

Save-Frame "pet_idle.png"    $idle
Save-Frame "pet_walk_1.png"  $walk1
Save-Frame "pet_walk_2.png"  $walk2
Save-Frame "pet_jump.png"    $jump
Save-Frame "pet_sleep_1.png" $sleep1
Save-Frame "pet_sleep_2.png" $sleep2

# ================================================================
#  NPC (Savaşçı) — basit 32×32, idle/walk/attack
#  Semboller: k(outline) A(metal) C(gölge) R(pelerin) b(deri) y(ten)
# ================================================================
$npc_idle = @(
    "................................",
    "................................",
    ".............kkkk...............",
    "............kAAAk...............",
    "...........kAyyAk...............",
    "...........kAyyAk...............",
    "............kAAk................",
    "...........kAAAAk...............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "...........kAAAAk...............",
    "...........kbbbk................",
    "..........kRbbRk................",
    ".........kRRRRRk................",
    ".........kRRRRRk................",
    "..........kRRRk.................",
    "...........kRk..................",
    "...........kAk..................",
    "..........kAAAk.................",
    "..........kAAAk.................",
    "...........kAk..................",
    "...........kAk..................",
    "..........kCkCk.................",
    ".........kCCkCCk................",
    ".........kkkkkkk................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

$npc_walk1 = @(
    "................................",
    "................................",
    ".............kkkk...............",
    "............kAAAk...............",
    "...........kAyyAk...............",
    "...........kAyyAk...............",
    "............kAAk................",
    "...........kAAAAk...............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "...........kAAAAk...............",
    "...........kbbbk................",
    "..........kRbbRk................",
    ".........kRRRRRk................",
    ".........kRRRRRk................",
    "..........kRRRk.................",
    "...........kRk..................",
    "...........kAk..................",
    "..........kAAAk.................",
    "..........kAAAk.................",
    "...........kAk..................",
    "..........kAk...................",
    ".........kCkCk..................",
    "........kCCkCCk.................",
    "........kkkkkkk.................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

$npc_walk2 = @(
    "................................",
    "................................",
    ".............kkkk...............",
    "............kAAAk...............",
    "...........kAyyAk...............",
    "...........kAyyAk...............",
    "............kAAk................",
    "...........kAAAAk...............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "...........kAAAAk...............",
    "...........kbbbk................",
    "..........kRbbRk................",
    ".........kRRRRRk................",
    ".........kRRRRRk................",
    "..........kRRRk.................",
    "...........kRk..................",
    "...........kAk..................",
    "..........kAAAk.................",
    "..........kAAAk.................",
    "...........kAk..................",
    "............kAk.................",
    "...........kCkCk................",
    "..........kCCkCCk...............",
    "..........kkkkkkk...............",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

$npc_attack1 = @(
    "................................",
    "................................",
    ".............kkkk...............",
    "............kAAAk...............",
    "...........kAyyAk...............",
    "...........kAyyAk...............",
    "............kAAk................",
    "...........kAAAAk...............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "...........kAAAAk...............",
    "...........kbbbk................",
    "..........kRbbRk................",
    ".........kRRRRRk................",
    ".........kRRRRRk................",
    "..........kRRRk.................",
    "...........kRk..................",
    "...........kAk......kkkkk.......",
    "..........kAAAk....kAAAAk.......",
    "..........kAAAk...kAACCAAk......",
    "...........kAk....kAAAAAAk......",
    "...........kAk.....kAAAAk.......",
    "..........kCkCk.....kkkk........",
    ".........kCCkCCk................",
    ".........kkkkkkk................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

$npc_attack2 = @(
    "................................",
    "................................",
    ".............kkkk...............",
    "............kAAAk...............",
    "...........kAyyAk...............",
    "...........kAyyAk...............",
    "............kAAk................",
    "...........kAAAAk...............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "..........kAACCAAk..............",
    "...........kAAAAk...............",
    "...........kbbbk................",
    "..........kRbbRk................",
    ".........kRRRRRk................",
    ".........kRRRRRk........kkkk....",
    "..........kRRRk........kAAAAk...",
    "...........kRk........kAACCAAk..",
    "...........kAk........kAAAAAAk..",
    "..........kAAAk........kAAAAk...",
    "..........kMMMk.........kkkk....",
    "...........kMk..................",
    "...........kMk..................",
    "..........kGkGk.................",
    ".........kGGkGGk................",
    ".........kkkkkkk................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
)

Save-Frame "npc_idle.png"     $npc_idle
Save-Frame "npc_walk_1.png"   $npc_walk1
Save-Frame "npc_walk_2.png"   $npc_walk2
Save-Frame "npc_attack_1.png" $npc_attack1
Save-Frame "npc_attack_2.png" $npc_attack2

# İkon için idle kullan
$iconBitmap = New-FrameBitmap -Rows $idle
$iconPath = Join-Path $assetsPath "pet.ico"
$iconHandle = [System.Drawing.Icon]::FromHandle($iconBitmap.GetHicon())
$stream = [System.IO.File]::Create($iconPath)
$iconHandle.Save($stream)
$stream.Close()
$iconHandle.Dispose()
$iconBitmap.Dispose()
Write-Host "Created $iconPath"
