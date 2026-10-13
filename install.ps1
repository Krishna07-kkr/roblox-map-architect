# Universal Installer for roblox-map-architect (Skill + /roblox-map-architect Slash Command)
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Google Antigravity / Gemini Global Skill (enables both Skill & /roblox-map-architect slash command)
$AgySkillDir = Join-Path $HOME ".gemini\config\skills\roblox-map-architect"
New-Item -ItemType Directory -Force -Path $AgySkillDir | Out-Null
if ((Resolve-Path $RepoRoot).Path -ne (Resolve-Path $AgySkillDir).Path) {
    Copy-Item -Path "$RepoRoot\*" -Destination $AgySkillDir -Recurse -Force -Exclude ".git"
}

# 2. Claude Code Global Skill + /roblox-map-architect Slash Command
$ClaudeSkillDir = Join-Path $HOME ".claude\skills\roblox-map-architect"
$ClaudeCmdDir   = Join-Path $HOME ".claude\commands"
New-Item -ItemType Directory -Force -Path $ClaudeSkillDir | Out-Null
New-Item -ItemType Directory -Force -Path $ClaudeCmdDir | Out-Null
Copy-Item -Path "$RepoRoot\*" -Destination $ClaudeSkillDir -Recurse -Force -Exclude ".git"
Copy-Item -Path "$RepoRoot\commands\roblox-map-architect.md" -Destination (Join-Path $ClaudeCmdDir "roblox-map-architect.md") -Force

Write-Host "[OK] Installed roblox-map-architect Skill + /roblox-map-architect slash command for Antigravity and Claude Code."
