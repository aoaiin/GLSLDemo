// 优化平面
// 背景色
// 添加box
// 添加贴图

#define r 0.5
#define spherepos vec3(0.,0.,0.)
#define ObjectSphere 1.
#define ObjectPlane 2.
#define Plane vec3(0.,-0.5,0.)

#define TMAX 30.
#define TMIN 0.01
#define RAYMARCHING 128
#define PRECISION 0.001
#define PI 3.1415926

#define AA 3

vec2 fixuv(in vec2 c){
  return (2.*c -iResolution.xy) /min(iResolution.x,iResolution.y);
}

// 点p 到球表面的距离
float sdfSphere1(in vec3 p) {
  return length( p - spherepos) - r;
}
// 当前点p 到平面的距离
float sdfPlane1(in vec3 p){
  return p.y - Plane.y;
}

vec2 opMin(in vec2 d1,in vec2 d2){
  return d1.x<d2.x?d1:d2;
}
// （当前点p 到场景物体 的距离 ， 该物体的id）
vec2 map(in vec3 p){
  // 在 后面添加上 物体的id
  vec2 d1 = vec2(sdfSphere1(p),ObjectSphere);
  vec2 d2 = vec2(sdfPlane1(p),ObjectPlane);

  return opMin(d1,d2);
}

vec2 rayMarching(in vec3 ro, in vec3 rd) {
  float t = TMIN;
  vec2 res = vec2(-1.,-1.);
  // 最多往前步进 RAYMARCHING 步
  for (int i = 0; i < RAYMARCHING && t<=TMAX; i++) {
    // 从ro出发，沿着rd方向，走t的距离
    vec3 p = ro + rd * t;
    // 物体id、距离
    vec2 d = map(p);
    if (abs(d.x) < PRECISION) {
      res = vec2(t,d.y);
      break;
    }
    // 没有相交，继续前进（可以直接加上d）
    t += d.x;
  }
  return res;
}


/*
  计算p点处的法线/梯度
  比如k是vec2(1,2)，那么k.xyy就是vec3(1,2,2)
*/
vec3 calNormal(in vec3 p){
  // h 表示往前一点点
  const float h=0.001;
  const vec2 k=vec2(1.,-1.);
  // 沿着p点周围的四个方向，计算梯度/法线
  return normalize( k.xyy* map(p+k.xyy*h).x+
                  k.yyx* map(p+k.yyx*h).x+
                  k.yxy* map(p+k.yxy*h).x+
                  k.xxx* map(p+k.xxx*h).x
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

// 可以从 p点出发，沿着lightPos方向，看是否有遮挡（调用raymarch） ，返回遮挡距离
float calShadow(in vec3 p , in vec3 lightPos){
  return rayMarching(p,normalize(lightPos-p)).x;
}

// k是软阴影的参数，越大越硬
float softShadow(in vec3 p , in vec3 lightPos, float k){
  vec3 lightDir = normalize(lightPos-p);
  float shadowval = 1.;
  float ph = 1e20;

  for(float t=TMIN;t<TMAX; ){

    float h = map(p + normalize(lightPos-p)*t).x;
    if(h<0.001){
      return 0.0;
    }

    float y = h*h/(2.*ph);
    float d = sqrt(h*h-y*y);
    shadowval = min(shadowval,k*d/max(0.0,t-y));
    ph = h;

    t += h;
  }
  return shadowval;
}

// 渲染：返回像素颜色
vec3 render(vec2 uv){
  vec3 color = vec3(0.0);

  // 定义一个相机位置  （xyz）
  vec3 ro = vec3(2.*cos(iTime), 1., 2.*sin(iTime));
  // vec3 ro = vec3(0., 0., 2.);
  if(iMouse.z>0.1){
    float theta=iMouse.x/iResolution.x*2.*PI;
    ro=vec3(2.*cos(theta),1.,2.*sin(theta));
  }
  vec3 target = vec3(0., 0., 0.);
  vec3 up = vec3(0.,1.,0.);
  mat3 cam = camera(target,ro,up);

  // 光线方向 
  // vec3 (uv,1.)是 相机空间中的
  vec3 rd = normalize( cam* vec3(uv, 1.));

  // 求交点
  vec2 t = rayMarching(ro, rd);
  if(t.y > 0.){   // t.y有物体交点
    // 交点坐标
    vec3 p = ro + rd * t.x;
    // 计算法线
    vec3 normal = calNormal(p);
    // 设置光源位置
    // vec3 lightPos = vec3(0.5 - 1.*cos(iTime), 2., -2.*sin(iTime));
    vec3 lightPos = vec3( 1., 2., 0.);
    // 计算光照（漫反射） 
    float  diff = clamp(dot(normalize(lightPos - p),normal), 0., 1.);

    // 计算是否有遮挡 / 阴影
    p += PRECISION * normal; // 如果直接从p出发，会和自己相交，会在面上有抖动，所以可以沿着法线方向走一点
    float shadow = softShadow(p,lightPos,10.);
    diff *= shadow;

    // 物体颜色
    // vec3 objColor = t.y == ObjectSphere ? vec3(1.,0.,0.) : vec3(0.,0.,1.);
    vec3 objColor = vec3(0.0);
    if(t.y >1.1 && t.y < 2.9){
      objColor = vec3(.2,.2,.2);
    }else if(t.y > 0.9 && t.y < 1.1){
      objColor = vec3(1.0,0.0,0.0);
    }

    // 全局光
    float ambilent = 0.5 + 0.5 * dot(normal, vec3(0., 1., 0.));

    color = ambilent*objColor + diff * vec3(1.0);
    // color = 1.*objColor + diff * vec3(1.0);
  }
  //一定的gamma矫正
  return pow(color,vec3(0.45));
  // return color;
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