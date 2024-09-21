// https://iquilezles.org/articles/normalsSDF/
#define r 0.5
#define spherepos vec3(0.,0.,0.)

#define TMAX 20.
#define TMIN 0.01
#define RAYMARCHING 128
#define PRECISION 0.001
#define PI 3.1415926

#define AA 3

vec2 fixuv(in vec2 c){
  return (2.*c -iResolution.xy) /min(iResolution.x,iResolution.y);
}

// 点p 到球表面的距离
float sdfSphere(in vec3 p) {
  return length( p - spherepos) - r;
}

float rayMarching(in vec3 ro, in vec3 rd) {
  float t = TMIN;

  // 最多往前步进 RAYMARCHING 步
  for (int i = 0; i < RAYMARCHING && t<=TMAX; i++) {
    // 从ro出发，沿着rd方向，走t的距离
    vec3 p = ro + rd * t;

    // 计算p点到球体的距离: 距离够小，就认为相交，返回距离
    float d = sdfSphere(p);
    if (abs(d) < PRECISION) {
      break;
    }
    // 没有相交，继续前进（可以直接加上d）
    t += d;
  }
  return t;
}

// 计算p点处的法线/梯度
/*
  比如k是vec2(1,2)，那么k.xyy就是vec3(1,2,2)
*/
vec3 calNormal(in vec3 p){
  const float h=0.001;
  const vec2 k=vec2(1.,-1.);
  // 沿着p点周围的四个方向，计算梯度/法线
  return normalize( k.xyy*sdfSphere(p+k.xyy*h)+
                  k.yyx*sdfSphere(p+k.yyx*h)+
                  k.yxy*sdfSphere(p+k.yxy*h)+
                  k.xxx*sdfSphere(p+k.xxx*h)
                  );
}

// 相机矩阵:观察目标，相机位置，向上
// 能从 相机空间 -》 世界空间
mat3 camera(vec3 target,vec3 pos,vec3 up){
  vec3 z=normalize(target-pos);
  vec3 x=normalize(cross(z,up));
  vec3 y=cross(x,z);
  return mat3(x,y,z);
}

// 渲染：返回像素颜色
vec3 render(vec2 uv){
  vec3 color = vec3(0.0);

  // 定义一个相机位置  （xyz）
  // vec3 ro = vec3(2.*cos(iTime), 0., 2.*sin(iTime));
  vec3 ro = vec3(0., 0., 2.);
  if(iMouse.z>0.1){
    float theta=iMouse.x/iResolution.x*2.*PI;
    ro=vec3(2.*cos(theta),0.,2.*sin(theta));
  }
  vec3 target = vec3(0., 0., 0.);
  vec3 up = vec3(0.,1.,0.);
  mat3 cam = camera(target,ro,up);

  // 光线方向 
  // vec3 (uv,1.)是 相机空间中的
  vec3 rd = normalize( cam* vec3(uv, 1.));

  // 求交点
  float t = rayMarching(ro, rd);
  if(t<TMAX){
    // 交点坐标
    vec3 p = ro + rd * t;
    // 计算法线
    vec3 normal = calNormal(p);
    // 设置光源
    // vec3 lightPos = vec3(0.5 - 1.*cos(iTime), 2., -2.*sin(iTime));
    vec3 lightPos = vec3( 1., 2., 0.);
    // 计算光照（漫反射） 
    float  diff = clamp(dot(normalize(lightPos - p),normal), 0., 1.);
    // 全局光
    float ambilent = 0.5 + 0.5 * dot(normal, vec3(0., 1., 0.));

    color = ambilent*vec3(0.25) + diff * vec3(1.0);
  }
  //一定的gamma矫正
  return pow(color,vec3(0.45));
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
  vec3 color =vec3(0.0);
  // 采样周围AA*AA个点,再平均
  for(int m=0;m<AA;m++){
    for(int n=0;n<AA;n++){
      // 归一化的偏移
      vec2 offset = 2.* (vec2(float(m),float(n))/float(AA) -0.5);
      vec2 uv= fixuv(fragCoord+offset);
      // 对周围点的颜色进行累加
      color += render(uv);
    }
  }
  color = color/float(AA*AA);

  fragColor = vec4(color,1.0);
}