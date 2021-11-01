LAYOUT_TOOL_WIDTH = 260
LAYOUT_TOOL_HEIGHT = 850
LT_BtnH = 30
LT_BtnH2 = 35

global TatCameraGuides
global LayoutTool 
global TatPreview_ 

rollout layoutTool_Shaker_Rollout "Shaker"
(
	dotnetcontrol btn_addShaker "System.Windows.Forms.Button" width:106 height:LT_BtnH across:2
	dotnetcontrol btn_convertShaker "System.Windows.Forms.Button" width:106 height:LT_BtnH
	radiobuttons btn_modeShaker labels:#("Position","Rotation") columns:2 align:#left  across:3 
	spinner spn_controllerIndex "Index :" type:#integer range:[1,5,2] fieldWidth:20 offset:[60,0] align:#right
	label lbl_controllerCount "/"  text:"1" offset:[-2,0] align:#right 
	label lbl_controllerNameTitle "Controller :" across:2 align:#left
	label lbl_controllerName "" align:#left offset:[-50,0]
	edittext edit_frequency "Freq:" text:"0.1" fieldWidth:40 align:#right offset:[-5,1] enabled:false across:2
	edittext edit_strengthX "Strength X :" text:"50" fieldWidth:40 align:#right offset:[0,1] enabled:false
	edittext edit_strengthY "Strength Y :" text:"50" fieldWidth:40 align:#right offset:[-5,1] enabled:false across:2
	edittext edit_strengthZ "Strength Z :" text:"50" fieldWidth:40 align:#right offset:[0,1] enabled:false
	dotnetcontrol btn_removeShaker "System.Windows.Forms.Button" width:110 height:20 across:2
	edittext edit_weight "Weight :" text:"100" fieldWidth:40 align:#right offset:[0,1] enabled:false

	on layoutTool_Shaker_Rollout open do
	(
		btn_addShaker.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_addShaker.text = "Add shaker"
		btn_addShaker.backcolor = btn_addShaker.backColor.lightblue

		btn_convertShaker.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_convertShaker.text = "Convert shaker"
		btn_convertShaker.backcolor = btn_convertShaker.backColor.orchid

		btn_removeShaker.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_removeShaker.text = "Delete shaker"
		btn_removeShaker.backcolor = btn_removeShaker.backColor.gray
	)

	on btn_modeShaker changed arg do 
	(
		layoutTool.UpdateShakerControls()
	)

	on edit_weight entered value do
	(
		-- mode available : noise on position or on rotation
		POSITION_MODE = 1
		ROTATION_MODE = 2

		if btn_modeShaker.state == POSITION_MODE then (
			LayoutTool.ModifyNoiseParameters #posWeight (value as float) spn_controllerIndex.value
		)
		else if btn_modeShaker.state == ROTATION_MODE do (
			LayoutTool.ModifyNoiseParameters #rotWeight (value as float) spn_controllerIndex.value
		)
	)

	on spn_controllerIndex changed value do
	(
		layoutTool.UpdateShakerControls  noise_index:value
	)

	------ update cam shaker parameters function ------
	on edit_frequency entered value do
	(
		LayoutTool.ModifyNoiseParameters #frequency (value as float) spn_controllerIndex.value
	)

	on edit_strengthX entered value do
	(
		LayoutTool.ModifyNoiseParameters #strengthX (value as float) spn_controllerIndex.value
	)

	on edit_strengthY entered value do
	(
		LayoutTool.ModifyNoiseParameters #strengthY (value as float) spn_controllerIndex.value
	)

	on edit_strengthZ entered value do
	(
		LayoutTool.ModifyNoiseParameters #strengthZ (value as float) spn_controllerIndex.value
	)

	on btn_addShaker mousedown senderArg arg do(
		/*
		* Create a point with a noise controller to add a shaker for the current camera.
		*/
		-- mode available : noise on position or on rotation
		POSITION_MODE = 1
		ROTATION_MODE = 2

		if layoutTool_Shaker_Rollout.btn_modeShaker.state == POSITION_MODE then (
			layoutTool.AddNoisePositionToCam()
		)
		else (
			layoutTool.AddNoiseRotationToCam()
		)
	)

	on btn_convertShaker mousedown senderArg arg do
	(
		/*
		* convert selected shaker to noise of keyframe 
		*/
		layoutTool.ConvertShaker btn_modeShaker.state spn_controllerIndex.value
	)

	on btn_removeShaker mousedown senderArg arg do(
		/*
		* Delete desired noise controller on the selected camera
		*/
		layoutTool.RemoveShaker btn_modeShaker.state spn_controllerIndex.value
	)
)

