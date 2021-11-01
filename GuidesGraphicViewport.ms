global GuidesCallback
global opt = #cross

global TatGuidesDisplayViewportCallback

try ( UnregisterRedrawViewsCallback TatGuidesDisplayViewportCallback ) catch ()

struct ST_TatGuides 
(
	_displayType = #ruleOfThird,
	_displayColor = red,
	
	_goldenRatio = 1.61803,
	
	fn DisplayGuide type onOff:true guideColor:red = (
		_displayType = type
		_displayColor = guideColor

		if onOff then (
			RegisterRedrawViewsCallback TatGuidesDisplayViewportCallback
		)
		else (
			UnregisterRedrawViewsCallback TatGuidesDisplayViewportCallback
		)
		redrawviews()	
	),
	
	fn DisplayRuleOfThird w h refH = (
		ph = refH + h/3
		p1 = [0, ph, 0] 
		p2 = [w, ph, 0]
		gw.hPolyline #(p1, p2) false 
		
		ph = refH + 2*h/3
		p1 = [0, ph, 0] 
		p2 = [w, ph, 0]
		gw.hPolyline #(p1, p2) false
		
		pw = w / 3
		p1 = [pw, refH, 0] 
		p2 = [pw, refH + h, 0]
		gw.hPolyline #(p1, p2) false 
		
		pw = 2*w/3
		p1 = [pw, refH, 0] 
		p2 = [pw, refH + h, 0]
		gw.hPolyline #(p1, p2) false
	),
	
	fn DisplayCross w h refH = (
		p1 = [0, refH, 0] 
		p2 = [w, refH + h, 0]
		gw.hPolyline #(p1, p2) false
		
		p1 = [0, refH + h, 0] 
		p2 = [w, refH, 0]
		gw.hPolyline #(p1, p2) false
	),
	
	fn DisplayCenterCross w h refH = (
		pw = w / 2
		p1 = [pw, refH, 0] 
		p2 = [pw, refH + h, 0]
		gw.hPolyline #(p1, p2) false
		
		ph = refh + h / 2
		p1 = [0, ph, 0] 
		p2 = [w, ph, 0]
		gw.hPolyline #(p1, p2) false
	),
	
	fn DisplayGoldenRatio w h refH = (
		ph = refH + h / _goldenRatio
		p1 = [0, ph , 0] 
		p2 = [w, ph, 0]
		gw.hPolyline #(p1, p2) false 
		
		ph = refH + h - h / _goldenRatio
		p1 = [0, ph, 0] 
		p2 = [w, ph, 0]
		gw.hPolyline #(p1, p2) false
		
		pw = w / _goldenRatio
		p1 = [pw, refH, 0] 
		p2 = [pw, refH + h, 0]
		gw.hPolyline #(p1, p2) false 
		
		pw = w - w / _goldenRatio
		p1 = [pw, refH, 0] 
		p2 = [pw, refH + h, 0]
		gw.hPolyline #(p1, p2) false
	),
	
	fn DisplayGoldenTriangle w h refH = (
		p1 = [0, refH, 0] 
		p2 = [w, refH + h, 0]
		gw.hPolyline #(p1, p2) false
		
		p1 = [0, refH + h, 0] 
		p2 = [w - w / _goldenRatio, refH + h - h / _goldenRatio, 0]
		gw.hPolyline #(p1, p2) false
		
		p1 = [w, refH, 0] 
		p2 = [w / _goldenRatio, refH + h / _goldenRatio, 0]
		gw.hPolyline #(p1, p2) false
	),
	
	fn DisplayGoldenSpiral w h refH = (
-- 		pA = [0, refH, 0]
-- 		pB = [w / _goldenRatio, refH + h, 0]
-- 		pC = [w, refH + h - h / _goldenRatio, 0]
-- 		gw.hPolyline #(pA, pB, pC) false
	)
)

fn TatGuidesDisplayViewportCallback = (
	gw.setTransform (matrix3 1)
	gw.setColor #line TatGuides._displayColor
	
	local w = gw.getWinSizeX()
	local h = (gw.getWinSizeX()) * renderHeight / (renderWidth as float) 
	local refH = (gw.getWinSizeY() - h) / 2
	
	local opt = TatGuides._displayType
		
	if opt == #ruleOfThird then (
		TatGuides.DisplayRuleOfThird w h refH
	)
	else if opt == #cross then (
		TatGuides.DisplayCross w h refH
	)
	else if opt == #centerCross then (
		TatGuides.DisplayCenterCross w h refH
	)
	else if opt == #goldenRatio then (
		TatGuides.DisplayGoldenRatio w h refH
	)
	else if opt == #goldenTriangle then (
		TatGuides.DisplayGoldenTriangle w h refH
	)
	else if opt == #goldenSpiral then (
		TatGuides.DisplayGoldenSpiral w h refH
	)
	gw.updatescreen()
)

TatGuides= ST_TatGuides()

TatGuides.DisplayGuide #goldenRatio
