#define MyAppName "DCS Lua Desanitizer"
#define ServiceName "DcsLuaDesanitizer"
#define MyAppVersion "0.1"
#define MyAppPublisher "TheHotseat"
#define MyAppURL "https://github.com/TheHotseat/DCS-Scripts"
#define MyAppExeName "lua-desanitizer.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{F4EE555B-E1AE-4F4D-B66B-98983C2E74A9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=D:\Documents\Developement\lua\DCS\GitHub\DCS-Scripts\LICENSE
OutputDir=D:\Documents\Developement\lua\DCS\GitHub\DCS-Scripts\LuaDesanitizer\inno installer
OutputBaseFilename=LuaDesanitizerSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "armenian"; MessagesFile: "compiler:Languages\Armenian.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "bulgarian"; MessagesFile: "compiler:Languages\Bulgarian.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "corsican"; MessagesFile: "compiler:Languages\Corsican.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "finnish"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "icelandic"; MessagesFile: "compiler:Languages\Icelandic.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "slovak"; MessagesFile: "compiler:Languages\Slovak.isl"
Name: "slovenian"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Files]
; Install if running on x64
Source: "D:\Documents\Developement\lua\DCS\GitHub\DCS-Scripts\LuaDesanitizer\target\x86_64-pc-windows-msvc\release\{#MyAppExeName}"; DestDir: "{app}";  Check: InstallX64;
; Place all ARM64 files here, first one should be marked 'solidbreak'
Source: "D:\Documents\Developement\lua\DCS\GitHub\DCS-Scripts\LuaDesanitizer\target\aarch64-pc-windows-msvc\release\{#MyAppExeName}"; DestDir: "{app}"; Check: InstallARM64; Flags: solidbreak      
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
; Place all common files here, first one should be marked 'solidbreak'

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{sys}\sc.exe"; Parameters: "create {#ServiceName} binpath=""{app}\{#MyAppExeName}"" start=auto"; Flags: runascurrentuser runhidden
Filename: "{sys}\net.exe"; Parameters: "start {#ServiceName}"; Flags: runascurrentuser runhidden

[UninstallRun]
Filename: "{sys}\net.exe"; Parameters: "stop {#ServiceName}"; Flags: runascurrentuser runhidden
Filename: "{sys}\sc.exe"; Parameters: "delete {#ServiceName}"; Flags: runascurrentuser runhidden

[Code]
function InstallARM64: Boolean;
begin
  Result := ProcessorArchitecture = paARM64;
end;
function InstallX64: Boolean;
begin
  Result := not InstallARM64;
end;