rollout layoutTool_Previz_Rollout "Previz Cams/Persos" rolledup:false
(
	dotnetcontrol btn_previz_import "System.Windows.Forms.Button" width:106 height:LT_BtnH across:2
	dotnetcontrol btn_previz_delete "System.Windows.Forms.Button"  width:106 height:LT_BtnH

	on layoutTool_Previz_Rollout open do (
		btn_previz_import.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_previz_import.text = "Import"
		btn_previz_import.backcolor = btn_previz_import.backColor.orchid

		btn_previz_delete.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_previz_delete.text = "Clean"
		btn_previz_delete.backcolor = btn_previz_delete.backColor.orchid
	)

	on btn_previz_import mouseDown senderArg arg do
	(
		layoutTool.ImportPreviz()
	)

	on btn_previz_delete mouseDown senderArg args do
	(
		layoutTool.CleanPreviz()
	)
)

rollout layoutTool_SaveAs_Rollout "Save to" 
(
	edittext edit_Seq 		"Seq:" 		text:"01" 	fieldWidth:35 align:#left offset:[0,1] across:3
	edittext edit_shot 		"Plan:" 	text:"0001" fieldWidth:45 align:#left offset:[0,1]
	edittext edit_version 	"v:" 		text:"A" 	fieldWidth:20 align:#left offset:[10,1]
	dotnetcontrol btn_saveNext "System.Windows.Forms.Button"  width:217 height:LT_BtnH

	on layoutTool_SaveAs_Rollout open do (
		
		btn_saveNext.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_saveNext.text = "Save to "
		btn_saveNext.backcolor = btn_saveNext.backColor.HotPink

		if layoutTool.GetSeqShot  &seq &shot &version then (
			edit_Seq.text = seq
			edit_shot.text = shot
			edit_version.text = version
		)
	)
	on btn_saveNext mouseDown senderArg arg do
	(
		layoutTool.SaveAs  edit_Seq.text  edit_shot.text  edit_version.text
		layoutTool.CloseSaveAsUI()
	)
)

