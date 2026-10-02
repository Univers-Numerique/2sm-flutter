; =============================================================================
;  Installateur Windows de Sports SM (Inno Setup 6)
;  Compilé par build-release.ps1 :  ISCC.exe /DAppVersion=1.0.0 installer\sportssm.iss
;  Résultat : ..\2sm-laravel\public\downloads\SportsSM-Setup.exe
; =============================================================================

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define AppName "Sports SM"
#define AppExe "SportsSM.exe"
#define Publisher "Univers Numérique"
#define SourceDir "..\build\windows\x64\runner\Release"

[Setup]
; Identifiant fixe : ne jamais le changer (il permet les mises à jour et la désinstallation)
AppId={{AF863641-D4E0-4DF2-99FC-FFDEF7944B62}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#Publisher}
AppPublisherURL=https://2sm.fun
AppSupportURL=https://2sm.fun/faq
AppUpdatesURL=https://2sm.fun/#application
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#Publisher}
VersionInfoDescription=Installateur de {#AppName}
VersionInfoProductName={#AppName}

; Installation pour l'utilisateur courant : aucune demande de droits administrateur
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir=..\..\2sm-laravel\public\downloads
OutputBaseFilename=SportsSM-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\Désinstaller {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "Lancer {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
