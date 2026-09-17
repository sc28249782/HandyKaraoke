; Reproducible x64 installer for the CMake staged runtime.
; Invoke through scripts\Build-Installer.ps1 so SourceDir always points to a verified stage.

#ifndef SourceDir
  #error "SourceDir must name the verified HandyKaraoke stage directory"
#endif
#ifndef OutputDir
  #error "OutputDir must name the installer output directory"
#endif
#ifndef MyAppVersion
  #define MyAppVersion "3.0.0-alpha-recovery"
#endif

#define MyAppName "Handy Karaoke (x64)"
#define MyAppPublisher "HandyKaraoke contributors"
#define MyAppURL "https://github.com/sc28249782/HandyKaraoke"
#define MyAppExeName "HandyKaraoke.exe"

[Setup]
AppId={{893E4048-2955-4D6A-912D-BA2FB00CDF1F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE
InfoBeforeFile=..\docs\OFFICIAL-BINARY-RELEASE-POLICY.md
OutputDir={#OutputDir}
OutputBaseFilename=HandyKaraoke-{#MyAppVersion}-x64-setup
SetupIconFile=..\icon.ico
Compression=lzma2
SolidCompression=yes
DisableWelcomePage=no
UsePreviousAppDir=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\HandyKaraoke Safe Mode"; Filename: "{app}\HandyKaraoke-SafeMode.cmd"; Check: FileExists(ExpandConstant('{app}\HandyKaraoke-SafeMode.cmd'))
Name: "{group}\Reset HandyKaraoke Settings"; Filename: "{app}\HandyKaraoke-ResetSettings.cmd"; Check: FileExists(ExpandConstant('{app}\HandyKaraoke-ResetSettings.cmd'))
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Dirs]
; Keep user-generated media and database/configuration across uninstall.
Name: "{app}\Data"; Flags: uninsneveruninstall
Name: "{app}\Songs"; Flags: uninsneveruninstall
Name: "{app}\Songs\HNK"; Flags: uninsneveruninstall
Name: "{app}\Songs\KAR"; Flags: uninsneveruninstall
Name: "{app}\Songs\NCN"; Flags: uninsneveruninstall
Name: "{app}\Songs\NCN\Cursor"; Flags: uninsneveruninstall
Name: "{app}\Songs\NCN\Lyrics"; Flags: uninsneveruninstall
Name: "{app}\Songs\NCN\Song"; Flags: uninsneveruninstall
Name: "{app}\SoundFonts"; Flags: uninsneveruninstall
Name: "{app}\VST"; Flags: uninsneveruninstall

[Files]
; The stage is the sole payload source. Do not replace this with a developer path.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "Data\*,Songs\*,SoundFonts\*,VST\*"

[Run]
; windeployqt places the VC redistributable in the verified stage.
Filename: "{app}\vc_redist.x64.exe"; Parameters: "/install /passive /norestart"; Flags: waituntilterminated ignoreerrors skipifdoesntexist
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