rollout layoutTool_Screenshot_Rollout "Plans"
(
	dotnetcontrol 	btn_exportEstablishing "System.Windows.Forms.Button"  width:217 height:LT_BtnH
	checkbox 		cb_light 	"Light"  across:2
	checkbox 		cb_CamGuides 		"Camera Guides" 
	dotnetcontrol 	btn_capture "System.Windows.Forms.Button"  width:70 height:LT_BtnH across:3
	dotnetcontrol 	btn_preview "System.Windows.Forms.Button"  width:70 height:LT_BtnH 
	dotnetcontrol 	btn_quickPath "System.Windows.Forms.Button"  width:70 height:LT_BtnH
	dotnetcontrol 	btn_saveNext  "System.Windows.Forms.Button"  width:70 height:LT_BtnH across:3
	dotnetcontrol 	btn_savePlus  "System.Windows.Forms.Button"  width:70 height:LT_BtnH 
	dotnetcontrol 	btn_importSound "System.Windows.Forms.Button"  width:70 height:LT_BtnH

	on layoutTool_Screenshot_Rollout open do (

		btn_exportEstablishing.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_exportEstablishing.text = "Export establishing"
		btn_exportEstablishing.backcolor = btn_exportEstablishing.backColor.HotPink

		btn_capture.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_capture.text = "Screenshot"
		btn_capture.backcolor = btn_capture.backColor.lightblue

		btn_preview.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_preview.text = "Preview"
		btn_preview.backcolor = btn_preview.backColor.lightblue

		btn_saveNext.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_saveNext.text = "Save Next"
		btn_saveNext.backcolor = btn_importSound.backColor.lightblue

		btn_savePlus.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_savePlus.text = "Save +"
		btn_savePlus.backcolor = btn_importSound.backColor.lightblue

		btn_importSound.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_importSound.text = "Impt. sound"
		btn_importSound.backcolor = btn_importSound.backColor.lightblue

		btn_quickPath.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_quickPath.text = "Browse..."
		btn_quickPath.backcolor = btn_quickPath.backColor.orchid

		cb_CamGuides.checked = layoutTool.GetCameraGuidesState()
		cb_light.checked = layoutTool.GetLightsRenderState()

	)
	
	on btn_importSound mousedown senderArg arg do
	(
		layoutTool.ImportSoundPicker()
	)

	on btn_exportEstablishing mouseDown senderArg arg do
	(
		layoutTool.ExportEstablishing()
	)

	on btn_preview mouseDown senderArg arg do
	(
		layoutTool.TakeMovie()
	)

	on btn_capture mouseDown senderArg arg do
	(
		layoutTool.TakeScreenshots()
	)

	on btn_saveNext mouseDown senderArg arg do
	(
 		local mousepos = senderArg.pointToScreen (dotnetobject "System.Drawing.Point" 0 0)
		layoutTool.OpenSaveAsUI [ mousepos.x , mousepos.y ] 
	)

	on btn_savePlus mouseDown senderArg arg do
	(
 		TatMxsLib.SaveIncrementedVersion  withAddUserName:true
	)		

	on cb_light changed  state do 
	(
		layoutTool.m_dsps["LightsRender"] =  state 
		TatPreview_.SetupNitrousViewportSettings layoutTool.m_dsps &restoreNvs &restoreEnv 
	)

	on cb_CamGuides changed  state do 
	(
		layoutTool.m_dsps["CameraGuides"] = state
	)

	on btn_quickPath mouseDown senderArg arg do
    (
        rcmenu quickPathMenu (
			menuItem mi_sceneFolder "Current Scene Folder"
            menuItem mi_screenshots "Screenshots"
            menuItem mi_previews "Previews"
            menuItem mi_sounds "Sounds"
            menuItem mi_libPistache "XX_LIB\\lib_Pistache"

			on mi_sceneFolder picked do (
				layoutTool.BrowseCurrentSceneFolder()
			)

            on mi_screenshots picked do (
                layoutTool.BrowseScreenshots()
            )

            on mi_previews picked do (
                layoutTool.BrowsePreviews()
            )

            on mi_sounds picked do (
                layoutTool.BrowseSounds()
            )

            on mi_libPistache picked do (
                layoutTool.BrowseLibPistache()
            )
        )

        popUpMenu quickPathMenu
    )
)

