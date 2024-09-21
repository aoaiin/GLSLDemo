#define Pi 3.1425926

// fixuv（标准化）: 将uv坐标转换到[-3,3]的范围内 
vec2 fixuv(in vec2 c){
  return 3. * (2.* c - iResolution.xy) / min(iResolution.x,iResolution.y);
}


vec3 Grid(in vec2 uv){ 
  vec3 col = vec3(0.4);

  // 对uv坐标取模，然后floor下取整，值为 0 或 1
  vec2 grid=floor(mod(uv,2.));
  if(grid.x == grid.y)col =vec3(0.6);

  //绘制坐标轴
  col = mix(col,vec3(0.0),1.-smoothstep(0.,4.*fwidth(uv.x),abs(uv.x)));
  col = mix(col,vec3(0.0),1.-smoothstep(0.,4.*fwidth(uv.y),abs(uv.y)));

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

  f = smoothstep( w, 0.9* w,d);
  return f;
}

float func(in float x){
  float T = 4. + sin(iTime);
  return sin(2. *Pi /T *x);
}

// 将函数 沿着y 分为两部分 （边界处 插值）
float funcPlot(in vec2 uv){
  float y=func(uv.x);
  return smoothstep(y-0.01,y+0.01,(uv.y));
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fixuv(fragCoord);

  vec3 col = Grid(uv);

  // 函数的形状：
  // col = vec3(funcPlot(uv));

  // 对 曲线边界进行采样 :周围的
  #define AA 4
  float count=0.;
  for(int m=0;m<AA;m++){
    for(int n=0;n<AA;n++){
      
      vec2 offset=vec2(float(m),float(n));
      // 归一化
      offset = 2.*(offset - float(AA))/float(AA);

      // 累加周围点的值(先对原图进行偏移，再转换到 标准的uv坐标)
      // 对边界进行采样
      count += funcPlot(fixuv(fragCoord+offset));
    }
  }
  // 将 采样结果 归一化到 0-1 ： 
  // 采样数量在 0-AA*AA ，越接近中间，越接近1；越在边界，越接近0 ： 中间的权重大？？
  if(count >float(AA*AA)/2.){
    count = float(AA*AA)-count;
  }
  count = count*2. /float(AA*AA);


  col = mix(col,vec3(1.0),count);

  fragColor = vec4(col,1.0);
}