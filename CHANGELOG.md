## VERSIONS

### 1.3.2
- Fix : TatViewportOps instead of TatCameraGuides

### 1.3.1
- Fix : Layout Browse with correct paths 
- Fix : Layout Tool Interface changes
- Fix : ImportSound log error
- Fix : Save next, Save+
- Fix : ExportEstab, sceenshots and preview saved in correct paths
- Add : SpaceSwitch rigRail rigPivot rigFollow
- Add : ExportEstab : merge fx_ciel // now disabled in prod
- Add : LayoutTool, ResetViewportLayout set preset_35mm

### 1.3.0
- Change : move button in ui
- Remove : rollout Other, rollout optim

### 1.2.9
- Remove : NitrousViewport is now set by TatPreview_ for screenShots and previews
- Add : CameraGuide option display in preview and ScreenShots

### 1.2.8
- Add : TatSyncAddModule to import py module in mxs
- Add : folder "Previs_JPG" is now sync
- Fix : export establishing updated

### 1.2.7
- Add : replace Tatpreview_.takeScreenshotDIB  by Tatpreview_.takeScreenshot and move config in it
- Fix : Dof always enabled, desabled by user in camera properties; remove dof checkbox
- Fix : Dof always enabled, desabled by user in camera properties; remove dof checkbox

### 1.2.6
- Add : TatCameraGuides
- Fix : ScreenShots+Dof, saveNext+savePlus, focalKey

### 1.2.5
- Fix : Replace TatPreview.process with TatPreview.makePreview
- Add : import macro ResetViewportLayout from TatMxsLib, rename to LayoutResetViewport
- Add : Possibility to save as version A, B, C, ...
- Add : Import previz, multi selection allowed and sort by alphabetic order
- Add : Option Light & DOF for screenShot / Previews 

### 1.2.4
- Add : replace pistacheLibPath with Pistache.DatabasePath
- Add : move PREVIZ_PATH_ROOT to structure. /!\ Must be set in Scripts.ms

### 1.2.3
- Fix : refresh focal_lenght in UI from max 
- Fix : Add Convert Shaker 
- Fix : refacto code and correct minnor bugs on update ui
- Fix : ScreenShot Show Dof and Lights
- wip : Add input [version A] to saveAsEstab... 

### 1.2.2
- Fix : create CameraFromView debug crash 
- Add : CameraFromView ask if create new cam in CameraMode
- Change : Instance of LayoutTool is now created in layoutTool_lib.ms after the ST_LayoutTool declaration
- Add : save as Establishing is moved to new rollout => layoutTool_SaveAsEstab_Rollout 
- Fix : (Wip) refresh focal_lenght in UI from max 

### 1.2.1
- Fix : Argo conformation
- Fix : Moving the only hardcoded path into main file
- Fix : Updating ImportPreviz to allow importing multiples previz files

### 1.2.0
- Add : move globals to structure

### 1.1.9
- Add : functions to manipulate tatcameraguides with kiwi

### 1.1.8
- Fixed : detection of geometry not visible to camera on the whole animation
range

### 1.1.7
- Add : macro for take movie + move macros to tat_Layout

### 1.1.6
- Fix : TakeMovie regex update for proposition nomenclature (ex : ".v000.B")

### 1.1.5
- Fix : TakeMovie now exports movie with the ".layout." step name 

### 1.1.4
- Fix : ExportScene() was exporting all cameras present in scene (bug due to TAT_CameraGuides present in scene)

### 1.1.3
- Fix : Sound import fix

### 1.1.2
- Fix : Accepting camera name format : s01p0001\_fr01-10
- Fix : Setting sound folder

### 1.1.1
- Fix : Call to TatPreview.takeScreenshotDIB instead of TatPreview.TakeScreenshot
- Fix : Intermediate helpers in rigs created with the "link constraint" option now have the _Link suffix instead of _Root

### 1.1.0
- Add : Import en XrefScene des fichiers _previz_cams.max, et suppression des XrefScene
- Fix : CreateConformedCamera : les caméras ne subissent plus de Freeze Transform

### 1.0.1
- Fix : preview name is based on camera name and not filename
- Fix : preview from a "estab" file will always produce a v000 file, preview from a "shot" file will reproduce the max file version
- Fix : Normalize\_Spl modifier name update (max2020 : Normalize\_Spline2)
- Fix : weight display in UpdateShakerControls

### 1.0.0
- Fix : TakeScreenshot now call TatPreview methods and thus produces DOF !

### 0.8.5
- Fix : Keyframe gathering on controller\_list

