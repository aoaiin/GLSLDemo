#define r 0.5+.3*sin(iTime)

vec2 fixuv(in vec2 c){
  return (2.*c -iResolution.xy) /min(iResolution.x,iResolution.y);
}

// 当前位置，到 圆（以原点为圆心，半径为r）的距离
float sdfCircle(vec2 p) {
  return length(p) - r;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
  // 0-1
  vec2 uv = fixuv(fragCoord);

  // 当前坐标 离 圆边 的距离
  float d = sdfCircle(uv);

  vec3 color = 1. - sign(d)*vec3(.4,.5,.6);
  // 越靠近边界，越改变颜色 ； 距离越远，不改变颜色
  color *= 1. - exp(-3. *abs(d));
  // 添加一些噪声 / 等高线 ：改变颜色
  color *= .8+.2*sin(150.*abs(d));
  // 画圆的边界 : 越靠近边界，画边界线
  color = mix(color,vec3(1.),1.-smoothstep(0.005,0.009,abs(d)));

  // iMouse.z 表示鼠标按下的状态 ： 鼠标按下时，才绘制
  if(iMouse.z > 0.1){
    vec2 m = fixuv(iMouse.xy);
    // ***鼠标位置 到 圆的距离***
    float mdistance = abs(sdfCircle(m));

    // length(uv-m):屏幕任意坐标 到 鼠标的距离 
    // length(uv-m) - mdistance : 根据圆的大小，变化需要绘制的区域

    // 鼠标周围画圆 
    color = mix(color,vec3(1.,0.,0.),1.-smoothstep(.0,0.01,abs(length(uv-m)-mdistance)));
    // 鼠标位置画点
    color = mix(color,vec3(1.,0.,0.),1.-smoothstep(0.0,0.01,length(uv-m)));
  }

  fragColor = vec4(color,1.0);
}