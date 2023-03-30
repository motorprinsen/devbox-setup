# Since RefreshEnv is provided by Chocolatey (which isn't installed yet) we must roll our own
function Refresh-Environment {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function removeApp {
	Param ([string]$appName)
	Write-Host "Trying to remove $appName"
	Get-AppxPackage $appName -AllUsers | Remove-AppxPackage
	Get-AppXProvisionedPackage -Online | Where DisplayName -like $appName | Remove-AppxProvisionedPackage -Online
}

# I don't really believe in it... Whenever someone ports sudo to Windows I'm going all-in
Disable-UAC

$applicationList = @(
	"Microsoft.BingFinance"
	"Microsoft.3DBuilder"
	"Microsoft.BingNews"
	"Microsoft.BingSports"
	"Microsoft.BingWeather"
	"Microsoft.CommsPhone"
	"Microsoft.Getstarted"
	"Microsoft.WindowsMaps"
	"*MarchofEmpires*"
	"Microsoft.GetHelp"
	"Microsoft.Messaging"
	"*Minecraft*"
	"Microsoft.MicrosoftOfficeHub"
	"Microsoft.OneConnect"
	"Microsoft.WindowsPhone"
	"Microsoft.WindowsSoundRecorder"
	"*Solitaire*"
	"Microsoft.MicrosoftStickyNotes"
	"Microsoft.Office.Sway"
	"Microsoft.XboxApp"
	"Microsoft.XboxIdentityProvider"
	"Microsoft.XboxGameOverlay"
	"Microsoft.XboxGamingOverlay"
	"Microsoft.ZuneMusic"
	"Microsoft.ZuneVideo"
	"Microsoft.NetworkSpeedTest"
	"Microsoft.FreshPaint"
	"Microsoft.Print3D"
	"Microsoft.People*"
	"Microsoft.Microsoft3DViewer"
	"Microsoft.MixedReality.Portal*"
	"*Skype*"
	"*Autodesk*"
	"*BubbleWitch*"
    "king.com*"
    "G5*"
	"*Facebook*"
	"*Keeper*"
	"*Netflix*"
	"*Twitter*"
	"*Plex*"
	"*.Duolingo-LearnLanguagesforFree"
	"*.EclipseManager"
	"ActiproSoftwareLLC.562882FEEB491" # Code Writer
	"*.AdobePhotoshopExpress"
);

foreach ($app in $applicationList) {
    removeApp $app
}

Write-Host "Configuring FileExplorer"

# Show hidden files, Show protected OS files, Show file extensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

# Taskbar on main display and where window is open for multi-monitor
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MMTaskbarEnabled -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MMTaskbarMode -Value 1

# Switch to dark theme
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0

# Night light is unfortunately tricky to set. Will have to do it manually...

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Hyper-V required for docker and other things
Write-Host "Enabling Hyper-V"
Enable-WindowsOptionalFeature -Online -FeatureName:Microsoft-Hyper-V -All -NoRestart

Write-Host "Installing docker"
choco install docker-desktop --yes

Write-Host "Installing git"
choco install git --yes --params '/GitAndUnixToolsOnPath'
Refresh-Environment

Write-Host "Configuring git"
git config --global core.editor "code --wait"
git config --global init.defaultBranch main
git config --global user.name "Anders Ågren"
git config --global user.email anders.agren@rssoftware.se

# Aliases
git config --global alias.pom 'pull origin main'
git config --global alias.last 'log -1 HEAD'
git config --global alias.ls "log --pretty=format:'%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]' --decorate --date=short --graph"
git config --global alias.standup "log --since yesterday --author $(git config user.email) --pretty=short"
git config --global alias.ammend "commit -a --amend"
git config --global alias.everything "! git pull && git submodule update --init --recursive"
git config --global alias.aliases "config --get-regexp alias"

Write-Host "Installing Powerdhell tooling for git"
Install-Module posh-git -Force -Scope CurrentUser
Install-Module oh-my-posh -Force -Scope CurrentUser
Set-Prompt
Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
Add-Content $PROFILE "`nImport-Module posh-git`nImport-Module oh-my-posh`nSet-PoshPrompt Paradox"

Write-Host "Installing fonts"
choco install nerdfont-hack

Write-Host "Installing WSL (Ubuntu22.04)"
choco install -y Microsoft-Windows-Subsystem-Linux --source="'windowsfeatures'"

# TODO: Move this to choco install once --root is included in that package
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-2204 -OutFile ~/Ubuntu.appx -UseBasicParsing
Add-AppxPackage -Path ~/Ubuntu.appx

# Run the distro once and have it install locally with root user, unset password
RefreshEnv
Ubuntu2204 install --root
Ubuntu2204 run apt update
Ubuntu2204 run apt upgrade -y

Write-Host "Installing Dotnet and Visual Studio"
winget install Microsoft.DotNet.SDK.7
winget install Microsoft.DotNet.HostingBundle.7
winget install Microsoft.VisualStudio.2022.Professional --silent --override "--wait --quiet --add Microsoft.VisualStudio.Workload.Azure Microsoft.VisualStudio.Workload.ManagedDesktop Microsoft.VisualStudio.Workload.NetWeb Microsoft.VisualStudio.Workload.Node"

Write-Host "Installing Code and extensions"
winget install Microsoft.VisualStudioCode

code --install-extension eamodio.gitlens
code --install-extension telesoho.vscode-markdown-paste-images
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension ms-vscode.azurecli
code --install-extension ms-vscode.powershell
code --install-extension ms-vscode-remote.remote-ssh-edit
code --install-extension ms-vscode-remote.remote-ssh-explorer
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension ms-azuretools.vscode-azurestorage
code --install-extension ms-dotnettools.vscode-dotnet-runtime
code --install-extension mhutchie.git-graph
code --install-extension tabnine.tabnine-vscode
code --install-extension esbenp.prettier-vscode
code --install-extension tim-koehler.helm-intellisense
code --install-extension hashicorp.terraform
code --install-extension vscode-icons-team.vscode-icons
code --install-extension davidanson.vscode-markdownlint

Write-Host "Installing Azure tools"
winget install Microsoft.AzureStorageExplorer
winget install Microsoft.AzureCLI

Write-Host "Installing Powershell 7"
winget install Microsoft.PowerShell

# Azure PowerShell
#pwsh (Make sure to start your terminal session with PowerShell 7)
#Install-Module Az

Write-Host "Installing node/nvm"
choco install nvm --yes

Write-Host "Installing Hugo"
choco install hugo --yes

Write-Host "Installing browsers"
choco install googlechrome --yes
choco install firefox --yes
choco install opera --yes

Write-Host "Installing virtual office"
choco install discord --yes

Write-Host "Installing misc. nice things to have"
Get-Command -Module Microsoft.PowerShell.Archive
choco install 7zip --yes
choco install vlc --yes
choco install sysinternals --yes
choco install procexp --yes
choco install everything --yes
choco install kubernetes-helm --yes
choco install paint.net --yes
choco install sublimetext4 --version=4.0.0.410700 --yes
choco install greenshot --yes
choco install notepadplusplus --yes
choco install licecap --yes
choco install lens --yes
choco install virtualbox --yes
choco install winmerge --yes
choco install winscp --yes
choco install yarn --yes
choco install cascadiacodepl
winget install WinDirStat.WinDirStat
winget install Obsidian.Obsidian
winget install Microsoft.Powertoys
winget install RandyRants.SharpKeys
winget install Postman.Postman
winget install Spotify.Spotify
winget install Logitech.Options
winget install Nushell.Nushell

# Uncomment UAC (User Annoyance Creator) if you _really_ want it
#Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula