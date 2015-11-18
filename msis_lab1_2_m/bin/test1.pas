
Program GeoOSScriptFunctions;

interface
  uses
    Windows, SysUtils, Classes, shellapi, Zip, StrUtils, Registry,
    WinINet, Tlhelp32
    {$IFNDEF CONSOLE}, Dialogs, IdHTTP, IdAntiFreeze, IdComponent, Forms{$ENDIF};

  type TWinVersion = (wvUnknown, wvWin95, wvWin98, wvWin98SE, wvWinNT, wvWinME, wvWin2000, wvWinXP, wvWinVista);

const
  FunctionsVersion = '0.46.4';

const //admin rights constants
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority=(Value:(0,0,0,0,0,5));
  SECURITY_BUILTIN_DOMAIN_RID  = $00000020;
  DOMAIN_ALIAS_RID_ADMINS      = $00000220;
  DOMAIN_ALIAS_RID_USERS       = $00000221;
  DOMAIN_ALIAS_RID_GUESTS      = $00000222;
  DOMAIN_ALIAS_RID_POWER_USERS = $00000223;

type functions = record

 var
    ZipHandler:                      TZipFile;  // for accessing zip files
    CommandSplit1:                TStringList;  // for spliting of commands (main - what is command, and what are parameters)
    CommandSplit2:                TStringList;  // for spliting of commands (minor - if multiple parameters, split them too)
    Handle:                              HWND;  // some handle variable for shellapi
    _log:                         TStringList;  // holds information about scripts progress
    progversion:                       string;  // program version in string
    ifinfo:                            string;  // for RunGOSCommand
    ifmode:                          smallint;  // GOScript if
    reg:                            TRegistry;  // for accessing windows registry
    {$IFNDEF CONSOLE}
    fIDHTTP:         array [1..10] of TIDHTTP;  // max support for 10 downloads at time
    Stream:    array [1..10] of TMemoryStream;  // downloading streams
    idAntiFreeze:               TIdAntiFreeze;  // stop freezing application while downloading a file
    {$ENDIF}


var line,name: string;
var
  comm,par: string;
  yn: string;
