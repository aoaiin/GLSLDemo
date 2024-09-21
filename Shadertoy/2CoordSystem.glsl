
vec3 Grid(vec2 uv){ 
  vec3 col = vec3(0.0);

  // fract 取小数部分
  vec2 cell=fract(uv);
  // 画出线框
  if(cell.x<fwidth(uv.x) || cell.y<fwidth(uv.y)){
    col=vec3(1.);
  }

  // fwidth（v） = abs( ddx(v) )  ， abs(ddy(v))
  // fwidth(v) 用于计算v的梯度，即v的变化率 : 可以看成是两个像素之间的差值
  // 两个坐标轴 弄成红绿色
  if(abs(uv.x) < fwidth(uv.x)){
    col=vec3(1.,0.,0.);
  }
  if(abs(uv.y) < fwidth(uv.y)){
    col=vec3(0.,1.,0.);
  }

  return col;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // irezolution 屏幕分辨率
  // 先将坐标 转换到 -x ~ x ，再除以x，得到 -1 ~ 1
    vec2 uv = 3.*(2. * fragCoord - iResolution.xy) / min(iResolution.x,iResolution.y);

    fragColor = vec4(Grid(uv),1.0);
}