### 0.8.4
- Add : cameraguides visibility toggle button
- Fix : cameraMaster helper is now frozen and hidden
- Fix : shake cam weight fixed
- Fix : physical cam default value : lens breathing = 0
- Fix : Focal keys applied on physical_camera.focal_length_mm instead of fov 
- Fix : UI : focal length buttons replaced by a spinner
- Fix : TakeScreenshots : export folder query at each batch beginning
- Fix : "Browse..." functions fixed

### 0.8.3
- Fix : UI default vertical size
- Fix : exception was raised on targetted cameras
- Fix : we track focal_length_mm keys and not fov keys in TakeScreenshot()
- Fix : in case of targetted_cam we also track the target transform keys

### 0.8.2
- Add : Add Select Targets
- Add : Add MirrorXYZ

### 0.8.1
- Fix : Call to Controls.FreezeScaleNodes in CreateConformedCameraFromView
- Fix : Rail/Pivot/Follow rigs are now parented to cameraMaster node
- Fix : Factorizing cameraMaster node creation
- Add : macro mc_LayoutToolCreateCameraFromView

### 0.8.0
- Add : add Pivot_Constraint button
- Fix : last screenshot location is always stored to avoid having to pick a folder at each capture. m_lastScreenshotName is reset on #filePostOpen callback
- Fix : UI layout is now splitted into several rollouts
- Fix : Physical_Camera is now the default camera, all functions have been updated to handle the new camera class
- Fix : Guides are now frozen by default at creation
- Add : UI btn to select guides

### 0.7.0
- PIL Conformation
- New Master helper parent of all cameras

### 0.6.2
- Fix : Pivot/Follow helpers are now aligned in rotation on target nodes

### 0.6.1
- Fix : name of the controller is displayed
- Fix : changing controller index changes active layer consequently

### 0.6.0
- Added : UI controller index spinner, UI can now work with multiple noise of the same type
- Added more tests to avoid undefined controller exceptions
- Some code factorization

### 0.5.48
- Add a lot of test to take into account every possibility concerning camera controllers (double position list, etc).

### 0.5.47
- Fix : IsValidBasename : allows a new pattern : sXXpXXXX_whatever (in a second try, after the full details original regex)

### 0.5.46
- Fix : prevent rotation shaker creation and update on Target Camera because it has no rotation parameter.

### 0.5.45
- Add create conform object with CA_SplineOnSurface custom attribute

### 0.5.44
- Modify tool to place noise controllers on the camera.
- Add : button to remove noise controllers.
- Add callback on frame change to update noise control fields.

### 0.5.43
- Add : noise rotation option.
- Reorganize noise functions to allow rotation option.

### 0.5.42
- Modify the way noise shaker is working. it now use two controllers : position list and noise position to control the position of the noise point and to manage weight of the effect.

### 0.5.41

- Add : function to add shaker to selected camera.
- Add : interface to modify parameters of the noise controller use to add shaker to cameras.
- Update rail, pivot and follow functions to put created points into Cameras layer.
- Update create camera function to put new camera in the right layer (and creates layer if it doesn't exist).

### 0.5.4

- Fix : screenshot suffix goes to Z instead of Q

### 0.5.3

- Fix : internal camera list was not sorted out accordingly to UI camera list

### 0.5.2

- Fix : standard display settings before screenshots
- Fix : several helpers display settings fixed
- Fix : auto rail : follow is enabled

### 0.5.1

- Minor bugfixes before release production version

### 0.5.0

- Del : ProSequencer references
- Add : quick browse button
- Add : toggle button : state focal key
- Add : Quick rail buttons, quick follow, quick pivot
- Add : Optimization workflow (selecting geometry outside of the detection box)
- Fix : TakeScreenshot ratio

### 0.4.9

- Case insensitive regex

### 0.4.8

- After an export, the viewport layout was locked on #layout_1

### 0.4.7

- updated regex : in the establishing scenes, the camera can be named sXXpYYYY_frZZ

### 0.4.6

- TakeScreenshot captures every keyframe of a camera.

### 0.4.5

- IsValidBasename : Deuxième régex pour la prise en compte de screenshots (par exemple pour le placement d'un objet dans une séquence, en dehors de toute notion de plan)
- Infos de preview affichées sur les captures

### 0.4.4

- Tous les screenshots sont placés au même endroit maintenant.

### 0.4.3

- Reverted "pro sequencer" button
- Reverted "rename cam" button
- Import Sound, if the scene contains only 1 camera, uses the scene basename !

### 0.4.2

- Reverted "import sound" button

### 0.4.1

- Amélioration du bouton lock/unlock
- Simplification du workflow de snapping

### 0.3.0

- Séparation du métier dans une structure
- Nettoyage des éléments inutilisés de l'UI
- Batch processing de l'export establishing

### 0.2.3

- Version récupérée de la section additional scripts
