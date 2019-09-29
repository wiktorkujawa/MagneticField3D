global function SingleLine(p_open::Ref{Bool})
  CImGui.Button("Add single line") && CImGui.OpenPopup("Add single line")
        if CImGui.BeginPopupModal("Add single line", C_NULL, CImGui.ImGuiWindowFlags_MenuBar)
          @cstatic startLine=Cfloat[0.10, 0.20, 0.30] startmidLine=Cfloat[0.10, 0.20, 0.30]  endLine=Cfloat[0.10, 0.20, 0.30] I=Cfloat(640.0) Angle=Cfloat(0.0) phaseAngle=Cfloat(0.0) lineLength=Cfloat(500.0)  beginOrMid=Cint(1) inputMethod=Cint(0) zstart=Cfloat(0.0) zend=Cfloat(0.0) begin
            CImGui.Separator()
            CImGui.Text("Electric details")
            CImGui.Separator()
            @c CImGui.InputFloat("Input current value", &I, 1.0, 1.0, "%.2f")
            @c CImGui.SliderAngle("Phase shift Angle",&phaseAngle, 0.0, 360.0)
            CImGui.Separator()
            CImGui.Text("Input coordinates of cable")
            CImGui.Separator()
            @c CImGui.RadioButton("Cartesian Coordinates", &inputMethod, 0); CImGui.SameLine()
            @c CImGui.RadioButton("Polar Coordinates", &inputMethod, 1);
            if inputMethod==0
              @c CImGui.InputFloat3("Input start of line(X,Y,Z)", startLine)
              @c CImGui.InputFloat3("Input end of line(X,Y,Z)", endLine)
            else
              @c CImGui.InputFloat("Input line length", &lineLength, 1.0, 1.0, "%.2f")
              @c CImGui.SliderAngle("Crossing Angle",&Angle, 0.0, 360.0)
              @c CImGui.RadioButton("By the start of line", &beginOrMid, 0); CImGui.SameLine()
              @c CImGui.RadioButton("By middle of line", &beginOrMid, 1);
              @c CImGui.InputFloat2("Input start/mid of line(X,Y)", startmidLine)
              @c CImGui.InputFloat("Height at the start", &zstart, 1.0, 1.0, "%.2f")
              @c CImGui.InputFloat("Height at the end", &zend, 1.0, 1.0, "%.2f")
            end

            CImGui.Button("Add line") && (if inputMethod==0

            push!(LinesSegments,[startLine;endLine])
            push!(LinesCurrents,[I*cos(phaseAngle)/2pi,I*sin(phaseAngle)/2pi])
            push!(LinesLengths,sqrt(sum((startLine-endLine).^2)))

            else
              startLine,endLine=cartesianToPolar2D(startmidLine,lineLength,Angle,beginOrMid,zstart,zend)

              push!(LinesSegments,[startLine;endLine])
              push!(LinesCurrents,[I*cos(phaseAngle)/2pi,I*sin(phaseAngle)/2pi])
              push!(LinesLengths,sqrt(lineLength*lineLength+(zstart-zend)^2))
            end)
          end
            CImGui.Button("Close") && CImGui.CloseCurrentPopup()
            CImGui.EndPopup()
        end
      end