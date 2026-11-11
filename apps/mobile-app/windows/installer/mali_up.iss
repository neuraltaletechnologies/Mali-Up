; Inno Setup script for the Mali Up Windows desktop installer (MaliUp-Setup-<version>.exe).
;
; Packages the output of `flutter build windows --release`
; (build\windows\x64\runner\Release\) into a per-user installer: no admin
; prompt, installs under %LOCALAPPDATA%\Programs\Mali Up, adds Start-menu
; (and optional desktop) shortcuts and an "Apps & features" uninstall entry.
;
; Built in CI by .github/workflows/release-windows.yml. Locally (Inno Setup 6):
;   flutter build windows --release
;   iscc /DAppVersion=1.3.0 windows\installer\mali_up.iss
; Output lands in build\windows\installer\.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define AppName "Mali Up"
#define AppPublisher "Neuraltale Technologies"
#define AppURL "https://maliup.neuraltale.com"
#define AppExeName "mali_up.exe"
#define BuildDir "..\..\build\windows\x64\runner\Release"

[Setup]
; Never change AppId — Windows uses it to recognise upgrades of the same app.
AppId={{7B1E4C2A-5D3F-4A8E-9C61-2F0B8D4E7A13}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\..\build\windows\installer
OutputBaseFilename=MaliUp-Setup-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Closes a running copy before upgrading so locked files can be replaced.
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
; Ticked by default: on a shop till the POS should be open when the PC starts.
Name: "startup"; Description: "Start {#AppName} automatically when Windows starts"; GroupDescription: "Startup:"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; Per-user autostart (no admin needed). Shows in Task Manager -> Startup apps,
; where it can be switched off. Re-running setup with the box unticked
; removes it; uninstall removes it too.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExeName}"""; Flags: uninsdeletevalue; Tasks: startup
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "{#AppName}"; Flags: deletevalue; Tasks: not startup

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
