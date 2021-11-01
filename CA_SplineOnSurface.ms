ConformSpliteAttribute = attributes CA_ConformSpliteAttribute attribID:#(0x41961907, 0x19147603)
(
    local roll

    parameters main rollout:mainRoll
    (
        LinkedSpline type:#node
        ProjectedSplineName type:#string
    )

    rollout mainRoll "SplineMod"
    (
        label  lb_pickSpline "Pick Spline :" 	width:150  align:#right  offset:[5,0]
        pickButton  pk_pickSpline 			"..."       	width:150  align:#right  offset:[0,0]

        spinner  sp_SegLength "Seg Length"      width:80 align:#center  offset:[0,0]   range:[1,2000,100]


        Button btn_Process "Process" width:150 offset:[0,5]

        label lb_projectedSplineTitle "ProjectedSpline : " width:150  align:#right  offset:[5,0]
        label lb_projectedSpline "" width:150  align:#right  offset:[5,0]


        fn GetProjectedSpline = (
            res = undefined
            if (this.ProjectedSplineName != undefined) do (
                res = GetNodeByName this.ProjectedSplineName
            )
            return res
        )

        fn UpdateLabels = (
            if this.LinkedSpline != undefined do (
                pk_pickSpline.text = this.LinkedSpline.name
            )
            if (this.ProjectedSplineName != undefined) do (
                n = GetProjectedSpline()
                if n != undefined and n.modifiers[#normalize_spl] != undefined then (
                    lb_projectedSpline.text = this.ProjectedSplineName
                    sp_SegLength.value = n.modifiers[#normalize_spl].Length
                ) else (
                    lb_projectedSpline.text = ""
                )
            )
        )

        on sp_SegLength changed val do (
            n = GetProjectedSpline()
            if n != undefined and n.modifiers[#normalize_spl] != undefined do (
                n.modifiers[#normalize_spl].Length = val
            )
        )

        on pk_pickSpline picked obj do (
            this.LinkedSpline = obj
            this.ProjectedSplineName = ""
            UpdateLabels()
        )

        on btn_Process pressed do (
            if this.LinkedSpline != undefined then (
                local ProjectedSpline = GetProjectedSpline()
                if ProjectedSpline == undefined then (
                    ProjectedSpline= reference this.LinkedSpline
                    this.ProjectedSplineName = ProjectedSpline.name
                    ProjectedSpline.vertexTicks = on
                ) else (
                    for i=1 to ProjectedSpline.modifiers.count do (
                        deleteModifier ProjectedSpline 1
                    )
                )
                if ProjectedSpline != undefined do (
                    local tmp = ( refs.dependents this )[1]
                    local conformNode  = ( refs.dependentNodes tmp )[1]
                    bindSpaceWarp ProjectedSpline  conformNode
                    normSpline = normalize_spline2()
                    addmodifier ProjectedSpline normSpline
                    normSpline.Length = 100
                    ProjectedSpline[3].controller = this.LinkedSpline[3].controller
                )
                UpdateLabels()
            ) else (
                messageBox "Please first pick the spline"
            )
        )

        on mainRoll open do (UpdateLabels())
    )
)
