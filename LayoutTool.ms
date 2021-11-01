-- in case of reload script
try (
	closeRolloutFloater layoutTool.m_rolloutFloater
)
catch()
global LayoutTool
global LayoutLocalPath   = @"D:\Argonautes\LayoutLocal"
global LayoutNetworkPath = @"R:\08_LAYOUT"

global LAYOUT_TOOL_VERSION = "1.3.2"
global thisPath = getFilenamePath(getThisScriptFilename())

LayoutToolLog = TatLoggerModule()
LayoutToolLog.setModuleName "LayoutTool"


fileIn "CA_SplineOnSurface.ms"
fileIn "TatCameraGuides.ms"
fileIn "LayoutTool_UI.ms"
fileIn "LayoutTool_Lib.ms"
fileIn "LayoutTool_macro.ms"

-- Registering file post open callback
callbacks.removeScripts #filePostOpen id:#layoutTool_resetScreenshotName_FilePostOpenCallback

python.ExecuteFile  ( thisPath + @"\TatSyncAddModule.py" )
TatSyncSequences = python.Import "TatSyncSequences"
LayoutToolSync = TatSyncSequences.SyncSequences  LayoutLocalPath  LayoutNetworkPath