begin
  result:=true;
  if not(ifmode=0) then
    if(LowerCase(line)='end::') then
    begin
      ifinfo:='';
      ifmode:=0;
      exit;
    end
    else if(LowerCase(line)='::else::') then
    begin
      if(ifmode=1) then ifmode:=2
      else if(ifmode=2) then ifmode:=1
      else if(ifmode=3) then ifmode:=4
      else if(ifmode=4) then ifmode:=3
      else if(ifmode=5) then ifmode:=6
      else if(ifmode=6) then ifmode:=5
      else if(ifmode=7) then ifmode:=8
      else if(ifmode=8) then ifmode:=7;
      result:=true;
      exit;
    end
    else if(progversion and (ifmode=1)) then
    begin
      result:=false;
      exit;
    end
    else if((ifinfo=progversion) and (ifmode=2)) then
    begin
      result:=false;
      exit;
    end
    else if(not(FileExists(ifinfo)) and (ifmode=3)) then
    begin
      result:=false;
      exit;
    end
    else if(FileExists(ifinfo) and (ifmode=4)) then
    begin
      result:=false;
      exit;
    end
    else if(not(DirectoryExists(ifinfo)) and (ifmode=5)) then
    begin
      result:=false;
      exit;
    end
    else if(DirectoryExists(ifinfo) and (ifmode=6)) then
    begin
      result:=false;
      exit;
    end
    else if(not(progversion)) and (ifmode=7)) then
    begin
      result:=false;
      exit;
    end
    else if(AnsiContainsStr(ifinfo,progversion) and (ifmode=8)) then
    begin
      result:=false;
      exit;
    end;
  if(empty(comm)) then // if command is missing, don't do anything
  begin
    LogAdd('Command whitespace');
    result:=false;
  end
  else if((comm='closeme') or (comm='terminateme')) then
  begin
    {$IFDEF CONSOLE}
    TerminateMe();
    {$ELSE}
    LogAdd('Can?t terminate program! Shut it down manually!');
    {$ENDIF}
  end
  else if(empty(par)) then // if parameter is missing, don't do anything
  begin
    LogAdd('Parameter whitespace');
    result:=false;
  end
  else if(comm='::ifversion') then
  begin
    ifinfo:=par;
    ifmode:=1;
  end
  else if(comm='::ifnotversion') then
  begin
    ifinfo:=par;
    ifmode:=2;
  end
  else if(comm='::iffileexists') then
  begin
    ifinfo:=par;
    ifmode:=3;
  end
  else if(comm='::iffilenotexists') then
  begin
    ifinfo:=par;
    ifmode:=4;
  end
  else if((comm='::ifdirexists') or (comm='::ifdirectoryexists')) then
  begin
    ifinfo:=par;
    ifmode:=5;
  end
  else if((comm='::ifdirnotexists') or (comm='::ifdirectorynotexists')) then
  begin
    ifinfo:=par;
    ifmode:=6;
  end
  else if((comm='::ifversioncontains') or (comm='::ifversioncont')) then
  begin
    ifinfo:=par;
    ifmode:=7;
  end
  else if((comm='::ifversionnotcontains') or (comm='::ifversionnotcont')) then
  begin
    ifinfo:=par;
    ifmode:=8;
  end
  else if(comm='scriptname') then
    LogAdd('Script name: '+par)
  else if(comm='author') then //Write script's author
    LogAdd('Script?s Author: '+par)
  else if(comm='log') then //Write a message
    LogAdd(StringReplace(par,'__',' ', [rfReplaceAll, rfIgnoreCase]))
  else if(comm='logenter') then //Write a message, user need to hit enter to continue with program
  begin
    {$IFDEF CONSOLE}
    write(StringReplace(par,'__',' ', [rfReplaceAll, rfIgnoreCase]));
    readln;
    {$ELSE}
    RunGOSCommand('Log='+par);
    {$ENDIF}
  end
  else if(comm='logsave') then //save log to a specified file
  begin
    LogAdd('Log saved as "'+par+'".');
    _log.SaveToFile(GetLocalDir()+par);
  end
  else if(comm='version') then //Write current script version
    LogAdd('Script?s Version: '+par)
  else if(comm='promptyesno') then //Ask user to do some command, if 'y' is prompt that command will be used
  begin
    {$IFDEF CONSOLE}
    write(StringReplace(CommandParams(line,0),'__',' ', [rfReplaceAll, rfIgnoreCase])+' [y/n]: ');
    read(yn);
    readln;
    yn:=InputBox('GeoOS Script',StringReplace(CommandParams(line,0),'__',' ', [rfReplaceAll, rfIgnoreCase])+' [y/n]: ','n');
    SetLength(yn,1);
    if(LowerCase(yn)='y') then
    begin
      if not(empty(CommandParams(line,1,1))) then //support for Execute
      begin
        RunGOSCommand(CommandParams(line,1)+'='+CommandParams(line,0,1)+','+CommandParams(line,1,1));
      end
      else
      begin
        RunGOSCommand(CommandParams(line,1)+'='+CommandParams(line,0,1));
      end;
    end
    else
      LogAdd('Prompt: Do Nothing');
  end
  else if(comm='mkdir') then //Create Directory
  begin
    if not(DirectoryExists(GetLocalDir()+par)) then
    begin
      mkdir(GetLocalDir()+par);
      LogAdd('Directory "'+GetLocalDir()+par+'" created.');
    end;
  end
  else if(comm='rmdir') then //Remove Directory
  begin
    if(DirectoryExists(GetLocalDir()+par)) then
    begin
      rmdir(GetLocalDir()+par);
      LogAdd('Directory "'+GetLocalDir()+par+'" removed.');
    end;
  end
  else if(comm='rmfile') then //Remove File
  begin
    if(FileExists(GetLocalDir()+par)) then
    begin
      deletefile(PWChar(GetLocalDir()+par));
      LogAdd('File "'+GetLocalDir()+par+'" removed.');
    end;
  end
  else if(comm='killtask') then //turn other process off
  begin
    KillTask(par);
    LogAdd('Killing task "'+par+'".');
  end
  else if(comm='setregistry') then //set value into windows registry
  begin
    result:=false;
    if(CommandParams(line,0)='HKEY_CLASSES_ROOT') then
      reg:=HKEY_CLASSES_ROOT
    else if(CommandParams(line,0)='HKEY_LOCAL_MACHINE') then
      reg:=HKEY_LOCAL_MACHINE
    else if(CommandParams(line,0)='HKEY_USERS') then
      reg:=HKEY_USERS
    else if(CommandParams(line,0)='HKEY_CURRENT_CONFIG') then
      reg:=HKEY_CURRENT_CONFIG
    else //if(CommandParams(line,0)='HKEY_CURRENT_USER') then || use HKEY_CURRENT_USER as default
      reg:=HKEY_CURRENT_USER;
    if( reg) or not(empty(CommandParams(line,1)))) and not(empty(CommandParams(line,2))) and not(empty(CommandParams(line,3))) and not(empty(CommandParams(line,4)))) then
    begin
      //reg(CommandParams(line,1),true);
      if(LowerCase(CommandParams(line,2))='string') then
        reg.WriteString(CommandParams(line,3),CommandParams(line,4))
      else if((LowerCase(CommandParams(line,2))='integer') or (LowerCase(CommandParams(line,2))='int')) then
        reg.WriteInteger(CommandParams(line,3),StrToInt(CommandParams(line,4)))
      else if(LowerCase(CommandParams(line,2))='float') then
        reg.WriteFloat(CommandParams(line,3),StrToFloat(CommandParams(line,4)))
      else if((LowerCase(CommandParams(line,2))='boolean') or (LowerCase(CommandParams(line,2))='bool')) then
      begin
        if(LowerCase(CommandParams(line,4))='true') then
          reg.WriteBool(CommandParams(line,3),true)
        else
          reg.WriteBool(CommandParams(line,3),false);
      end;
      LogAdd('Modification in Registry completed!');
      result:=true;
    end
    else
      LogAdd('Modification in Registry not completed! Something is missing or invalid key.');
  end
  else if(comm='copyfile') then //Copy File
  begin
    if(FileExists(GetLocalDir()+CommandParams(line,0))) then
    begin
      if(FileExists(GetLocalDir()+CommandParams(line,1))) then
      begin
        if(CommandParams(line,2)='overwrite') then
        begin
          CopyFile(PWChar(GetLocalDir()+CommandParams(line,0)),PWChar(GetLocalDir()+CommandParams(line,1)),false);
          LogAdd('File "'+GetLocalDir()+CommandParams(line,0)+'" copied to "'+GetLocalDir()+CommandParams(line,1)+'". autooverwrite');
        end
        else
        begin
          {$IFDEF CONSOLE}
          write('File "'+GetLocalDir()+CommandParams(line,1)+'" already exists, overwrite? [y/n]: ');
          read(yn);
          readln;
          {$ELSE}
          yn:=InputBox('GeoOS Script','File "'+CommandParams(line,1)+'" already exists, overwrite? [y/n]: ','n');
          {$ENDIF}
          SetLength(yn,1);
          if(LowerCase(yn)='y') then // if user type "y" it means "yes"
          begin
            CopyFile(PWChar(GetLocalDir()+CommandParams(line,0)),PWChar(GetLocalDir()+CommandParams(line,1)),false);
            LogAdd('File "'+GetLocalDir()+CommandParams(line,0)+'" copied to "'+GetLocalDir()+CommandParams(line,1)+'".');
          end
          else
            LogAdd('OK');
        end;
      end
      else
      begin
        CopyFile(PWChar(GetLocalDir()+CommandParams(line,0)),PWChar(GetLocalDir()+CommandParams(line,1)),false);
        LogAdd('File "'+GetLocalDir()+CommandParams(line,0)+'" copied to "'+GetLocalDir()+CommandParams(line,1)+'".');
      end;
    end
    else
      LogAdd('File "'+GetLocalDir()+CommandParams(line,0)+'" copied to "'+GetLocalDir()+CommandParams(line,1)+'" failed! File "'+CommandParams(line,0)+'" doesn?t exists!');
  end
  else if(comm='execute') then
  begin
    if(FileExists(GetLocalDir()+CommandParams(line,0))) then
    begin
      if(GetWinVersion=wvWinVista) then
      begin
        ShellExecute(Handle,'runas',PWChar(GetLocalDir()+CommandParams(line,0)),PWChar(StringReplace(CommandParams(line,1),'__',' ', [rfReplaceAll, rfIgnoreCase])),PWChar(GetLocalDir()),1);
        LogAdd('File "'+CommandParams(line,0)+'" executed as admin with "'+StringReplace(CommandParams(line,1),'__',' ', [rfReplaceAll, rfIgnoreCase])+'" parameters.');
      end
      else
      begin
        ShellExecute(Handle,'open',PWChar(GetLocalDir()+CommandParams(line,0)),PWChar(StringReplace(CommandParams(line,1),'__',' ', [rfReplaceAll, rfIgnoreCase])),PWChar(GetLocalDir()),1);
        LogAdd('File "'+CommandParams(line,0)+'" executed with "'+StringReplace(CommandParams(line,1),'__',' ', [rfReplaceAll, rfIgnoreCase])+'" parameters.');
      end;
    end
    else if(IsRemote(CommandParams(line,0))) then
  end
  else if(comm='downloadfile') then
  begin
    if(fileexists(GetLocalDir()+CommandParams(line,1))) then
    begin
      if(CommandParams(line,2)='overwrite') then
      begin
        LogAdd('Downloading "'+CommandParams(line,0)+'" to "'+GetLocalDir()+CommandParams(line,1)+'" ... autooverwrite');
        result:=CheckDirAndDownloadFile(CommandParams(line,0),CommandParams(line,1));
      end
      else
      begin
        {$IFDEF CONSOLE}
        write('File "',GetLocalDir()+CommandParams(line,1),'" already exists, overwrite? [y/n]: ');
        read(yn);
        readln;
        {$ELSE}
        yn:=InputBox('GeoOS Script','File "'+CommandParams(line,1)+'" already exists, overwrite? [y/n]: ','n');
        {$ENDIF}
        SetLength(yn,1);
        if(yn='y') then // if user type "y" it means "yes"
        begin
          LogAdd('Downloading "'+CommandParams(line,0)+'" to '+GetLocalDir()+CommandParams(line,1)+'" ...');
          result:=CheckDirAndDownloadFile(CommandParams(line,0),CommandParams(line,1));
        end;
      end;
    end
    else  //file does not exists
    begin
      LogAdd('Downloading "'+CommandParams(line,0)+'" to "'+GetLocalDir()+CommandParams(line,1)+'" ...');
      result:=CheckDirAndDownloadFile(CommandParams(line,0),CommandParams(line,1));
    end;
  end
  else if(comm='zipextract') then
  begin
    if(ZipHandler) then
    begin
      if(FileExists(GetLocalDir()+par)) then
      begin
        ZipHandler.ExtractZipFile(par,GetLocalDir()+'geoos\');
        LogAdd('File "'+par+'" extracted.');
      end
      else
        LogAdd('File "'+par+'" does not exists.');
    end
    else
      LogAdd('File "'+par+'" is not valid zip file!');
  end; 
	name := 'nastya';
	if( name = 'nastya') then name:= 'NASTYA';
  end;
end;