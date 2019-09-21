module MF3DSupportingPackage
using CUDAnative
using CuArrays
export cartesianToPolar2D
export divideLine
export biotGPU
export calcValue
export bench_biot
function cartesianToPolar2D(startmid,linelength,angle,midorstart,zstart=0.0,zend=zstart)
  bufor=Float32[sin(angle),cos(angle),0.0]
  endline=startmid+bufor*linelength/(midorstart+1)
  startline=startmid-bufor*midorstart*linelength/2
  startline[3]=zstart
  endline[3]=zend
  return startline,endline
end

function divideLine(Segment,numberofsegments,SegmentsCalculated)
  segmentNumber = (blockIdx().x-1) * blockDim().x + threadIdx().x

  coordinate=blockIdx().x
  
  SegmentsCalculated[segmentNumber]=Segment[coordinate]+(segmentNumber-1)%numberofsegments*(Segment[coordinate+3]-Segment[coordinate])/(numberofsegments-1)
  return nothing
end

function biotGPU(x,y,z,Segment, Bx,By,Bz, Current)
  offset= blockIdx().x + (blockIdx().y-1)*gridDim().x + (blockIdx().z-1)*gridDim().x*gridDim().y
  XelementIndex=threadIdx().x
  YelementIndex=XelementIndex+blockDim().x+1
  ZelementIndex=YelementIndex+blockDim().x+1
  δx=x[blockIdx().x]-Segment[XelementIndex]
  δy=y[blockIdx().y]-Segment[YelementIndex]
  Sx=Segment[XelementIndex+1]-Segment[XelementIndex]; Sy=Segment[YelementIndex+1]-Segment[YelementIndex];
  Sy<0.1 ? Sy+=1.1920929f-7 : nothing
        
  L=CUDAnative.sqrt(Sx*Sx+Sy*Sy); mi=(Segment[ZelementIndex+1]-Segment[ZelementIndex])/Sy;
        
  δz=z[blockIdx().z]+mi*Segment[YelementIndex]-Segment[ZelementIndex]; 
  α=Sx/L; β=Sy/L;
  a=1+mi*mi;

  G=δx*α+δy*β+δz*mi; H=δx*δx+δy*δy+δz*δz;

  M=a*H-G*G;
  
  integral=(L*a-G)/(M*CUDAnative.sqrt(a*L*L-2*L+H))+G/(M*CUDAnative.sqrt(H));
  isfinite(integral) ? (
    @atomic Bx[1,offset]+=integral*(β*δz-mi*δy)*Current[1]; 
    @atomic By[1,offset]+=integral*(α*δz-mi*δx)*Current[1]; 
    @atomic Bz[1,offset]+=integral*(α*δy-β*δx)*Current[1];
    @atomic Bx[2,offset]+=integral*(β*δz-mi*δy)*Current[2]; 
    @atomic By[2,offset]+=integral*(α*δz-mi*δx)*Current[2]; 
    @atomic Bz[2,offset]+=integral*(α*δy-β*δx)*Current[2]
    ) : nothing

  return nothing
end


function calcValue(Bx,By,Bz,B)
  offset=(blockIdx().x-1)*blockDim().x +threadIdx().x
  B[offset]=CUDAnative.sqrt(Bx[1,offset]^2+Bx[2,offset]^2+By[1,offset]^2+By[2,offset]^2+Bz[1,offset]^2+Bz[2,offset]^2)
  return nothing
end

function bench_biot(x,y,z,Segment, Bx,By,Bz, Current,numberofsegments,SegmentsCalculated)
  CuArrays.@sync begin
    @cuda blocks=3 threads=numberofsegments+1 divideLine(Segment,numberofsegments+1,SegmentsCalculated)
    @cuda blocks=length(x),length(y),length(z) threads=numberofsegments,1,1 biotGPU(x,y,z,SegmentsCalculated,Bx,By,Bz, Current)
  end
end

end
