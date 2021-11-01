global SELECTION_LOCKED = 1
global SELECTION_FREE = 2
global SELECTION_INDETERMINATE = 3

global Controls
global ViewportLib
global KiwiPackage
global Pistache
global ST_TatMultiListboxQuery
global TatLayersManager
global TatPreview_

struct ST_LayoutTool
(
	-- paths inits in TatMxsLoad
	soundFolder  = "", -- default value, set in Scripts.ms
	PrevizPath   =  "",

	previewFolder 		= @"{{LAYOUT_TOOL_SHOT_FOLDER}}\PREVIEWS",
	establishingFolder 	= @"{{LAYOUT_TOOL_SHOT_FOLDER}}\establishing_max",
	screenshotFolder 	= @"{{LAYOUT_TOOL_SHOT_FOLDER}}\establishing_previews",
	EstabFolder 		= @"{{LAYOUT_TOOL_SHOT_FOLDER}}\Estab",
	maxFolder 			= @"{{LAYOUT_TOOL_SHOT_FOLDER}}\MAX",

	screenshotFilename 		= @"{{BASENAME}}{{ABC}}_capture_Cadre{{INCREMENT}}.jpg",
	movieFilename 			= @"{{BASENAME}}.layout{{ABC}}.{{VERSION}}.mov",
	layoutMaxFileName 		= @"{{BASENAME}}.layout{{ABC}}.v000.max",
	cameraMasterHelperName 	= @"LAYOUT_CAMERAS_MASTER",

	POSITION_MODE = 1,
	ROTATION_MODE = 2,

	m_UI = undefined,
	m_screenshotUI = undefined,
	m_shakerUI = undefined,
	m_rolloutFloater = undefined,
	m_rollSaveAsFloater = undefined,
	m_dialogPos = undefined,
	m_followWireColor = color 140 88 225,
	m_pivotWireColor = color 224 86 86,
    m_rootWireColor = color 14 255 2,
	m_detectionBoxScale = 10.0,
	m_uniqueCam = undefined,
	m_dsps = Dictionary(#string),

    on create do (
    	m_dsps = Dictionary(#string)
        m_dsps["dspGeometry"] 	= True
        m_dsps["dspShapes"] 	= False
        m_dsps["dspLights"] 	= False
        m_dsps["dspCameras"] 	= False
        m_dsps["dspHelpers"] 	= False
        m_dsps["dspParticles"] 	= true
        m_dsps["dspBones"] 		= False
        m_dsps["dspGrid"] 		= False
        m_dsps["dspBkg"] 		= true
        m_dsps["dspSafeFrame"] 	= true
        m_dsps["highQuality"] 	= true
        m_dsps["LightsRender"]  = false
        m_dsps["CameraGuides"]  = false
    ),

    fn GetLightsRenderState = (
		local nvs = NitrousGraphicsManager.GetActiveViewportSetting()
		m_dsps["LightsRender"]  =  nvs.lightoption == #SceneLight
    ),

    fn GetCameraGuidesState = (
		m_dsps["CameraGuides"] 
    ),

	fn CheckPrevizPath = (
        if doesFileExist this.PrevizPath then (
            return true
        )
        else (
            LayoutToolLog.LogError "Previz dir % does not exist !" val:this.PrevizPath
            return false
        )
	),

	fn GetSoundPath = (
		try (
			return (this.soundFolder + @"\s{{SEQUENCE}}\{{BASENAME}}.wav")
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.GetSoundPath : %" val:(getCurrentException())
			return undefined
		) 
		
	),

	--  SetCamFOV :
	--	change FOV of the camera.
	--	depends of the classof of the camera

	fn IsPhysicalCam c = (
		if classof c == Physical then (
			return true
	 	)
		if classof c == Physical_Camera then (
			return true
		)
		return false
	),

	fn SetCamFOV c val = (
		-- physical camera (introduced in 2016) are bugged so not supported yet

        if isValidNode c then (
        	if this.IsPhysicalCam c then (
        		c.focal_length_mm = val
        	)
            else if classof c == FreeCamera or c == TargetCamera  then (
				LayoutToolLog.logError "Not implemented yet, please use PhysicalCamera"
    		)
    		else
    			LayoutToolLog.LogError "Invalid camera type : %" val:((classof sel) as string)
        )
        else
			LayoutToolLog.LogWarning "Current selection is not a camera"
	),

	fn IsValidBasename basename &sequence &shotName &shot  &ABC &duration &description = (
		layoutToolLog.logUltraVerbose "IsValidBasename : %" val:basename
		try (
			regexClass = dotnetclass "System.Text.RegularExpressions.Regex"

			-- PLAN Regex : s01p0001 - s40Ap1650A - s17p0416_fr18 - s01p0001_fr01-10
			fullRegex = dotNetObject regexClass "(s([0-9]{2}[A-Za-z]?)p([0-9]{4}[A-Za-z]?))(.[A-Z])?(_([0-9]+)?fr([0-9-]+)?)?$"

			fullMatch = fullRegex.match(basename)

			if fullMatch.Success then (
				layoutToolLog.logUltraVerbose "IsValidBasename : fullMatch"
				shotName = (fullMatch.groups.item(1)).value
				sequence = (fullMatch.groups.item(2)).value
				shot = (fullMatch.groups.item(3)).value
				ABC =  (fullMatch.groups.item(4)).value
				duration = (fullMatch.groups.item(6)).value
				description = trimLeft (fullMatch.groups.item(7)).value
				return true
			)
		
			layoutToolLog.logUltraVerbose "IsValidBasename : no match"
			return false
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.IsValidBasename : %" val:(getCurrentException())
		)
	),

	fn GetBasename sequence shot ABC = (
		try (
			sequence = "s" + sequence
			shot = "p" + shot
			baseName = sequence + shot + ABC

			return baseName
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.GetBasename : %" val:(getCurrentException())
		)
	),

	fn GetAllCameras = (
		-- We do this to avoid returning targets of TargetCamera
		for c in objects where superclassOf c == Camera and classof c != TargetObject collect c
	),

	fn SelectAllCameras = (
		select (GetAllCameras())
	),

	fn SelectTargets = (
		targets = for o in selection where superclassof o == camera and this.IsTargettedCamera o collect o.target
		select targets
	),

	-- Import sound corresponding to BaseName.
	-- /!\ Delete all sounds in prosound listing
	-- Returns the length in frame of the loaded sound
	fn ImportSound shotName sequence = (
		
		LayoutToolLog.LogUltraVerbose "ST_LayoutTool.ImportSound % %" val:#(shotName, sequence)
		try (
			with undo off (
				local soundPath =  (this.GetSoundPath())

				if soundPath == undefined then (
					LayoutToolLog.LogWarning "ST_LayoutTool.ImportSound : soundPath is undefined" 
					return -1
				)
				soundSourceFile = substituteString soundPath "{{SEQUENCE}}" sequence
				soundSourceFile = substituteString soundSourceFile "{{BASENAME}}" shotName

				local duration = -1

				-- What's the purpose of this ? Are we sure there's only one sound ?
				prosound.delete 1

	    		if doesfileexist soundSourceFile == false then (
					LayoutToolLog.LogError "    File not found : %" val:soundSourceFile
	                duration = -1
	            )

				--If sound exists then load it in prosound
				else (
					-- Resetting tracks first
					for i = 1 to prosound.NumTracks() do (
						prosound.delete i
					)

					prosound.append soundSourceFile
					-- Get the number of frame from File duration
					-- /!\ CARE, return a Time value (~string with value + "f")
					frameLength = prosound.end 1
					tmp = filterString (frameLength as String ) "."
					duration = tmp[1] as integer
					-- Retiming timeline with the value return in sound
					animationRange = interval  0  duration

					LayoutToolLog.LogInfo "    Imported sound : % (% frames)" val:#(soundSourceFile, duration)
				)
				return duration
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.ImportSound : %" val:(getCurrentException())
			return -1
		) 
	),

	-- CAUTION
	-- if the scene contains only 1 camera, this fn imports the sound relative to the CURRENT SCENE FILENAME
	fn ImportSoundPicker = (
		try (
			local camList = GetAllCameras()
			local camNames = for o in camList collect o.name
			local c = undefined

			if camList.count == 0 then (
				LayoutToolLog.LogInfo "No camera in scene"
				return false
			)

			if camList.count > 1 then (
				local dlg = ST_TatMultiListboxQuery()
				dlg.openDialog title:"Choose a sound to import" items:camNames caption:"Pick one camera :"

				if dlg.returnValue != undefined and dlg.returnValue.isEmpty == false then (
					if (dlg.returnValue as array).count == 1 then (
						c = (for index in dlg.returnValue collect camList[index])[1]
					)
					else (
						LayoutToolLog.LogWarning "You must pick one camera only"
					)	
				)
			)
			else (
				c = camList[1]
			)

			if this.IsValidBasename c.name  &seq &shotName &ABC &shot &camDuration &description then (
				format "cam duration % \n" camDuration
				LayoutToolLog.LogInfo "Processing : %" val:c.name
				soundDuration = this.ImportSound shotName seq
			)
			else (
				LayoutToolLog.LogError "Invalid camera name : %" val:c.name
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.ImportSoundPicker : %" val:(getCurrentException())
		)
	),

	fn ConformPhysical c = (
		c.show_camera_cone = 0 -- when selected
		c.horizon_on = true
		c.clip_on = false
		c.clip_near = 1
		c.target_distance = 500
		c.targeted = false
		c.specify_fov = false
		c.lens_breathing_amount = 0
	),

	fn ConformCam c = (
		
		if superClassOf c == camera then (
			c.film_preset = "35mm"
		) 
		case (classof c) of (
			FreeCamera: (
				c.showCone = true
				c.baseObject.targetDistance = 100.0
				c.showHorizon = true
				c.clipManually = true
				c.nearclip = 1
			)
			TargetCamera: (
				c.type = #free
				c.baseObject.targetDistance = 100.0
				c.showHorizon = true
				c.clipManually = true
				c.nearclip = 1
			)
			Physical_Camera: (
				this.ConformPhysical c
			)
			Physical: (
				this.ConformPhysical c
			)
			default: LayoutToolLog.LogWarning "Camera type not supported yet"
		)
	),
	
	fn GetCameraLayer = (
		layer = LayerManager.getLayerFromName "Cameras"
		if layer == undefined then (
			layer = LayerManager.newLayer()
			layer.setName "Cameras"
		)
		layer
	),

	fn InitCameraMaster = (
		cameraMaster = undefined
		with animate off (
			cameraMaster = getNodeByName this.cameraMasterHelperName

			if not isValidNode cameraMaster then (
				cameraMaster = Point name:this.cameraMasterHelperName

				layer = this.GetCameraLayer()
				layer.addnode cameraMaster

				hide cameraMaster
				freeze cameraMaster
			)
		)
		cameraMaster
	),

	fn ResetViewportLayout = (
		try (
			with animate off (
				local cam = (for c in cameras where superclassOf c == Camera collect c)[1]
				
				if isValidNode cam then (
					ViewportLib.ResetViewportLayout cam:cam
					cam.film_preset = "35mm"
				)
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.CreateConformedCameraFromView : %" val:(getCurrentException())
		)
	),

	fn CreateConformedCameraFromView = (
		try (
			with animate off (
				try (
					local cam = ViewportLib.CreateCameraFromView()
					
					if isValidNode cam then (

						this.ConformCam cam

						local cameraMaster = this.InitCameraMaster()
						local layer = this.GetCameraLayer()
						layer.addnode cam
						cam.parent = cameraMaster

						cam.focal_length_mm.controller = bezier_float()
						this.UpdateFocalKeyState()	
					)
				) catch(
					print "Error!"
				)
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.CreateConformedCameraFromView : %" val:(getCurrentException())
		)
	),

	fn SelectViewportCamera = (
		camNode = getActiveCamera()
		if camNode != undefined then
			select camNode
		else
			clearSelection()
	),

	fn GetSeqFromRootFolder  rootfolder = (
		local os = Python.Import "os"
		(os.path.split  rootfolder)[2]
	),

    fn GetShotRootFolder = (
        if maxFilename == "" then
			throw "Please save scene first"

		os = Python.Import "os"
        local dir = os.path.join maxFilePath ".."
        dir = os.path.abspath dir
		dir
    ),
	
	fn GetSavedDir  firstChoiseFolder secondChoiseFolder = (
		local dir
		local rootFolder = this.GetShotRootFolder()

		local dir = substituteString firstChoiseFolder "{{LAYOUT_TOOL_SHOT_FOLDER}}" rootFolder
		if not doesfileExist dir then (
			dir = substituteString secondChoiseFolder "{{LAYOUT_TOOL_SHOT_FOLDER}}" rootFolder
		)
		if not doesfileExist dir then (
			dir = rootFolder
		)	
		dir
	),

	fn TakeMovie = (
		local physCamera = getActiveCamera()
		if physCamera == undefined then (
			messageBox "Active view is not a camera"
			return false
		)
			
		if this.IsValidBasename physCamera.name &seq &shotName &shot &ABC &camDuration &description then (
			
			local version = "v000"
			if matchPattern maxFilename pattern:"*estab*" then (
				version = "v000"
			)
			else ( 
				regexClass = dotnetClass "system.text.regularexpressions.regex"
				regex = dotnetObject regexClass @".*\.(v[0-9]+(?:\.[A-Z])?)\..*"
				
				m = regex.match maxFilename
				if m.success then (
					version = m.groups.item[1].value
				)
				else (
					version = "v000"
				)
			)
			
			local dir = this.GetSavedDir  this.previewFolder  this.EstabFolder
			dir = getSavePath initialDir:dir

			if dir == undefined then (
				return undefined
			)
			local outputFilename = substituteString this.movieFilename "{{BASENAME}}" shotName
			outputFilename = substituteString outputFilename "{{ABC}}"  ABC		
			outputFilename = substituteString outputFilename "{{VERSION}}" version
			outputFilename = dir + @"\" + outputFilename

 			TatPreview_.MakePreview  outputFilename:outputFilename   dsps:m_dsps
		)			
	),

	fn TakeScreenshots  = (

		local camList = this.GetAllCameras()
		fn compareNames str1 str2 = stricmp str1.name str2.name
		qsort camList compareNames
		local camNames = for o in camList collect o.name

		if camList.count == 0 then (
			LayoutToolLog.LogInfo "No camera in scene"
			return false
		)
		if camList.count > 1 then (
            local dlg = ST_TatMultiListboxQuery()
			dlg.openDialog title:"Choose camera to export" items:camNames caption:"Cameras :"
			print 
            if dlg.returnValue != undefined and not dlg.returnValue.isEmpty  then (
				camList = for index in dlg.returnValue collect camList[index]
			)
			else (
				camList = #()
			)
        )
		if camList.count == 0 then (
			return false
		)

		local dir = this.GetSavedDir  this.screenshotFolder  this.EstabFolder
		dir = getSavePath initialDir:dir
		if dir == undefined then (
			return false
		)

		TatPreview_.setPreviewSettings  m_dsps["LightsRender"]

		for c in camList do (
			LayoutToolLog.LogInfo "Capturing camera : %" val:c.name
			if this.IsValidBasename c.name &seq &shotName &shot &ABC &duration &description then (
				this.ScreenshotKeys c seq shotName ABC description dir
			)
			else (
				LayoutToolLog.LogError "Invalid basename : %" val:c.name
			)
		)
		return true
	),

	fn ScreenshotKeys physCamera seq shotName ABC description dir  = (
		
		LayoutToolLog.LogTxt "ScreenshotKeys physCamera:% seq:% shotName:% askFolderLocation:%" val:#(physCamera, seq, shotName, askFolderLocation)

		viewport.setCamera physCamera

		local captureTimes = #()

		if classof physCamera.transform.controller == lookat then (
			ctrlList = #(physCamera.transform.controller.position.controller, physCamera.transform.controller.scale.controller, physCamera.focal_length_mm.controller, physCamera.target.transform.controller.position.controller)
		) else (
			ctrlList = #(physCamera.transform.controller.position.controller, physCamera.transform.controller.rotation.controller, physCamera.transform.controller.scale.controller,  physCamera.focal_length_mm.controller, physCamera.target_distance.controller)
		)

		for ctrl in ctrlList do (
			if ctrl == undefined then
				continue
			
			if findItem #(position_list, rotation_list, scale_list) (classof ctrl) > 0 then (
				for i=1 to ctrl.count do (
					for key in ctrl[i].keys do (
						LayoutToolLog.LogUltraVerbose "    key : %" val:key
						appendIfUnique captureTimes key.time
					)
				)
			)
			else (
				for key in ctrl.keys do (
					LayoutToolLog.LogUltraVerbose "    key : %" val:key
					appendIfUnique captureTimes key.time
				)
			)
		)
		if captureTimes.count == 0 then (
			append captureTimes 0f
		)
        local incrementLUT = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

		for i = 1 to captureTimes.count do (
			 
			local captureTime = captureTimes[i]
			local increment = incrementLUT[i]

			local screenshotName = ""
			
			screenshotName = substituteString this.screenshotFilename "{{BASENAME}}" shotName
			screenshotName = substituteString screenshotName"{{ABC}}"  ABC		
			screenshotName = substituteString screenshotName "{{INCREMENT}}" increment
			
			local screenshotFile = dir + @"\" + screenshotName

            if isDirectoryWriteable dir then (

				TatPreview_.TakeScreenshot outputFilename:screenshotFile attime:captureTime  dsps:m_dsps defaultSettings:false
                LayoutToolLog.LogInfo "    Screenshot : %" val:screenshotFile
            )
            else (
                LayoutToolLog.logWarning "Impossible d'écrire le fichier : %" val:screenshotFile
                messageBox ("Impossible d'écrire le fichier :\n" + screenshotFile)
            )
		)
	),

	fn ExportScene physCamera seq shotname ABC dir convertCam:false = (
		try (
			with undo off (
				LayoutToolLog.logTxt "ExportScene % % %" val:#(physCamera.name, seq, shotname)
				
				outputFileName = substituteString layoutMaxFileName "{{SEQUENCE}}" seq
				outputFileName = substituteString outputFileName "{{BASENAME}}" shotname
				outputFileName = substituteString outputFileName "{{ABC}}"  ABC

				outputFilename = dir + "\\" + outputFilename

				if convertCam then
					LayoutToolLog.LogInfo "Processing % -> %" val:#(physCamera.name, shotName)
				else
					LayoutToolLog.LogInfo "Processing %" val:physCamera.name

				soundDuration = this.ImportSound shotname seq

				if outputFilename != undefined then (
					if convertCam then (
						LayoutToolLog.LogUltraVerbose "ExportScene : convertCam true"
						
						newName = shotname + ABC 

						if soundDuration > 0 then
							newName  += "_" + (soundDuration as string) + "fr"
						else
							newName += "_XXXXfr"

		    			LayoutToolLog.LogInfo "    Camera name    : %" val:newName
						physCamera.name = newName

						saveMaxFile outputFilename
						LayoutToolLog.LogInfo "    File saved as  : %" val:outputFilename
					)
					else (

						LayoutToolLog.LogUltraVerbose "ExportScene : convertCam false"
						local camName = physCamera.name

						if soundDuration != -1 then (
							tokens = filterString physCamera.name "_"
							physCamera.name = tokens[1] + "_" + (soundDuration as string) + "fr"
						)

						camNodes = for o in objects where superclassof o == camera collect o
						join camNodes (for o in objects where classof o == TAT_CameraGuides collect o)
						sceneNodes = for o in objects where findItem camNodes o == 0 collect o
							
						append sceneNodes physCamera
						join sceneNodes (for o in shapes where classof o == TAT_CameraGuides and o.parent == physCamera collect o)

						LayoutToolLog.LogInfo "    Locking camera : Done"
						setTransformLockFlags physCamera #all

						saveNodes sceneNodes outputFilename
						LayoutToolLog.LogInfo "    Exported file  : %" val:outputFilename

						setTransformLockFlags physCamera #none
						physCamera.name = camName

						-- Resetting tracks first
						for i = 1 to prosound.NumTracks() do (
							prosound.delete i
						)
					)
					return outputFilename
				)
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.ExportScene : %" val:(getCurrentException())
		)
		return false
	),

	fn GetSeqShot  &seq &shot &ABC = (
		if isValidNode m_uniqueCam then (
			return this.IsValidBasename m_uniqueCam.name &seq &shotName &shot &ABC &duration &description
		)
		return false
	),

	fn SaveAs seq shot ABC = (
		try (
			if isValidNode m_uniqueCam  then (
				-- No screenshot in convert physCamera workflow.
	            if not prosound.isActive() then (
	                prosound.init true
                )
	            prosound.SetPlaybackActive true

				basename = this.GetBasename seq shot ABC
				
				if this.IsValidBasename basename &seq &shotName &shot &ABC &duration &description then (
					local dir = getSavePath initialDir:maxFilePath
					if dir == undefined then (
						return false
					)
					this.ExportScene m_uniqueCam seq shotName ABC dir convertCam:true
				) else (
					LayoutToolLog.LogError "Invalid basename : %" val:basename
				)
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.SaveAs : %" val:#(getCurrentException(),getCurrentExceptionStackTrace())
		)
	),

	fn GetViewportConfig &cam &layout &type = (
		cam = viewport.getCamera()
		layout = viewport.getLayout() 
		type =viewport.getType()
	),

	fn SetViewportConfig cam layout type = (
		if isValidNode cam then (
			viewport.setCamera cam
		) 
		viewport.setLayout layout
		if type != #view_camera then (
			viewport.setType type
		)
	),

	fn MergeSkyMaxFile  &mergedSky = (
		mergedSky = #()
		local kiwiMaxFile = KiwiPackage.GetMaxFile  "X_FxCiel"  "FX"  "Argonautes" "Layout"
		if doesFileExist kiwiMaxFile.FilePath do (
			mergeMAXFile kiwiMaxFile.FilePath  #skipDups  #useMergedMtlDups  #alwaysReparent  mergedNodes:&mergedSky  
		)
	),


	fn UnMergeSkyMaxFile merged = (
		delete merged
	),

	fn ExportEstablishing mergeSky:false = (
		try (
			local camList = this.GetAllCameras()
			local camNames = for o in camList collect o.name

			if camList.count == 0 then (
				LayoutToolLog.LogInfo "No camera to export"
				return false
			)

            if not prosound.isActive() then
                prosound.init true
            prosound.SetPlaybackActive true

			dlg = ST_TatMultiListboxQuery()
			dlg.openDialog title:"Choose camera to export" items:camNames caption:"Cameras :"

			if dlg.returnValue == undefined or dlg.returnValue.isEmpty  then (
				return false
			)

			local camToExport = for index in dlg.returnValue collect camList[index]

			local dir = this.GetSavedDir  this.maxFolder  ""
			local dir = getSavePath initialDir:dir
			
			if dir == undefined then (
				return false
			)

			local lastExportFilename = undefined
			local keyArrays = undefined
			local nodes = #()

		  
			local progfactor = 100.0 / camToExport.count
			local progVal = 0
			local rgx = dotNetObject "System.Text.RegularExpressions.Regex" ""

			progressStart ("Export Establishing : " )

			this.GetViewportConfig &restoreCam &layout &type 
			if mergeSky then (
				this.MergeSkyMaxFile  &mergedSky 
			)
			for i = 1 to camToExport.count do (
				local c  = camToExport[i]
			
				progressUpdate ( progVal +  progfactor * 0.1 )

				if this.IsValidBasename c.name &seq &shotName &shot &ABC &duration &description then (
					
					local currentAnimationRange = animationRange
						
					local iskeyRange = this.GetDescriptionKeyRange description &startRange &endRange

					ViewportLib.ResetViewportLayout  cam:c  SafeFrameMaxCB:false
					
					progressUpdate ( progVal +  progfactor * 0.3 )

					if iskeyRange then (
						if keyArrays == undefined then (
							keyArrays = #()
							nodes = for n in ( $* as array) where n.isAnimated or rgx.isMatch n.name "_ROOT|_CTRL" collect n

							for n in nodes do (
								keyArrays += keysManager.GetNodeKeyArray n  subLimit:100
							)
						)
						this.ShiftEstablishing  startRange endRange nodes keyArrays 
					)
					
					progressUpdate ( progVal + progfactor * 0.5 )
					
					this.ExportScene c seq shotName  ABC   dir

					progressUpdate ( progVal +  progfactor * 0.8 )

					if iskeyRange then (
						max undo
					)
					animationRange = currentAnimationRange
				)
				else (
					LayoutToolLog.LogError "Invalid basename : %" val:c.name
				)
				progressUpdate ( progVal + progfactor )
				progVal +=  i * progfactor
			)
			progressEnd() 

			this.SetViewportConfig restoreCam layout type 
			if mergeSky then (
				this.UnMergeSkyMaxFile mergedSky
			)
		)
		catch (
			LayoutToolLog.LogError "ST_LayoutTool.ExportEstablishing : %" val:(getCurrentException())
		)
	),

	fn GetDescriptionKeyRange description &startRange &endRange = (

		if description == "" then (
			return false
		)
		if ( startRange = description as integer ) != undefined then (
			endRange = startRange
			return true
		)
		local buffer =  filterstring description "-"

		if buffer.count == 2 and ( startRange = buffer[1] as integer ) != undefined and ( endRange = buffer[2] as integer ) != undefined then (
			return true
		)
		return false
	),

	fn ShiftEstablishing  startRange endRange nodes keyArrays = (
		undo "ShiftEstablishing" on (

			for keyArray in keyArrays do (
				try (
					addNewKey  keyArray  startRange
					if endRange != startRange then (
						addNewKey  keyArray  endRange
					)
					for i = keyArray.count  to 1 by -1 where  keyArray[i].time < startRange or keyArray[i].time > endRange  do (
						deleteKey keyArray i
					)
					for i = 1 to keyArray.count  do (
						keyArray [i].time -= startRange
					)
				)catch (
				--	LayoutToolLog.LogWarning "ST_LayoutTool.ShiftEstablishing : %" val:(getCurrentException())
				)
			)
			Animationrange = interval 0  100 
		)
	),

	fn GeneratePoints = (
		nodes = selection as array
		generatedPoints = #()
		for obj in (selection as array) do (
			if matchPattern obj.name pattern:"*_ROOT_LAYOUT" == false then
				targetName = "point_" + obj.name + "_layout"
			else
				targetName = "point_" + obj.name
			targetPoint = getNodeByName targetName

			if targetPoint == undefined then (
				targetPoint = Point pos:[0,0,0] isSelected:off name:targetName
				targetPoint.cross = true
				targetPoint.box = false
				targetPoint.axisTripod = false
				targetPoint.centerMarker = false
				LayoutToolLog.logInfo "Creating point : %" val:targetName
			)
			else
				LayoutToolLog.logInfo "Using existing point : %" val:targetName

			append generatedPoints targetPoint
			targetPoint.transform = obj.transform
		)
		select generatedPoints
		LayoutToolLog.LogInfo "Points generated : %" val:nodes.count
	),

	fn SnapNodes = (
		snapCount = 0

		nodes = selection as array

		if nodes.count == 0 then (
			if querybox "Process all scene roots ?" then (
				join nodes ($A_*_ROOT_LAYOUT as array)
				join nodes ($P_*_ROOT_LAYOUT as array)
				join nodes ($P_*_ROOT as array)
				join nodes ($A_*_ROOT as array)
			)
		)


		for obj in nodes do (
			-- Two cases :
			-- 		Snapping theObj_layout -> point_theObj
			-- 		Snapping theObj -> point_theObj_layout

			if matchPattern	obj.name pattern:"*_ROOT_LAYOUT" == true then
				targetName = "point_" + obj.name
			else
				targetName = "point_" + obj.name + "_layout"

			--LayoutToolLog.LogTxt "% -> %" val:#(obj.name, targetName)
			targetPoint = getNodeByName targetName

			if targetPoint != undefined then (
				LayoutToolLog.LogInfo "Snapping : % -> %" val:#(obj.name, targetName)
				obj.transform = targetPoint.transform
				snapCount += 1
			)
		)
		LayoutToolLog.LogInfo "Objects snapped : %/%" val:#(snapCount, nodes.count)

	),

	fn IsSelectionCompletlyLockedTheSameWay nodes = (
		lockSetups = #()

		for n in nodes do
			appendIfUnique lockSetups (((getTransformLockFlags n) as array).count)

		return lockSetups.count == 1
	),

	fn GetTransformLockStatus nodes = (
		if IsSelectionCompletlyLockedTheSameWay nodes == false then
			return SELECTION_INDETERMINATE

		locks = getTransformLockFlags nodes[1]
		if (locks as array).count == 9 then
			return SELECTION_LOCKED
		if locks.isEmpty == true then
			return SELECTION_FREE

		return SELECTION_INDETERMINATE
	),

	fn ToggleTransformLocks nodes = (
		nodes = selection as array

		if nodes.count > 0 then (
			case (GetTransformLockStatus nodes) of (
				SELECTION_INDETERMINATE: setTransformLockFlags nodes #all
				SELECTION_FREE: setTransformLockFlags nodes #all
				SELECTION_LOCKED: setTransformLockFlags nodes #none
			)
		)
	),

	fn MirrorCam axis = (
		if selection.count == 1 and superclassof selection[1] == camera then (
			Controls.MirrorPickNode selection[1] axis
		)
	),

    fn UpdateFocalKeyState = (
        if m_UI != undefined and m_UI.open == true then (

            if selection.count == 1 and superclassof selection[1] == camera then (
                c = selection[1]
				
				if not this.IsPhysicalCam c then (
					LayoutToolLog.LogError "UpdateFocalKeyState not implemented yet. Please use Physical_Camera only"
					return false
				) 

                if c.focal_length_mm.controller == undefined then (
                	c.focal_length_mm.controller = bezier_float()
                )

                m_UI.spn_focalLength.controller = c.focal_length_mm.controller
                m_UI.spn_focalLength.enabled = true

                keyFound = false

                local ctrl = c.focal_length_mm.controller
                if ctrl != undefined then (
                    for key in ctrl.keys do (
    					if key.time == currentTime then (
                            keyFound = true
                            break
                        )
    				)
                )

                if keyFound then (
                    m_UI.btn_focalKey.backcolor = m_UI.btn_focalKey.backColor.lightgreen
                    m_UI.btn_focalKey.text = "Focal Key @ " + (currentTime as string)
                )
                else (
                    m_UI.btn_focalKey.backcolor = m_UI.btn_focalKey.backColor.indianred
                    m_UI.btn_focalKey.text = "Focal Key"
                )
            )
            else (
            	m_UI.spn_focalLength.controller = bezier_float()
            	m_UI.spn_focalLength.value = 0.0 
            	m_UI.spn_focalLength.enabled = false
                m_UI.btn_focalKey.backcolor = m_UI.btn_Lock.backColor.gray
                m_UI.btn_focalKey.text = "Focal Key"
            )
        )
    ),

	fn IsTargettedCamera c = (
		classof c == TargetCamera or (this.IsPhysicalCam c and c.targeted)
	),

	fn SetShakerParams onOff = (
		m_shakerUI.edit_frequency.enabled = onOff
		m_shakerUI.edit_strengthX.enabled = onOff
		m_shakerUI.edit_strengthY.enabled = onOff
		m_shakerUI.edit_strengthZ.enabled = onOff
		m_shakerUI.edit_weight.enabled = onOff
		
		if not onOff then (
			m_shakerUI.edit_frequency.text = ""
			m_shakerUI.edit_strengthX.text = ""
			m_shakerUI.edit_strengthY.text = ""
			m_shakerUI.edit_strengthZ.text = ""
			m_shakerUI.edit_weight.text = ""
		)
	),

	fn UpdateShakerControls noise_index:undefined = (
		/*
		* Enable noise parameters if the user select a camera with a noise linked to it or a point with a noise modifier.
		* Get values of noise'parameters.
		*/

		if m_shakerUI == undefined then
			return false

		local prMode = m_shakerUI.btn_modeShaker.state
		local physCamera = selection[1]

		if selection.count != 1 or superclassof selection[1] != camera or ( prMode == ROTATION_MODE and this.IsTargettedCamera physCamera ) then (
			SetShakerParams false
			m_shakerUI.lbl_controllerName.text = ""
			m_shakerUI.spn_controllerIndex.value = 1
			m_shakerUI.spn_controllerIndex.enabled = False 
			return false
		)

		local prC = if prMode == POSITION_MODE then physCamera.position.controller else physCamera.rotation.controller

		local ctrl = undefined
		local ctrlName = ""
		local countC = 1

		if classof prC == Position_List or classof prC == Rotation_List  then (
			countC = prC.count
			if noise_index == undefined then (
				noise_index = prC.getActive()
			) else if noise_index > countC then (
				noise_index = countC
			)
			prC.setActive noise_index

			ctrl = prC[noise_index].controller
			ctrlName = prC.GetName  noise_index
			if noise_index > 1 then (
				local typeName = if classof ctrl == noise_position or classof ctrl == noise_rotation then "Noise" else "Keyframe"
				ctrlName += " - " + typeName
			)
		) else (
			noise_index = 1
			ctrl = prC
			ctrlName = classof ctrl  as string
		)
		-- update info of selected controller
		m_shakerUI.lbl_controllerName.text = ctrlName  
		m_shakerUI.lbl_controllerCount.text = countC as string   
		m_shakerUI.spn_controllerIndex.value = noise_index
		m_shakerUI.spn_controllerIndex.enabled = True

		-- enable the textbox and update their values with noise controller's one
		if classof ctrl == noise_position or classof ctrl == noise_rotation then (
			
			local strength = #()
			for i = 1 to 3 do (
				strength[i] = ctrl.noise_strength[i]
				if prMode == ROTATION_MODE then (
					strength[i] *= (180/pi)
				)
			)

			this.SetShakerParams true
			m_shakerUI.edit_frequency.text = (ctrl.frequency as string)
			m_shakerUI.edit_strengthX.text = (strength[1] as string)
			m_shakerUI.edit_strengthY.text = (strength[2] as string)
			m_shakerUI.edit_strengthZ.text = (strength[3] as string)
			
			m_shakerUI.edit_weight.text = (prC.weight[noise_index] as string) 
		) else (
			this.SetShakerParams false
		)
	),

	fn UpdateUI = (
		if m_UI != undefined and m_UI.open == true then (

			m_screenshotUI.cb_light.checked = this.GetLightsRenderState()

			nodes = selection as array
			if nodes.count > 0 then (
				case (GetTransformLockStatus nodes) of (
					SELECTION_INDETERMINATE: (
						m_UI.btn_Lock.backcolor = m_UI.btn_Lock.backColor.gray
						m_UI.btn_Lock.text = "Indeterminate locking"
					)
					SELECTION_FREE: (
						m_UI.btn_Lock.backcolor = m_UI.btn_Lock.backColor.lightgreen
						m_UI.btn_Lock.text = "Everything is free"
					)
					SELECTION_LOCKED: (
						m_UI.btn_Lock.backcolor = m_UI.btn_Lock.backColor.indianred
						m_UI.btn_Lock.text = "Everything is locked"
					)
				)

				-- enable/disable button to create a noise on camera
				if superclassof nodes[1] == camera then (
					m_shakerUI.btn_addShaker.enabled = True
				)
				else (
					m_shakerUI.btn_addShaker.enabled = False
				)
			)
			else (
				m_UI.btn_Lock.backcolor = m_UI.btn_Lock.backColor.gray
				m_UI.btn_Lock.text = "Empty selection"
				m_shakerUI.btn_addShaker.enabled = False
			)
            UpdateFocalKeyState()
			UpdateShakerControls()
		)
	),

    fn BrowseScreenshots = (
    	local dir = this.GetSavedDir  this.screenshotFolder  this.EstabFolder

        if doesFileExist dir then (
            ShellLaunch dir ""
        ) else (
            messageBox ("Impossible d'ouvrir le dossier :\n\n" + dir)
		)
    ),

    fn BrowsePreviews = (
    	local dir = this.GetSavedDir  this.previewFolder  this.EstabFolder

        if doesFileExist dir then (
            ShellLaunch dir ""
        ) else (
            messageBox ("Impossible d'ouvrir le dossier :\n\n" + dir)
		)
    ),

    fn BrowseSounds = (
    	local rootFolder = this.GetShotRootFolder()
    	local seq = this.GetSeqFromRootFolder rootFolder
    	local dir = this.soundFolder + "\\" + seq

        if doesFileExist dir then(
        	ShellLaunch dir ""
       	)else if doesFileExist   this.soundFolder then (
   			ShellLaunch this.soundFolder ""
        )else (
            messageBox ("Impossible d'ouvrir le dossier :\n\n" + dir)
    	)
    ),

    fn BrowseLibPistache = (
    	if Pistache != undefined then (
    		local rootFolder = this.GetShotRootFolder()
    		local seq = this.GetSeqFromRootFolder rootFolder
    		local dir = Pistache.DatabasePath + "\\" + seq

        	if doesFileExist dir then (
            	ShellLaunch dir ""
	        )else if doesFileExist Pistache.DatabasePath then (
	            ShellLaunch Pistache.DatabasePath ""
	        )else (
	            messageBox ("Impossible d'ouvrir le dossier :\n\n" + dir)
            )
    	)
    	else (
			messageBox ("Error : Pistache not found")
    	)
    ),

	fn BrowseCurrentSceneFolder = (

		if maxFilePath != "" then
			ShellLaunch maxFilePath "" 
		else
			messageBox ("La scène actuelle n'est pas sauvegardée")
	),

	fn AddNoisePositionToCam frequency:0.1 strength:50 = (
		if selection.count == 1 and superclassof selection[1] == camera do (

			physCamera = selection[1]

			-- set a position controller to keep animation on camera's position (if no position is already present)
			if (classof physCamera.position.controller == Position_XYZ) do (
				physCamera.pos.controller = position_list ()
			)

			-- set a noise controller on camera to add noise
			local listC = physCamera.position.controller

			if listC.count < 5 then ( 
				listC.Available.controller = noise_position()

				local index = listC.count
				listC.setName  index  "Shake Position"

				noise_controller = listC[ index ]
				noise_controller.seed = random 0 1 --Starts the noise calculations. Changing the seed creates a new curve.
				noise_controller.fractal = off
				noise_controller.frequency = frequency
				noise_controller.noise_strength = [strength,strength,strength]

				-- update controls allowing user to modify noise parameters
				m_shakerUI.spn_controllerIndex.value = index
				UpdateShakerControls  noise_index:index
			)
		)
	),

	fn AddNoiseRotationToCam frequency:0.1 strength:50 = (
		if selection.count == 1 and superclassof selection[1] == camera then (

			physCamera = selection[1]

			if IsTargettedCamera physCamera then (
				messageBox "You can't add Noise_Rotation on a targetted camera." title:"Invalid Camera type"
				return false
			)

			-- set a rotation controller to keep animation on camera's rotation (if no rotation is already present)
			if (classof physCamera.rotation.controller == Euler_XYZ) do (
				physCamera.rotation.controller = rotation_list ()
			)

			-- set a noise controller on camera to add noise
			local listC = physCamera.rotation.controller

			if listC.count < 5 then ( 
				listC.Available.controller = noise_rotation()

				local index = listC.count
				listC.setName  index  "Shake Rotation"

				noise_controller = listC[ index ]
				noise_controller.seed = random 0 1 --Starts the noise calculations. Changing the seed creates a new curve.
				noise_controller.fractal = off
				noise_controller.frequency = frequency
				noise_controller.noise_strength = [strength*(pi/180),strength*(pi/180),strength*(pi/180)]

				-- update controls allowing user to modify noise parameters
				-- FIXME : not very classy to update this from here
				m_shakerUI.spn_controllerIndex.value = index
				UpdateShakerControls noise_index:index
			)
		)
		else (
			messageBox "Invalid selection"
		)
	),

	fn ConvertShaker mode index = (
		/*
		* Delete desired noise controller on the selected camera
		*/
		-- controllerIndex is locked by the UI, range starts goes from 2 to 5
		undo "convertShaker" on (
			if index > 1 and selection.count == 1 and superclassof selection[1] == camera then (

				local physCamera = selection[1]
				local posList = physCamera.position.controller 
				local rotList = physCamera.rotation.controller

				if mode == POSITION_MODE and classof posList == Position_List and index <= posList.count then (

					local newCtrl = if classof posList[index].controller == Noise_Position then Position_Xyz() else Noise_Position()
					posList[index].controller = newCtrl
					posList.setName index "Shake Position"
				)
				else if mode == ROTATION_MODE and classof rotList == Rotation_List  and index <= rotList.count then (
					
					local newCtrl = if classof rotList[index].controller == Noise_Rotation then Euler_XYZ() else  Noise_Rotation()
					rotList[index].controller = newCtrl
					rotList.setName index "Shake Rotation"
				)
				else (
					LayoutToolLog.logWarning "Targetted controller is not a Noise Controller"
				)
				-- update controls allowing user to modify noise parameters
				UpdateShakerControls()
			)
		)
	),


	fn RemoveShaker mode index = (
		/*
		* Delete desired noise controller on the selected camera
		*/
		-- controllerIndex is locked by the UI, range starts goes from 2 to 5
		undo "RemoveShaker" on (
			if index > 1 and selection.count == 1 and superclassof selection[1] == camera then(

				local physCamera = selection[1]
				local posList = physCamera.position.controller
				local rotList = physCamera.rotation.controller

				if mode == POSITION_MODE and classof posList == Position_List and index <= posList.count then  (
						posList.delete index
				)
				else if mode == ROTATION_MODE and classof rotList == Rotation_List and index <= rotList.count then  (
						rotList.delete index
				)
				else (
					LayoutToolLog.logWarning "Targetted controller is not a Noise Controller"
				)
				-- update controls allowing user to modify noise parameters
				UpdateShakerControls()
			)
		)
	),

	fn ModifyNoiseParameters param value controllerIndex = (
		/*
		* Change the value of one of the noise'parameters.
		* @param param, the parameter to change.
		* @param value, the new value to set for the given parameter.
		*/

		if (selection.count != 1 or superclassof selection[1] != camera) then (
			this.SetShakerParams false
			return false
		)

		physCamera = selection[1]
		
		if superclassof physCamera != camera then (
			LayoutToolLog.logError "Current selection is not a camera"
			return false
		)
		
		noise_controller = undefined

		case m_shakerUI.btn_modeShaker.state of (
			POSITION_MODE: (
				if classof physCamera.position.controller == Position_List and classof physCamera.position.controller[controllerIndex].controller == Noise_Position then
					noise_controller = physCamera.position.controller[controllerIndex].controller
			)
			ROTATION_MODE: (
				if classof physCamera.rotation.controller == Rotation_List and classof physCamera.rotation.controller[controllerIndex].controller == Noise_Rotation then (
					noise_controller = physCamera.rotation.controller[controllerIndex].controller
					if (matchPattern (param as string) pattern:"strength*") do (
						value = value * (pi/180)
					)
				)
			)
		)


		if noise_controller != undefined do (
			case param of (
				#frequency : noise_controller.frequency = value
				#strengthX : noise_controller.noise_strength = [value, noise_controller.noise_strength[2], noise_controller.noise_strength[3]]
				#strengthY : noise_controller.noise_strength = [noise_controller.noise_strength[1], value, noise_controller.noise_strength[3]]
				#strengthZ : noise_controller.noise_strength = [noise_controller.noise_strength[1], noise_controller.noise_strength[2], value]
				#posWeight : physCamera.pos.controller.weight[controllerIndex] = value
				#rotWeight : physCamera.rotation.controller.weight[controllerIndex] = value
			)
		)

		UpdateShakerControls()
	),

	 fn BindCameraToRail addSpaceSwitch nodes:(selection as array) = (
        if nodes.count != 1 or superclassof nodes[1] != camera then (
        	messageBox "You must select a camera first."
        	return false
        )
        local c = nodes[1]
		local cameraMaster = this.InitCameraMaster()

        fn shapeFilt o = (superClassOf o == Shape)
        local railNode = pickObject rubberBand:c.pos rubberBandColor:yellow filter:shapeFilt

        if isValidNode railNode then (
        	undo "BindCameraToRail" on (
	        	with animate off (
	        		suspendEditing()
					railNode.name = c.name + "_Rail"
					railNode.parent = cameraMaster

					setupPoint = point name:((c.name + "_Follow"))  cross:false box:true wireColor:m_followWireColor size:160	
					pLink = point name:((c.name + "_Pivot")) cross:true box:false wireColor:m_pivotWireColor size:160
					
					posList = position_list()
					pathc 		= path_constraint()
					pathc.percent.controller =  bezier_float()
		            pathc.follow = true
					pathc.appendTarget railNode 100
					posList.available.controller = pathc
					setupPoint.position.controller = posList
					pLink.transform = setupPoint.transform
					c.parent = pLink
					setupPoint.parent = cameraMaster
					
					if addSpaceSwitch then (
						pLink.parent = cameraMaster
						local sw = SpaceSwitchManager.AddSpaceSwitch pLink
						sw.SetCurrentParent setupPoint
					)
					else (
						pLink.parent = setupPoint
					)
					local layer = GetCameraLayer()
					layer.addnode setupPoint
					layer.addnode pLink
					layer.addNode railNode
					resumeEditing()
					redrawViews()
				)
			)
        )
    ),

	fn CreateCameraSetup setupType addSpaceSwitch  nodes:(selection as array) = (
		if nodes.count == 1 and superclassof nodes[1] == camera then (
			local c = nodes[1]

			local targetNode = pickObject rubberBand:c.pos rubberBandColor:yellow

			if isValidNode targetNode then (
				undo "CreateCameraSetup" on (
					with Animate off (
						suspendEditing()
						local cameraMaster = InitCameraMaster()
						
						local wirecolor, typePoint  
						local isPivot = true

						if setupType == "Follow" then (
							isPivot = false
							wireColor = m_followWireColor
						)else (
							wireColor = m_pivotWireColor
						)
						local setupPoint = point name:((c.name + "_" + setupType))  cross:isPivot box:(not isPivot) wireColor:wireColor size:160	

						setupPoint.transform = targetNode.transform
						setupPoint.scale = [1,1,1]
						setupPoint.parent = cameraMaster

						local layer = GetCameraLayer()
						layer.addNode setupPoint

						if addSpaceSwitch then (
							pLink = point name:(c.name + "_Link") cross:true box:false wireColor:m_rootWireColor size:160
							pLink.transform = c.transform
							pLink.parent = cameraMaster
							local sw = SpaceSwitchManager.AddSpaceSwitch pLink
							sw.SetCurrentParent setupPoint
							layer.addNode pLink
							c.parent = pLink
						)
						else (
							c.parent = setupPoint
						)
						resumeEditing()
						redrawViews()
					)
				)
			)
		)
		else
			messageBox "You must select a camera first."
	),

    fn ToggleCameraFocalKey = (

        if selection.count == 1 and superclassof selection[1] == camera then (
            c = selection[1]
			
			if not this.IsPhysicalCam c then (
				LayoutToolLog.logError "Not implemented yet, please use PhysicalCamera"
				return false
			)

            doCreate = false
			
			theCtrl = c.focal_length_mm.controller
			-- Not Physical physCamera parameter :
			-- c.fov.controller

            if theCtrl == undefined then (
                theCtrl = Bezier_Float()
				c.focal_length_mm.controller = theCtrl
                doCreate = true
            )
            else (
                keyIndex = getKeyIndex theCtrl currentTime
                if keyIndex == 0 then
                    doCreate = true
            )

            with undo label:"LayoutTool Toggle Focal Key" on (
                if doCreate then
                    addNewKey theCtrl currentTime
                else (
                    keyIndex = getKeyIndex theCtrl currentTime
                    deleteKey theCtrl keyIndex
                )
            )
        )
        UpdateFocalKeyState()
    ),

	fn OpenUI = (
		if m_rolloutFloater == undefined or m_rolloutFloater.open == false then (
			dialogPos = unsupplied
			if m_dialogPos != undefined then
				dialogPos = m_dialogPos

			m_rolloutFloater = newRolloutFloater ( "Layout Tool " + LAYOUT_TOOL_VERSION ) LAYOUT_TOOL_WIDTH LAYOUT_TOOL_HEIGHT
			addRollout layoutTool_Screenshot_Rollout m_rolloutFloater
			addRollout layoutTool_Previz_Rollout m_rolloutFloater
			addRollout layoutTool_Rollout m_rolloutFloater
			addRollout layoutTool_Shaker_Rollout m_rolloutFloater rolledUp:true

 			m_UI = layoutTool_Rollout
			m_shakerUI = layoutTool_Shaker_Rollout
			m_screenshotUI = layoutTool_Screenshot_Rollout
		)
		else (
			setFocus m_UI
		)
		UpdateUI()
	),

	fn OpenSaveAsUI dialogPos = (
		if m_rollSaveAsFloater == undefined or not m_rollSaveAsFloater.open then (
			local camList = layoutTool.GetAllCameras()
			if camList.count != 1 then (
				messageBox "You must have exactly 1 camera."
				return false 
			)
			m_uniqueCam = camList[1]
			m_rollSaveAsFloater = newRolloutFloater ( "Layout Tool " + " - Save As" ) LAYOUT_TOOL_WIDTH 100
			m_rollSaveAsFloater.pos = dialogPos
			addRollout layoutTool_SaveAs_Rollout  m_rollSaveAsFloater
			return true
		)
		return false
	),

	fn CloseSaveAsUI = (
		if m_rollSaveAsFloater != undefined and m_rollSaveAsFloater.open  then (
			closeRolloutFloater m_rollSaveAsFloater
		)
	),
	-- maxscript doc :]
	fn GetCamVFOV theCamera = (
		local r_aspect=(renderWidth as float)/renderHeight
		2.0*atan(tan(theCamera.fov/2.0)/r_aspect)
	),

	fn CreateDetectionBox = (
        cameraList = for o in objects where superclassof o == camera collect o
		if cameraList.count != 1 then (
			if selection.count != 1 or superclassof selection[1] != camera then (
				messageBox "Select a camera first"
				return false
			)
			camNode = selection[1]
		)
		else (
			camNode = cameraList[1]
		)

		b = getNodeByName "DetectionBox"
		if isValidNode b == false then (
			b = box name:"DetectionBox" renderable:false xray:true
			addModifier  b (FFD_2x2x2())
		)

		b.transform = camNode.transform
		b.height = camNode.farRange * m_detectionBoxScale
		b.width = camNode.farRange * (tan (camNode.fov/2.0)) * 2  * m_detectionBoxScale
		vFov = GetCamVFOV camNode
		b.length = camNode.farRange * (tan (vFov/2.0)) * 2  * m_detectionBoxScale

		in coordsys camNode (
			rotate b (eulerAngles 180 0 0)
		)

		--b.parent = camNode
		select b
	),

	fn DetectVisibleObjects = (
		b = getNodeByName "DetectionBox"

		if isValidNode b == false then
			messageBox "Create Detection Box first"
		else (
			searchField = for o in objects where superclassof o == GeometryClass and (matchPattern o.name pattern:"O_*" or matchPattern o.name pattern:"D_*") collect o
			visibleNodes = for o in searchField where intersects o b collect o
			nodes = for o in searchField where findItem visibleNodes o == 0 collect o
			select nodes
		)
	),

	fn CreateCameraGuideNode n = (
		if superclassof n == camera then (
			g = TAT_CameraGuides()
			initCameraGuidesWatcher()
			g.m_camera = n
			g.parent = n
			g.createGuides()
			g.updateGuidesShape()
			g.registerWhenCallback()
			g.isFrozen = true
			g.showFrozenInGray = false
			select g
			
			layer = GetCameraLayer()
			layer.addnode g
			redrawViews()
		)
		else (
			messageBox "Please select a camera first"
		)
	),

	fn CreateCameraGuides = (
		theNode = selection[1]
		CreateCameraGuideNode theNode
	),

	fn GetCameraGuide n = (
		if superclassof n == Camera then (
			for o in shapes where classof o == TAT_CameraGuides do (
				if o.m_camera == n then (
					return o
				)
			)
		)
		return undefined
	),

	fn SelectCameraGuides = (
		local result = #()
		local camNodes = for o in selection where superclassof o == Camera collect o

		if camNodes.count == 0 then
			camNodes = #( (viewport.GetCamera()) )

		for o in shapes where classof o == TAT_CameraGuides do (
			if findItem camNodes o.m_camera > 0 then (
				append result o
			)
		)

		select result
	),
	fn GetPivotHelper cam = (
		local helperName 	= cam.name + "_Pivot_CTRL" 
		local pivotHelper 	= getNodeByName helperName
		if not isValidNode pivotHelper then (
			pivotHelper = point name:helperName
		)

		local layer = this.GetCameraLayer()
		layer.addnode pivotHelper

		pivotHelper
	),

	fn SetupLinkHelper cam  pivotHelper = (
		local pivotC = cam.controller 

		if controls.IsAnimPivotControl pivotC then (
			pivotHelper.parent = cam.parent
			local prsC = copy ( controls.GetTransformController cam )
			pivotC.Translate_Pivot = true
			pivotC.Target = pivotHelper
			--controls.setTransformController  pivotHelper  prsC 
		)
	),

	fn AddPivotConstraint  = (
		camNodes = for o in selection where superclassof o == Camera collect o
		for c in camNodes do (
			local pivotHelper 
			if not controls.IsAnimPivotControl c then (
				c.controller = Pivot_Constraint()
				pivotHelper = this.GetPivotHelper c
				this.SetupLinkHelper c pivotHelper 
			)
		)
	),
	
	fn ToggleCameraGuides = (
		camNode = getActiveCamera()
		camGuides = for c in camNode.children where classof c == Tat_CameraGuides collect c
			
		action = #hide
		if camGuides.count > 0 then (
			visibilityStatus = makeUniqueArray (for o in camGuides collect o.isNodeHidden)
			if visibilityStatus.count == 1 then (
				if visibilityStatus[1] == true then
					action = #unhide
			)
			else
				action = #hide
		)
		
		if action == #hide then
			hide camGuides
		else
			unhide camGuides
	),
	
	fn ImportPreviz = (
		if this.CheckPrevizPath() then (
			local previzFiles = #()
			local dirs = getDirectories (this.PrevizPath + "\\" + "D_*")
			--sort dirs
			
			local maxSubfolder = @"Max\Previs"
			local previzFilePattern = maxSubfolder + "\\" + "*.previs_Cams.max"
			
			for d in dirs do (
				files = getFiles (d + previzFilePattern)
				--sort files
				previzFiles += files
			)
			sort previzFiles

	 		local displayFiles = for f in previzFiles collect (substituteString (getFilenameFile f) ".previs_cams" "")
			
			local dlg = ST_TatMultiListboxQuery()
			dlg.openDialog items:displayFiles title:"Choose Previz to import" caption:"Préviz file to import :" enableFilter:true 
			
			if dlg.returnValue != undefined then (
				for i in dlg.returnValue  do (
					local fname = previzFiles[i]
					
					if not doesfileExist fname then (
						layoutToolLog.LogError "Can't find previz file : %" val:fname
					) else (
						xrefs.addNewXRefFile fname
					)
				)
			)
		)
	),
	
	fn CleanPreviz = (
		if querybox "Delete ALL the xref scenes ?" then (
			xrefs.deleteAllXRefs()
			/*
			clean from layers if some xRefs was merged 
			*/
			local layers = #()
			local parentlayers = #()
			local others = #()
			local nodes = #()
	        for i = 0 to LayerManager.count - 1 do (
	            layer = LayerManager.getLayer i

	            if  matchPattern  layer.name  pattern:"*Previs*" then (
	            	if layer.getParent() == undefined then (
	            		append  parentlayers layer
		                local layerNodes = ( TatLayersManager.GetLayerNodes layer.name  includeSubLayers:true )
		                for n in layerNodes do (
		                	appendIfUnique nodes n
	                	)
	                ) else (
	                	append layers layer
                	)
	            ) else (
	            	append others layer
	            )
	        )
	        delete nodes

         	for otherlay in others do (
         		for pLayer in parentlayers where \
         			TatLayersManager.IsLayerInLayerHierarchy  otherlay pLayer do (
            		append layers otherlay
            		break
            	)
            )

	        for layer in layers do (
	        	LayerManager.deleteLayerByName layer.name
	        )
	        for layer in parentlayers do (
	        	LayerManager.deleteLayerByName layer.name
	        )
		)
	),

    fn RegisterCallbacks = (
        LayoutToolLog.LogUltraVerbose "Registering UpdateUI callbacks"
        callbacks.addScript #selectionSetChanged "layoutTool.UpdateUI()" id:#layoutTool_updateUI_SelectionSetChangedCallback
        callbacks.addScript #filePostSave "layoutTool.UpdateUI()" id:#layoutTool_updateUI_FilePostSaveCallback
        callbacks.addScript #filePostOpen "layoutTool.UpdateUI()" id:#layoutTool_updateUI_FilePostOpenCallback
        registerTimeCallback this.UpdateFocalKeyState
		registerTimeCallback this.UpdateShakerControls
    ),

    fn UnregisterCallbacks = (
        LayoutToolLog.LogUltraVerbose "Unregistering UpdateUI callbacks"
        callbacks.removeScripts #selectionSetChanged id:#layoutTool_updateUI_SelectionSetChangedCallback
        callbacks.removeScripts #filePostSave id:#layoutTool_updateUI_FilePostSaveCallback
        callbacks.removeScripts #filePostOpen id:#layoutTool_updateUI_FilePostOpenCallback
        unregisterTimeCallback this.UpdateFocalKeyState
		unregisterTimeCallback this.UpdateShakerControls
    )
)

layoutTool = ST_LayoutTool()