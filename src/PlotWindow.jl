using Images
using CuArrays
using CUDAdrv
using CUDAnative
let
  plane=1
global function PlotWindow(p_open::Ref{Bool})
                    
          CImGui.Begin("Plot", p_open, window_flags) || (CImGui.End(); return)
          img_width=CImGui.GetWindowWidth()-120.0f0
          img_height=CImGui.GetWindowHeight()-300.0f0
          io = CImGui.GetIO()
          pos = CImGui.GetCursorScreenPos()
          
          CImGui.Image(Ptr{Cvoid}(image_id), (img_width,img_height))
          
          if CImGui.IsItemHovered()
            CImGui.BeginTooltip()
            try
              region_x = Cint(div(length(x)*(io.MousePos.x - pos.x),img_width)+1)
              region_y = Cint(length(y)-div(length(y)*(io.MousePos.y - pos.y),img_height))
              CImGui.Text(@sprintf("[X,Y] = (%g, y = %g)m \n B = %.2f A/m", x[region_x],y[region_y], B[region_x,region_y,plane]))
            catch
            end
            CImGui.EndTooltip()
          end
          
          CImGui.SameLine()
          CImGui.Image(Ptr{Cvoid}(color_bar_id), ImVec2(bar_width, img_height))
          CImGui.SameLine()
          @cstatic X=Cfloat[-10.0, 0.20, 10.0] Y=Cfloat[-10, 0.20, 10.0] Z=Cfloat[0.00, 0.10, 0.40] Zplane=Cint(1) begin
              if @isdefined B
                if @c CImGui.VSliderInt("##v", ImVec2(bar_width,img_height), &Zplane, 1, length(z), @sprintf("%g m",z[Zplane]))
                        Bplane=B[:,:,Zplane]
                        Bcolormap = colorsigned(low,medium,high) ∘ scalesigned(minimum(Bplane),(minimum(Bplane)+maximum(Bplane))/2,maximum(Bplane));
                        image=Bcolormap.(Bplane);
                        image=reverse(image, dims=(2))
                        img_width,img_height=size(image)
                        image = unsafe_wrap(Array{UInt8,3}, convert(Ptr{UInt8}, pointer(image)), (Cint(3), Cint(img_width), Cint(img_height)))
                        ImGui_ImplOpenGL3_ReplaceStrechedImageTexture(image_id, image, img_width, img_height; format = GL_RGB)  
                        global plane=Zplane
                end
                Bplane=B[:,:,plane]
                maxval = maximum(Bplane)
                xypos=argmax(Bplane)
                xmax=x[xypos[1]]
                ymax=y[xypos[2]]
                CImGui.Text("Magnetic Field on the height of $(z[plane]) m above the ground level \n is equal $(round(maxval, digits=2)) A/m on [X,Y] = [$xmax, $ymax] m")
                CImGui.SameLine()
              end
              CImGui.Separator()
              CImGui.Text("Grid coordinate")
              CImGui.Separator()
              @c CImGui.InputFloat3("Xmin:dX:Xmax", X, "%g")
              @c CImGui.InputFloat3("Ymin:dY:Ymax", Y, "%g")
              @c CImGui.InputFloat3("Zmin:dZ:Zmax", Z, "%g")
                

              if CImGui.Button("Generate plot")&&!isempty(LinesCurrents)
                x=cu(collect(X[1]:X[2]:X[3]))
                y=cu(collect(Y[1]:Y[2]:Y[3]))
                z=cu(collect(Z[1]:Z[2]:Z[3]))
              
                lenX=length(x)
                lenY=length(y)
                lenZ=length(z)
                lengthOverall=lenX*lenY*lenZ

                segmentlength=length(LinesLengths)
                
                Bx=cu(fill(0.0f0,(2,lengthOverall)))
                By=cu(fill(0.0f0,(2,lengthOverall)))
                Bz=cu(fill(0.0f0,(2,lengthOverall)))
                B=CuArray{Float32}(undef,lenX,lenY,lenZ)
                for i=1:segmentlength
                  numberofsegments=numberofsegments=Int(div(LinesLengths[i],5))
                  if accuracylevel==1  
                    numberofsegments=32
                  elseif accuracylevel==3
                    numberofsegments=Int(div(LinesLengths[i],5))
                    if numberofsegments>640
                      numberofsegments=640
                    end
                  else
                    numberofsegments=div(numberofsegments+32,2)
                  end

                  Segment=cu(LinesSegments[i])
                  SegmentsCalculated=CuArray{Float32}(undef,(numberofsegments+1)*3)

                  Current=cu(LinesCurrents[i])
                  
                  beginMF3DCalc(x,y,z,Segment, Bx,By,Bz, Current,numberofsegments,SegmentsCalculated)

                end

                @cuda blocks=lenX*lenZ threads=lenY calcAbsoluteValue(Bx,By,Bz,B)

                global B=Array{Float32}(B)
                global x=Array{Float32}(x)
                global y=Array{Float32}(y)
                global z=Array{Float32}(z)


                Bcolorbar = colorsigned(high,medium,low) ∘ scalesigned(1,img_height/2,img_height);
                barImage=Bcolorbar.(collect(1:img_height));
                
                barImage=unsafe_wrap(Array{UInt8,3}, convert(Ptr{UInt8}, pointer(barImage)), (Cint(3), Cint(1), Cint(img_height)))                 
                ImGui_ImplOpenGL3_ReplaceStrechedImageTexture(color_bar_id, barImage, 1, img_height; format = GL_RGB)
            
                
                Bplane=B[:,:,Zplane]            
                Bcolormap = colorsigned(low,medium,high) ∘ scalesigned(minimum(Bplane),(minimum(Bplane)+maximum(Bplane))/2,maximum(Bplane))
                image=Bcolormap.(Bplane)
                image=reverse(image,dims=(2))
                img_width,img_height=size(image)
                image = unsafe_wrap(Array{UInt8,3}, convert(Ptr{UInt8}, pointer(image)), (Cint(3), Cint(img_width), Cint(img_height)))
                ImGui_ImplOpenGL3_ReplaceStrechedImageTexture(image_id, image, img_width, img_height; format = GL_RGB)
             
            end

            end
            CImGui.End()
          end
        end