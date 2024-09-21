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

  // if(abs(uv.x)<=  fwidth(uv.x)){
  //   col = vec3(1.,0.,0.);
  // }
  // else if(abs(uv.y)<=  fwidth(uv.y)){
  //   col = vec3(0.,1.,0.);
  // }
  // else if(fraction.x <=  fwidth(uv.x) || fraction.y <=  fwidth(uv.y)){
  //   col = vec3(1.);
  // }

  // 坐标在 一个像素内 绘制 -》 (小于小的 时 =1，绘制； 大于大的时 =0)
  col = vec3(smoothstep(3.* fwidth(uv.x),2.*fwidth(uv.x),fraction.x));
  col += vec3(smoothstep(20.* fwidth(uv.y),10.*fwidth(uv.y),fraction.y));
  //绘制 xy轴 
  // 这里用 1-  等于 上面交换顺序
  // uv.x : y轴左右的， 在 [0,ddx]之间有值/绘制， 超出的地方返回1/不改变颜色 
  // 这里对红、蓝乘了0，只剩下了绿色
  col.rb *= smoothstep(0.,fwidth(uv.x),abs(uv.x));
  col.gb *= smoothstep(4.*fwidth(uv.y),7.*fwidth(uv.y),abs(uv.y));
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
  // if(d<= w){
  //   f=1.;
  // }

  // [0.95*w,w] 之间的值，返回0-1之间的值,大于w返回0，小于0.95w返回1
  f = smoothstep( w, 0.9* w,d);
  return f;
}

float func(in float x){
  // 使用 x 在两个边界范围 之间插值，返回一个0-1之间的值；
  // 大于或小于时，返回0或1

  // 假设 a<b
  // 边界为[a,b] ：之间的值，返回0-1之间的值 ,大于b时，返回1，小于a时，返回0
  // [b,a]：之间的值，返回0-1之间的，小于a时，返回1，大于b时，返回0
  // smoothstep[a,b] = 1.-smoothstep[b,a]
  
  // return smoothstep(0.,1.,x);
  return smoothstep(3.,-1.,x);
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
  // float ddy=fwidth(uv.y);
  f += line(uv,vec2(uv.x-ddx,func(uv.x-ddx)),vec2(uv.x+ddx,func(uv.x+ddx)),ddx);
  // f += line(uv,vec2(uv.y-ddy,func(uv.y-ddy)),vec2(uv.y+ddy,func(uv.y+ddy)),ddy);
#endif

  // 确保f在[0,1]之间
  return clamp(f,0.,1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fixuv(fragCoord);

  vec3 col = Grid(uv);
  col = mix(col,vec3(1.,1.,0),funcPlot(uv));

  // // 画 圆
  // vec3 col = vec3(0.0);
  // // 这种通过 长度判断的 边界有锯齿
  // // if(length(uv) <= 1.){
  // //   col = vec3(1.);
  // // }
  // // 大于1的地方，返回0，小于.99 的地方返回1，边界处返回0-1之间的值
  // col = vec3(smoothstep(1., .99 , length(uv)));

  fragColor = vec4(col,1.0);
}