rollout layoutTool_Rollout "Camera Settings"
(
	group "General" (

		dotnetcontrol btn_createCam "System.Windows.Forms.Button" width:217 height:LT_BtnH

		dotnetcontrol btn_selCur "System.Windows.Forms.Button"  across:3  width:70 height:LT_BtnH2
		dotnetcontrol btn_selAll "System.Windows.Forms.Button"  width:70 height:LT_BtnH2 offset:[2,0]
		dotnetcontrol btn_selTargets "System.Windows.Forms.Button"  width:70 height:LT_BtnH2 offset:[2,0]
		
		spinner spn_focalLength "Focal Length (mm) : " type:#integer range:[10,400,50] fieldWidth:30

        dotnetcontrol btn_focalKey "System.Windows.Forms.Button" width:217 height:LT_BtnH
	)
	
	group "Guides" (
		dotnetcontrol btn_toggleGuides "System.Windows.Forms.Button"  width:217 height:LT_BtnH
		radiobuttons btn_guideType labels:#("Rule Of Third","Cross", "Center Cross", "Golden Ratio", "Golden") columns:2 offsets:#([0,0], [15,0], [0,0], [15,0], [0,0])
	) 
	

	group "Constraints" (
		dotnetcontrol btn_bindToRail "System.Windows.Forms.Button"  width:70 height:LT_BtnH across:3 align:#left
		dotnetcontrol btn_createPivot "System.Windows.Forms.Button"  width:70 height:LT_BtnH align:#left
		dotnetcontrol btn_createFollow "System.Windows.Forms.Button"  width:70 height:LT_BtnH align:#left
		checkbox cb_bindWithSpaceSwitch "Space Switch" checked:false
		dotnetcontrol btn_splineOnSurface "System.Windows.Forms.Button"  width:217 height:LT_BtnH
	)

	group "Transformations" (
		dotnetcontrol btn_Lock "System.Windows.Forms.Button" width:217  height:LT_BtnH
		dotnetcontrol btn_Local "System.Windows.Forms.Button"  width:106  height:LT_BtnH across:2
		dotnetcontrol btn_World "System.Windows.Forms.Button"  width:106  height:LT_BtnH
		dotnetcontrol btn_mirrorX "System.Windows.Forms.Button"  width:70  height:LT_BtnH across:3
		dotnetcontrol btn_mirrorY "System.Windows.Forms.Button"  width:70  height:LT_BtnH
		dotnetcontrol btn_mirrorZ "System.Windows.Forms.Button"  width:70  height:LT_BtnH
	)

	group "Snap"
	(
		dotnetcontrol btn_generate "System.Windows.Forms.Button"  width:106 height:LT_BtnH across:2
		dotnetcontrol btn_snap "System.Windows.Forms.Button"  width:106 height:LT_BtnH
	)

	on layoutTool_Rollout open do
	(
		btn_createCam.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_createCam.text = "Create Physical Camera"
		btn_createCam.backcolor = btn_createCam.backColor.orange

		btn_selCur.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_selCur.text = "Select VIEW CAM"
		btn_selCur.backcolor = btn_selCur.backColor.lightgreen

		btn_selAll.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_selAll.text = "Select ALL CAM"
		btn_selAll.backcolor = btn_selAll.backColor.lightgreen

		btn_selTargets.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_selTargets.text = "Select TARGETS"
		btn_selTargets.backcolor = btn_selTargets.backColor.lightgreen

		btn_Lock.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_Lock.text = "Indeterminate locking"
		btn_Lock.backcolor = btn_Lock.backColor.gray

		btn_Local.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_Local.text = "Local"
		btn_Local.backcolor = btn_Local.backColor.indianred

		btn_World.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_World.text = "World"
		btn_World.backcolor = btn_World.backColor.indianred

		btn_mirrorX.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_mirrorX.text = "MirrorX"
		btn_mirrorX.backcolor = btn_mirrorX.backColor.lightblue

		btn_mirrorY.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_mirrorY.text = "MirrorY"
		btn_mirrorY.backcolor = btn_mirrorY.backColor.lightblue

		btn_mirrorZ.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_mirrorZ.text = "MirrorZ"
		btn_mirrorZ.backcolor = btn_mirrorZ.backColor.lightblue

        btn_bindToRail.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_bindToRail.text = "Rail Rig"
		btn_bindToRail.backcolor = btn_bindToRail.backColor.lightblue
		

		btn_toggleGuides.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_toggleGuides.text = "Toggle Guides"
		btn_toggleGuides.backcolor = btn_toggleGuides.backColor.lightgreen

		btn_createPivot.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_createPivot.text = "Pivot Rig"
		btn_createPivot.backcolor = btn_createPivot.backColor.lightblue

		btn_createFollow.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_createFollow.text = "Follow Rig"
		btn_createFollow.backcolor = btn_createFollow.backColor.lightblue

        btn_focalKey.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_focalKey.text = "Focal Key"
		btn_focalKey.backcolor = btn_focalKey.backColor.lightgreen

		btn_generate.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_generate.text = "Generate points"
		btn_generate.backcolor = btn_generate.backColor.orange

		btn_snap.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_snap.text = "Snap"
		btn_snap.backcolor = btn_snap.backColor.lightgreen

		btn_splineOnSurface.flatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").flat
		btn_splineOnSurface.text = "Conform Splines"
		btn_splineOnSurface.backcolor = btn_splineOnSurface.backColor.orchid

        layoutTool.RegisterCallbacks()
	)

	on layoutTool_Rollout close do
	(
        layoutTool.UnregisterCallbacks()
	)

    on btn_bindToRail mousedown senderArg arg do (
        layoutTool.BindCameraToRail cb_bindWithSpaceSwitch.checked
    )

    on btn_createFollow mousedown senderArg arg do (
        layoutTool.CreateCameraSetup "Follow" cb_bindWithSpaceSwitch.checked
    )

    on btn_createPivot mousedown senderArg arg do (
        layoutTool.CreateCameraSetup "Pivot" cb_bindWithSpaceSwitch.checked
    )

	fn GetGuidesDisplay = (
		return case btn_guideType.state of (
			1:#ruleOfThird
			2:#cross
			3:#centerCross
			4:#goldenRatio
			5:#goldenTriangle
		)
	)

	on btn_guideType changed e do (
		TatViewportOps.SetGuideType  ( GetGuidesDisplay() )
	)
	
	on btn_toggleGuides mouseDown senderArg arg do (
		TatViewportOps.ToggleGuideDisplay type:(GetGuidesDisplay())
	)

	-- convert view to perspective & create camera from it. Then conform cam
	on btn_createCam mousedown senderArg arg do
	(
		layoutTool.CreateConformedCameraFromView()
	)

	on btn_selCur mouseDown senderArg arg do
	(
		layoutTool.SelectViewportCamera()
	)

	on btn_selAll mouseDown senderArg arg do
	(
		layoutTool.SelectAllCameras()
	)

	on btn_selTargets mouseDown senderArg arg do
	(
		layoutTool.SelectTargets()
	)

	-- lock selection
	on btn_Lock mouseDown senderArg arg do
	(
		layoutTool.ToggleTransformLocks (selection as array)
		layoutTool.UpdateUI()
	)

	-- change coordonate System
	on btn_Local mousedown senderArg arg do toolMode.coordsys #local
	on btn_World mousedown senderArg arg do toolMode.coordsys #world

	on btn_mirrorX mousedown senderArg args do
	(
		layoutTool.MirrorCam "x"
	)

	on btn_mirrorY mousedown senderArg args do
	(
		layoutTool.MirrorCam "y"
	)

	on btn_mirrorZ mousedown senderArg args do
	(
		layoutTool.MirrorCam "z"
	)

	on btn_generate mouseDown senderArg arg do
	(
		layoutTool.GeneratePoints()
	)

	on btn_snap mouseDown senderArg arg do
	(
		layoutTool.SnapNodes()
	)

    on btn_focalKey mouseDown senderArg arg do
    (
        LayoutTool.ToggleCameraFocalKey()
    )

    on btn_splineOnSurface mouseDown senderArg args do
	(
		confo = ConformSpaceWarp()
		confo.Icon_Size  = 100
		confo.pos.z = 200
		custAttributes.add confo ConformSpliteAttribute
		select confo
		max modify mode
	)
)
