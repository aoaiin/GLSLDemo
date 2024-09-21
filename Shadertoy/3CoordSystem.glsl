#define Pi 3.1425926

// fixuv（标准化）: 将uv坐标转换到[-3,3]的范围内 
vec2 fixuv(in vec2 c){
  return 3. * (2.* c - iResolution.xy) / min(iResolution.x,iResolution.y);
}

// 返回 uv点上的颜色
vec3 Grid(in vec2 uv){ 
  
  vec3 col = vec3(0.0);
  // 将 负数的小数部分 转换到0-1之间，也能被绘制 
  vec2 fraction = 1. - 2.*abs(fract(uv)-.5);

  if(abs(uv.x)<=  fwidth(uv.x)){
    col = vec3(1.,0.,0.);
  }
  else if(abs(uv.y)<=  fwidth(uv.y)){
    col = vec3(0.,1.,0.);
  }
  else if(fraction.x <=  fwidth(uv.x) || fraction.y <=  fwidth(uv.y)){
    col = vec3(1.);
  }

  return col;
}


//绘制直线： 绘制的位置p，起点a，终点b，宽度w
float line(in vec2 p,in vec2 a,in vec2 b, in float w){
  float f = 0.;
  vec2 ab=b-a;
  vec2 ap=p-a;

  // ap在 ab上的投影
  float proj = clamp(dot(ap,ab)/dot(ab,ab),0.,1.);

  // proj*ab -ap 为p到直线ab的距离
  float d=length(proj*ab -ap);
  
  // 只有在 一个宽度内的线段上才绘制
  // if(d<= 10.* w){
  if(d<= w){
    f=1.;
  }
  return f;
}

// 自定义函数：输入x，返回y
float func(in float x){
  // sinx 在-1~1，记得不要让T=0
  float T = 2. + sin(iTime);
  // float T = 1. ;
  float A = 1.;
  return A * sin(2. * Pi / T * x);
}

//传入 uv坐标，返回 0/1（该坐标点是否有函数值）
float funcPlot(in vec2 uv){
  float f = 0.;

// #define use 0.
#ifdef use
  {
    // 沿着x轴遍历/绘制
    for(float x=0.; x<=iResolution.x; x+=1.){
      // (在标准坐标系下) 取 当前x坐标、下一个点的x坐标
      float fx=fixuv(vec2(x,0.)).x;
      float nfx=fixuv(vec2(x+1.,0.)).x;

      // 绘制 从x到x+1的线段 ，如果能绘制，则返回1，加在f上
      f += line(uv,vec2(fx,func(fx)),vec2(nfx,func(nfx)),fwidth(uv.x));
    }
  }
#else 
  float ddx=fwidth(uv.x);
  f += line(uv,vec2(uv.x-ddx,func(uv.x-ddx)),vec2(uv.x+ddx,func(uv.x+ddx)),ddx);
#endif

  // 确保f在[0,1]之间
  return clamp(f,0.,1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fixuv(fragCoord);
  vec3 col = Grid(uv);
  // 在col和黄色之间，用line进行插值（line=0，表示不在直线，用col）
  // col = mix(col,vec3(1.,1.,0),line(uv,vec2(0.,0.),vec2(1.,1.),fwidth(uv.x)));
  col = mix(col,vec3(1.,1.,0),funcPlot(uv));
  fragColor = vec4(col,1.0);
}