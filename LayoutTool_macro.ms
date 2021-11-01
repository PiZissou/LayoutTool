global LayoutTool

macroScript LayoutTool
category:"tat_Layout"
tooltip:"Layout Tool"
buttontext:"Layout Tool"
(
    LayoutTool.OpenUI()
)

macroScript LayoutToolPreview
category:"tat_Layout"
tooltip:"Layout Tool - Create Preview" 
buttontext:"Preview"
(
   	LayoutTool.TakeMovie()
)

macroScript LayoutToolCreateFreeCamera 
category:"tat_Layout"
tooltip:"Layout Tool - Create Free Camera"
buttontext:"Free Camera"
(
    LayoutTool.CreateConformedCameraFromView()
)

macroScript LayoutResetViewport
category:"tat_Layout"
buttontext:"ResetViewport"
tooltip:"ViewportLib - Reset Viewport Layout"
(
    LayoutTool.ResetViewportLayout()
)

macroScript layoutToolSyncNetwork
category:"tat_Layout"
buttontext:"SyncNetwork"
tooltip:"Layout Tool - Sync Network"
(
    LayoutToolSync.sync()
    messageBox "LayoutTool Sync Network done!"
)