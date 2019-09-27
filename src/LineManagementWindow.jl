include(joinpath(@__DIR__, "SingleLine.jl"))
include(joinpath(@__DIR__, "ThreePhaseRoute.jl"))
# include(joinpath(@__DIR__, "CablePoles.jl"))
using MF3DSupportingPackage


showLines=true
global function LineManagementWindow(p_open::Ref{Bool})
  CImGui.Begin("Line management", p_open, window_flags) || (CImGui.End(); return)
  global showLines
  showLines && @c SingleLine(&showLines)
  showLines && @c ThreePhaseRoute(&showLines)
  # showLines && @c CablePoles(&showLines)
  CImGui.Separator()
  CImGui.Text("Line list:")
  CImGui.Separator()
  i=1;
  while i<=length(LinesLengths)
    CImGui.PushID(i-1)
    CImGui.PushStyleColor(CImGui.ImGuiCol_Button, CImGui.HSV(0.0, 100.0, 100.0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonHovered, CImGui.HSV(0.1, 0.7, 0.7))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonActive, CImGui.HSV(0.1, 0.8, 0.8))

    CImGui.Text(@sprintf("Start:[ %g, %g, %g] m End:[%g , %g, %g] m \nCurrent Value: %g A, PhaseShift: %g degrees ",LinesSegments[i][1],LinesSegments[i][2],LinesSegments[i][3],LinesSegments[i][4],LinesSegments[i][5],LinesSegments[i][6],sqrt(sum(LinesCurrents[i].^2))*4pi,rad2deg(atan(LinesCurrents[i][2],LinesCurrents[i][1])))); CImGui.SameLine()

    CImGui.Button("X") && (deleteat!(LinesSegments,i); deleteat!(LinesLengths,i); deleteat!(LinesCurrents,i))
    CImGui.PopStyleColor(3)
    CImGui.PopID()
    i+=1
  end
    CImGui.End()
  end