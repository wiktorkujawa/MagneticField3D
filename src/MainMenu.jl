include(joinpath(@__DIR__, "LineManagementWindow.jl"))
include(joinpath(@__DIR__, "AboutAuthor.jl"))
let
  showLineManagementWindow = true
  showPlotWindow = true 
  showAbout = false 
  showAuthor = false
  global low=RGB{N0f8}(0.0,0.0,1.0)
  global medium=RGB{N0f8}(0.0,1.0,0.0)
  global high=RGB{N0f8}(1.0,0.0,0.0)
  global accuracylevel=1

    no_titlebar = false
    no_scrollbar = false
    no_menu = false
    no_move = false
    no_resize = false
    no_collapse = false
    no_close = false
    no_nav = false
    no_background = false
    no_bring_to_front = false

    show_app_metrics = false
    show_app_style_editor = false
    show_app_about = false


    

global function MainMenu(p_open::Ref{Bool})

  show_app_metrics && @c CImGui.ShowMetricsWindow(&show_app_metrics)
  if show_app_style_editor
      @c CImGui.Begin("Style Editor", &show_app_style_editor)
      CImGui.ShowStyleEditor()
      CImGui.End()
  end

  global window_flags = CImGui.ImGuiWindowFlags(0)
    no_titlebar       && (window_flags |= CImGui.ImGuiWindowFlags_NoTitleBar;)
    no_scrollbar      && (window_flags |= CImGui.ImGuiWindowFlags_NoScrollbar;)
    !no_menu          && (window_flags |= CImGui.ImGuiWindowFlags_MenuBar;)
    no_move           && (window_flags |= CImGui.ImGuiWindowFlags_NoMove;)
    no_resize         && (window_flags |= CImGui.ImGuiWindowFlags_NoResize;)
    no_collapse       && (window_flags |= CImGui.ImGuiWindowFlags_NoCollapse;)
    no_nav            && (window_flags |= CImGui.ImGuiWindowFlags_NoNav;)
    no_background     && (window_flags |= CImGui.ImGuiWindowFlags_NoBackground;)
    no_bring_to_front && (window_flags |= CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus;)
    no_close && (p_open = C_NULL;)
    
    
  showLineManagementWindow && @c LineManagementWindow(&showLineManagementWindow)
  showPlotWindow && @c PlotWindow(&showPlotWindow)
  showAbout && @c About(&showAbout)
  showAuthor && @c Author(&showAuthor)
  
  if CImGui.BeginMainMenuBar()
    if CImGui.BeginMenu("Menu")
      @c CImGui.MenuItem("Open Line Management Window", C_NULL, &showLineManagementWindow)
      @c CImGui.MenuItem("Show Main Result Window", C_NULL, &showPlotWindow)
        CImGui.EndMenu()
    end
    if CImGui.BeginMenu("Settings")
      if CImGui.BeginMenu("Window Settings")
        @c CImGui.MenuItem("Metrics", C_NULL, &show_app_metrics)
        @c CImGui.MenuItem("Style Editor", C_NULL, &show_app_style_editor)
        CImGui.EndMenu()
      end
      if CImGui.BeginMenu("Accuracy")
        @cstatic number=Cint(1) begin
        @c CImGui.SliderInt("Accuracy level", &number, 1, 3, "Accuracy Level: %d")
        accuracylevel=number
      end
      CImGui.EndMenu()
      end
      if CImGui.BeginMenu("Colors")
        @cstatic a=Cfloat[0.0,0.0,1.0] b=Cfloat[0.0,1.0,0.0] c=Cfloat[1.0,0.0,0.0] begin
        CImGui.ColorEdit3("Low", a); CImGui.SameLine();
        CImGui.ColorEdit3("Medium", b);CImGui.SameLine();
        CImGui.ColorEdit3("High", c)

        low=RGB{N0f8}(a[1],a[2],a[3])
        medium=RGB{N0f8}(b[1],b[2],b[3])
        high=RGB{N0f8}(c[1],c[2],c[3])

        Bcolorbar = colorsigned(high,medium,low) ∘ scalesigned(1,img_height/2,img_height);
        imageBar=Bcolorbar.(collect(1:img_height));               
        barImage=unsafe_wrap(Array{UInt8,3}, convert(Ptr{UInt8}, pointer(imageBar)), (Cint(3), Cint(1), Cint(img_height)))
        ImGui_ImplOpenGL3_ReplaceStrechedImageTexture(color_bar_id, barImage, 1, img_height; format = GL_RGB)

        try
          Bplane=B[:,:,plane]          
          Bcolormap = colorsigned(low,medium,high) ∘ scalesigned(minimum(Bplane),(minimum(Bplane)+maximum(Bplane))/2,maximum(Bplane));
          image=Bcolormap.(Bplane);
          image=reverse(image,dims=(1))
          img_width,img_height=size(image)
          image = unsafe_wrap(Array{UInt8,3}, convert(Ptr{UInt8}, pointer(image)), (Cint(3), Cint(img_width), Cint(img_height)))
          ImGui_ImplOpenGL3_ReplaceStrechedImageTexture(image_id, image, img_width, img_height; format = GL_RGB)
          
        catch 
        end

        end
        CImGui.EndMenu()
    end
        CImGui.EndMenu()
    end
    if CImGui.BeginMenu("About")
        @c CImGui.MenuItem("About", C_NULL, &showAbout)
        @c CImGui.MenuItem("Author", C_NULL, &showAuthor)
        CImGui.EndMenu()
    end
    CImGui.EndMainMenuBar()
end
end
end