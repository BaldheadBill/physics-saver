; Physics-Saver Windows installer (Inno Setup 6)
; Designed, built, and copyrighted by VantEdge Intelligence, Atlanta, GA, USA.
; Open-sourced under the MIT License. https://vantedgeintelligence.com/
;
; Compile:  ISCC.exe Physics-Saver.iss   (from the installer directory)

#define MyAppName "Physics-Saver"
#define MyAppVersion "3.0.0"
#define MyAppPublisher "VantEdge Intelligence"
#define MyAppURL "https://vantedgeintelligence.com/"
#define MyAppExeName "physics-saver.exe"

[Setup]
AppId={{B3E7F1A2-9C4D-4E6B-8A5F-2D1C0E3F4A5B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL=https://github.com/BaldheadBill/physics-saver/issues
AppUpdatesURL=https://github.com/BaldheadBill/physics-saver/releases
DefaultDirName={localappdata}\Physics-Saver
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=Physics-Saver-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Physics-enhanced retrieval for token-efficient AI conversations
VersionInfoCopyright=Copyright (c) 2026 VantEdge Intelligence, Atlanta, GA, USA
VersionInfoVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "claude"; Description: "Register with Claude Desktop"; Flags: unchecked
Name: "gemini"; Description: "Register with Gemini CLI"; Flags: unchecked

[Files]
Source: "..\dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "install.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName} (CLI help)"; Filename: "{app}\{#MyAppExeName}"; Parameters: "help"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Parameters: "help"; Flags: nowait skipifsilent; Description: "Show CLI help"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install.ps1"" -SkipDownload -InstallDir ""{app}"" {code:GetClientFlags}"; Flags: nowait skipifsilent; Description: "Register with Claude Desktop / Gemini CLI"; Check: HasClientTasks

[Code]
function HasClientTasks(): Boolean;
begin
  Result := IsTaskSelected('claude') or IsTaskSelected('gemini');
end;

function GetClientFlags(Param: String): String;
begin
  Result := '';
  if IsTaskSelected('claude') then
    Result := Result + ' -ConfigureClaude';
  if IsTaskSelected('gemini') then
    Result := Result + ' -ConfigureGemini';
end;
