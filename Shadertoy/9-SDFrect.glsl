#define r 0.5+.2*sin(iTime)

vec2 fixuv(in vec2 c){
  return 2.*(2.*c -iResolution.xy) /min(iResolution.x,iResolution.y);
}

float sdfRect(vec2 p,vec2 b) {
  vec2 d=abs(p)-b;
  return length(max(d,0.)) + min(max(d.x,d.y),0.);
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){

  vec2 uv = fixuv(fragCoord);

  // 当前坐标 离 圆边 的距离
  float d = sdfRect(uv,vec2(1.+.2*sin(iTime),1.+.3*cos(iTime)));

  vec3 color = vec3(1.) - sign(d) * vec3(.2,.3,.4);
  // 越靠近边界，越改变颜色 ； 距离越远，不改变颜色
  color *= 1. - exp(-3. *abs(d));
  // 添加一些噪声 / 等高线 ：改变颜色
  color *= .8+.2*sin(150.*abs(d));
  // 画圆的边界 : 越靠近边界，画边界线
  color = mix(color,vec3(1.),1.-smoothstep(0.004,0.005,abs(d)));

  if(iMouse.z > 0.1){
    vec2 m = fixuv(iMouse.xy);

    float mdistance = abs(sdfRect(m,vec2(1.+.2*sin(iTime),1.+.3*cos(iTime))));
    // 鼠标周围画圆 
    color = mix(color,vec3(1.,0.,0.),1.-smoothstep(.0,0.01,abs(length(uv-m)-mdistance)));
    // 鼠标位置画点
    color = mix(color,vec3(1.,0.,0.),1.-smoothstep(0.0,0.01,length(uv-m)));
  }

  fragColor = vec4(color,1.0);
}