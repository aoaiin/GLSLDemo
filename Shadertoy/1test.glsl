void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // irezolution 屏幕分辨率
  // 先将坐标 转换到 -x ~ x ，再除以x，得到 -1 ~ 1
    vec2 uv = (2. * fragCoord - iResolution.xy) / min(iResolution.x,iResolution.y);

    float d = 0.;
    float r = 0.3;
    if(length(uv) < r){
        d=1.;
    }
    fragColor = vec4(vec3(d),1.0);
}