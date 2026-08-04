# Custom warm-light theme, generated from 'mini.hues' in the Neovim config.
# Palette source of truth: ~/.config/palette.json (chezmoi-managed).
$Palette = @{
    Bg     = 0xece4d8
    BgMid  = 0xcac3b7
    Fg     = 0x2e2a22
    FgMid2 = 0x69645b
    Red    = 0x6d0022
    Orange = 0x7d4200
    Yellow = 0x6f6600
    Green  = 0x005f24
    Cyan   = 0x008180
    Azure  = 0x005b86
    Blue   = 0x290774
    Purple = 0x570056
}
function fg($name) { $PSStyle.Foreground.FromRgb($Palette[$name]) }
function bgc($name) { $PSStyle.Background.FromRgb($Palette[$name]) }

# PSReadLine syntax highlighting
$Colors = @{
    ContinuationPrompt     = fg 'Cyan'
    Emphasis               = fg 'Red'
    Selection              = bgc 'BgMid'

    InlinePrediction       = fg 'FgMid2'
    ListPrediction         = fg 'Purple'
    ListPredictionSelected = bgc 'BgMid'

    Command                = fg 'Blue'
    Comment                = fg 'FgMid2'
    Default                = fg 'Fg'
    Error                  = fg 'Red'
    Keyword                = fg 'Azure'
    Member                 = fg 'Orange'
    Number                 = fg 'Purple'
    Operator               = fg 'Cyan'
    Parameter              = fg 'Yellow'
    String                 = fg 'Green'
    Type                   = fg 'Azure'
    Variable               = fg 'Orange'
}
Set-PSReadLineOption -Colors $Colors

# PowerShell's own formatting output (errors, verbose, tables, etc.)
$PSStyle.Formatting.Debug = fg 'Cyan'
$PSStyle.Formatting.Error = fg 'Red'
$PSStyle.Formatting.ErrorAccent = fg 'Blue'
$PSStyle.Formatting.FormatAccent = fg 'Azure'
$PSStyle.Formatting.TableHeader = fg 'Orange'
$PSStyle.Formatting.Verbose = fg 'Yellow'
$PSStyle.Formatting.Warning = fg 'Orange'

# Directory listings (Get-ChildItem/ls) - override default blue background
$PSStyle.FileInfo.Directory = fg 'Blue'
$PSStyle.FileInfo.SymbolicLink = fg 'Orange'
$PSStyle.FileInfo.Executable = fg 'Green'

# Git-aware prompt
Import-Module posh-git
$GitPromptSettings.DefaultPromptPrefix.Text = "$([char]0x2192) " # arrow unicode symbol
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = fg 'Green'
$GitPromptSettings.DefaultPromptPath.ForegroundColor = fg 'Cyan'
$GitPromptSettings.DefaultPromptSuffix.Text = "$([char]0x203A) " # chevron unicode symbol
$GitPromptSettings.DefaultPromptSuffix.ForegroundColor = fg 'Purple'
$GitPromptSettings.BeforeStatus.ForegroundColor = fg 'Blue'
$GitPromptSettings.BranchColor.ForegroundColor = fg 'Blue'
$GitPromptSettings.AfterStatus.ForegroundColor = fg 'Blue'
