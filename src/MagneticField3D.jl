using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui: ImVec2, ImVec4
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using Printf

include(joinpath(@__DIR__, "LineManagementWindow.jl"))
include(joinpath(@__DIR__, "PlotWindow.jl"))
include(joinpath(@__DIR__, "MainMenu.jl"))

@static if Sys.isapple()
    # OpenGL 3.2 + GLSL 150
    const glsl_version = 150
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
else
    # OpenGL 3.0 + GLSL 130
    const glsl_version = 130
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
    # GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
    # GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
end

# setup GLFW error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

# create window
window = GLFW.CreateWindow(1280, 720, "Demo")
@assert window != C_NULL
GLFW.MakeContextCurrent(window)
GLFW.SwapInterval(1)
# enable vsync

# setup Dear ImGui context
ctx = CImGui.CreateContext()

# setup Dear ImGui style
CImGui.StyleColorsDark()
# CImGui.StyleColorsClassic()
# CImGui.StyleColorsLight()


fonts_dir = joinpath(@__DIR__, "..", "fonts")
fonts = CImGui.GetIO().Fonts
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "OpenSans-Regular.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Cousine-Regular.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Karla-Regular.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyClean.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyTiny.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "DroidSans.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 18, C_NULL, CImGui.GetGlyphRangesCyrillic(fonts))

img_width=400;
img_height=400;

bar_width=40;
plane=1;
glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
image_id = ImGui_ImplOpenGL3_CreateImageTexture(img_width, img_height, format = GL_RGB);
color_bar_id = ImGui_ImplOpenGL3_CreateImageTexture(bar_width, img_height, format = GL_RGB);

LinesSegments=Array{Float32,1}[]
LinesCurrents=Array{Float32,1}[]
LinesLengths=Float32[]
# LinesPhaseOrder=String[]
# LinesRouteShift=Float64[]


PolesSegments=Array{Float32,1}[]
PolesCurrents=Array{Float32,1}[]
PolesLengths=Float32[]


const phaseShift=2*pi/3
# setup Platform/Renderer bindings
ImGui_ImplGlfw_InitForOpenGL(window, true)
ImGui_ImplOpenGL3_Init(glsl_version)

ShowMainMenu=true
clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]



while !GLFW.WindowShouldClose(window)
    global ShowMainMenu
    global LinesSegments,LinesCurrents,LinesLengths
    global PolesSegments, PolesCurrents, PolesLengths

    global  phaseShift
    global img_width, img_height, bar_width, image_id, color_bar_id, plane
    GLFW.PollEvents()
    # start the Dear ImGui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()

    ShowMainMenu && @c MainMenu(&ShowMainMenu)
    
    # rendering
    CImGui.Render()
    GLFW.MakeContextCurrent(window)
    display_w, display_h = GLFW.GetFramebufferSize(window)
    glViewport(0, 0, display_w, display_h)
    glClearColor(clear_color...)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

    GLFW.MakeContextCurrent(window)
    GLFW.SwapBuffers(window)
end

# cleanup
ImGui_ImplOpenGL3_Shutdown()
ImGui_ImplGlfw_Shutdown()
CImGui.DestroyContext(ctx)
GLFW.DestroyWindow(window)