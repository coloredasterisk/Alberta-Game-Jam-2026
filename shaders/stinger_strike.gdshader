shader_type canvas_item;
render_mode unshaded;
// Rainbow Lance: transparent procedural projectile overlay.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float glow : hint_range(0.0, 1.0) = 0.8;
uniform float trail_scale : hint_range(0.5, 2.0) = 1.0;
uniform float rainbow_width : hint_range(1.0, 40.0) = 20.0;
uniform float pulse_speed : hint_range(0.1, 5.0) = 2.5;
uniform float facing : hint_range(-1.0, 1.0) = 1.0;
float segment(vec2 p, vec2 a, vec2 b) { vec2 pa=p-a; vec2 ba=b-a; float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0); return length(pa-ba*h); }
void fragment() {
	vec2 p=UV-vec2(0.5); p.x*=facing;
	float fade=smoothstep(0.0,0.12,progress)*(1.0-smoothstep(0.82,1.0,progress));
	float w=mix(0.008,0.035,rainbow_width/40.0); float pulse=0.78+0.22*sin(TIME*pulse_speed*6.28318);
	vec3 color=vec3(0.0); float alpha=0.0;
	for(int i=0;i<6;i++){float fi=float(i); float y=(fi-2.5)*w*0.72; float band=1.0-smoothstep(w*0.45,w,segment(p,vec2(-0.42*trail_scale,y),vec2(0.28,y*0.25))); vec3 rainbow=0.55+0.45*cos(6.28318*(fi/6.0+vec3(0.0,0.67,0.33))); color+=rainbow*band; alpha=max(alpha,band);}
	float tip=1.0-smoothstep(0.025,0.09,length(p-vec2(0.32,0.0))); float aura=1.0-smoothstep(0.06,0.20,length(p-vec2(0.32,0.0)));
	color+=vec3(1.0,0.95,0.65)*tip+vec3(1.0,0.55,0.12)*aura*glow*pulse; alpha=max(alpha,max(tip,aura*glow)); COLOR=vec4(color*pulse,alpha*fade);
}
