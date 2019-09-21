global function ThreePhaseRoute(p_open::Ref{Bool})
  CImGui.Button("Add three-phase route") && CImGui.OpenPopup("Add three-phase route")
  phaseShift=2*pi/3
        if CImGui.BeginPopupModal("Add three-phase route", C_NULL, CImGui.ImGuiWindowFlags_MenuBar)
          @cstatic startLineLeft=Cfloat[0.10, 0.20, 0.30] startLineCenter=Cfloat[0.10, 0.20, 0.30] startLineRight=Cfloat[0.10, 0.20, 0.30] endLineLeft=Cfloat[0.10, 0.20, 0.30] endLineCenter=Cfloat[0.10, 0.20, 0.30] endLineRight=Cfloat[0.10, 0.20, 0.30]  gapL2=Cfloat[0.10, 0.20, 0.30] gapL3=Cfloat[0.10, 0.20, 0.30] formationType=Cint(1) I=Cfloat(640.0) Angle=Cfloat(0.0) phaseAngle=Cfloat(0.0) lineLength=Cfloat(500.0)  beginOrMid=Cint(1) inputMethod=Cint(1) zstart=Cfloat(0.0) zend=Cfloat(0.0) gapSecond=Cfloat[0.0,0.0,0.0] gapThird=Cfloat[0.0,0.0,0.0] phaseOrder=Cint(0) phaseMultiplier=Cint[0,-1,1] startmidLine=Cfloat[0.10, 0.20, 0.30] gapFlat=Cfloat(4.0) gapTrefoil=Cfloat(4.0) begin
            CImGui.Separator()
            CImGui.Text("Electric details")
            CImGui.Separator()
            @c CImGui.InputFloat("Input current value", &I, 1.0, 1.0)
            @c CImGui.SliderAngle("Phase shift Angle",&phaseAngle, 0.0, 360.0)

            CImGui.Separator()
            CImGui.Text("Input coordinates of route")
            CImGui.Separator()
            @c CImGui.RadioButton("Cartesian Coordinates", &inputMethod, 0); CImGui.SameLine()
            @c CImGui.RadioButton("Polar Coordinates", &inputMethod, 1);

            if inputMethod==0
              CImGui.Separator()
              CImGui.Text("Coordinates of first Line")
              CImGui.Separator()
              @c CImGui.InputFloat3("Input start of line phase L1(X,Y,Z)", startLineLeft)
              @c CImGui.InputFloat3("Input end of line phase L1(X,Y,Z)", endLineLeft)
              CImGui.Separator()
              CImGui.Text("Gaps between phases")
              CImGui.Separator()
              @c CImGui.InputFloat3("Input gap of phase L2(X,Y,Z) to phase L1(XYZ)", gapL2)
              @c CImGui.InputFloat3("Input gap of phase L3(X,Y,Z) to phase L1(XYZ)", gapL3)
              if CImGui.Button("Add route")

                bufLength=sqrt(sum((startLineLeft-endLineLeft).^2))

                push!(LinesSegments,[startLineLeft;endLineLeft],[startLineLeft+gapL2;endLineLeft+gapL2],[startLineLeft+gapL3;endLineLeft+gapL3])
                push!(LinesCurrents,[I*cos(phaseMultiplier[1]*phaseShift+phaseAngle)/4pi,I*sin(phaseMultiplier[1]*phaseShift+phaseAngle)/4pi],[I*cos(phaseMultiplier[2]*phaseShift+phaseAngle)/4pi,I*sin(phaseMultiplier[2]*phaseShift+phaseAngle)/4pi],[I*cos(phaseMultiplier[3]*phaseShift+phaseAngle)/4pi,I*sin(phaseMultiplier[3]*phaseShift+phaseAngle)/4pi])
                push!(LinesLengths,bufLength,bufLength,bufLength)

              end
            else
              CImGui.Separator()
              CImGui.Text("Phase Order")
              CImGui.Separator()
              @c CImGui.RadioButton("ABC", &phaseOrder, 0); CImGui.SameLine()
              @c CImGui.RadioButton("ACB", &phaseOrder, 1); CImGui.SameLine()
              @c CImGui.RadioButton("BAC", &phaseOrder, 2);
              @c CImGui.RadioButton("BCA", &phaseOrder, 3); CImGui.SameLine()
              @c CImGui.RadioButton("CAB", &phaseOrder, 4); CImGui.SameLine()
              @c CImGui.RadioButton("CBA", &phaseOrder, 5);

              if phaseOrder==0
                phaseMultiplier=0,-1,1
              elseif phaseOrder==1
                phaseMultiplier=0,1,-1
              elseif phaseOrder==2
                phaseMultiplier=-1,0,1
              elseif phaseOrder==3
                phaseMultiplier=-1,1,0
              elseif phaseOrder==4
                phaseMultiplier=1,0,-1
              else
                phaseMultiplier=1,-1,0
              end

              CImGui.Separator()
              CImGui.Text("Position data")
              CImGui.Separator()
              @c CImGui.InputFloat("Input line length", &lineLength, 1.0, 1.0, "%.2f")
              @c CImGui.SliderAngle("Crossing Angle",&Angle, 0.0, 360.0)
              CImGui.Separator()
              CImGui.Text("Waypoint")
              CImGui.Separator()
              @c CImGui.RadioButton("By the start of line", &beginOrMid, 0); CImGui.SameLine()
              @c CImGui.RadioButton("By middle of line", &beginOrMid, 1);

              @c CImGui.InputFloat2("Input start/mid coordinates of center phase line(X,Y)", startmidLine)
              @c CImGui.InputFloat("Input start/mid height of center phase line", &zstart, 1.0, 1.0, "%.2f")

              CImGui.Separator()
              CImGui.Text("Arrangement method")
              CImGui.Separator()
              @c CImGui.RadioButton("Various gaps", &formationType, 0); CImGui.SameLine()
              @c CImGui.RadioButton("Flat formation", &formationType, 1); CImGui.SameLine()
              @c CImGui.RadioButton("Trefoil formation", &formationType, 2);


              if formationType==0
                @c CImGui.InputFloat2("Input vertical and horizontal gap towards second line", gapSecond); CImGui.SameLine()
                @c CImGui.InputFloat2("Input vertical and horizontal gap towards third line", gapThird)

              elseif formationType==1
                @c CImGui.InputFloat("Input gap towards left line coordinate", &gapFlat, 1.0, 1.0, "%.2f")
                gapSecond=Float32[-gapFlat*cos(Angle),gapFlat*sin(Angle),0.0]
                gapThird=Float32[gapFlat*cos(Angle),-gapFlat*sin(Angle),0.0]

              else
                @c CImGui.InputFloat("Input gap towards left line coordinate", &gapTrefoil, 1.0, 1.0, "%.2f")
                gapSecond=Float32[-gapTrefoil*0.5*cos(Angle),gapTrefoil*0.5*sin(Angle),-gapTrefoil*0.86602540378]
                gapThird=Float32[gapTrefoil*0.5*cos(Angle),-gapTrefoil*0.5*sin(Angle),-gapTrefoil*0.86602540378]
              end

              if CImGui.Button("Add route")

                startLineCenter,endLineCenter=cartesianToPolar2D(startmidLine,lineLength,Angle,beginOrMid,zstart)
                startLineLeft,endLineLeft=cartesianToPolar2D(startmidLine+gapSecond,lineLength,Angle,beginOrMid,zstart)
                startLineRight,endLineRight=cartesianToPolar2D(startmidLine+gapThird,lineLength,Angle,beginOrMid,zstart)


                push!(LinesSegments,[startLineLeft;endLineLeft],[startLineCenter;endLineCenter],[startLineRight;endLineRight])
                push!(LinesCurrents,[I*cos(phaseMultiplier[1]*phaseShift+phaseAngle)/4pi,I*sin(phaseMultiplier[1]*phaseShift+phaseAngle)/4pi],[I*cos(phaseMultiplier[2]*phaseShift+phaseAngle)/4pi,I*sin(phaseMultiplier[2]*phaseShift+phaseAngle)/4pi],[I*cos(phaseMultiplier[3]*phaseShift+phaseAngle)/4pi,I*sin(phaseMultiplier[3]*phaseShift+phaseAngle)/4pi])
                push!(LinesLengths,lineLength,lineLength,lineLength)

              
              end
            end

          end
            CImGui.Button("Close") && CImGui.CloseCurrentPopup()
            CImGui.EndPopup()
        end
      end
