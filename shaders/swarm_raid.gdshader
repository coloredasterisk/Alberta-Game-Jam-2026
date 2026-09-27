shader_type canvas_item;
render_mode unshaded;
// Honey Heist: orbiting bee swarm with a stolen-honey accent.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float glow : hint_range(0.0, 1.0) = 0.9;
uniform float spread : hint_range(0.5, 2.0) = 1.4;
uniform int bee_count : hint_range(1, 20) = 14;
uniform float flight_speed : hint_range(0.1, 4.0) = 2.0;
float hash(float n){return fract(sin(n*127.1)*43758.5453);}
void fragment(){
	vec2 p=UV-vec2(0.5); float fade=smoothstep(0.0,0.12,progress)*(1.0-smoothstep(0.84,1.0,progress)); vec3 color=vec3(0.0); float alpha=0.0;
	for(int i=0;i<20;i++){if(i>=bee_count){break;} float fi=float(i); float a=6.28318*hash(fi+4.0)+TIME*flight_speed*mix(0.6,1.3,hash(fi+8.0)); float r=mix(0.11,0.34,hash(fi+12.0))*spread; vec2 q=p-vec2(cos(a),sin(a)*0.62)*r; float body=1.0-smoothstep(0.014,0.026,length(q/vec2(1.35,0.75))); float wa=1.0-smoothstep(0.010,0.022,length(q-vec2(-0.012,-0.021))); float wb=1.0-smoothstep(0.010,0.022,length(q-vec2(0.012,-0.021))); float aura=1.0-smoothstep(0.025,0.055,length(q)); color+=vec3(1.0,0.72,0.03)*body+vec3(0.72,0.9,1.0)*(wa+wb)+vec3(1.0,0.45,0.02)*aura*glow*0.35; alpha=max(alpha,max(max(body,wa),max(wb,aura*glow*0.45)));}
	float honey=1.0-smoothstep(0.025,0.045,length(p-vec2(0.0,0.30+0.025*sin(TIME*5.0)))); color+=vec3(1.0,0.48,0.0)*honey; alpha=max(alpha,honey); COLOR=vec4(color,alpha*fade);
}
