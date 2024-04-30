unit ChServer;

interface
uses ChSettings, ChShare, LocalIPC, ChConst;

var  pWgcSet: ^TWGCSettings = NIL;
     ssm: TShareMem = NIL;


implementation
uses Misk, DataProvider;


initialization
 IPCIdent := 100;
 LoadModuleVersion;
 InitShare (ServerGlobalName, ClientGlobalName);
end.
 