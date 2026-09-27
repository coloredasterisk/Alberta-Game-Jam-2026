shader_type canvas_item;
render_mode unshaded;
// Pocket Storm: compact cloud and seeded rain field.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.75;
uniform float effect_scale : hint_range(0.5, 2.0) = 1.3;
uniform int drop_count : hint_range(1, 32) = 20;
uniform float fall_speed : hint_range(0.1, 3.0) = 0.8;
float hash(float n){return fract(sin(n*91.3458)*47453.5453);}
void fragment(){
	vec2 p=(UV-vec2(0.5))/effect_scale; float fade=smoothstep(0.0,0.1,progress)*(1.0-smoothstep(0.88,1.0,progress)); float cloud=0.0;
	for(int i=0;i<7;i++){float fi=float(i); vec2 c=vec2((fi-3.0)*0.075,-0.17+0.025*mod(fi,2.0)); cloud=max(cloud,1.0-smoothstep(0.075,0.09,length(p-c)));}
	vec3 color=mix(vec3(0.38),vec3(0.055,0.065,0.09),darkness)*cloud; float alpha=cloud;
	for(int i=0;i<32;i++){if(i>=drop_count){break;} float fi=float(i); float x=mix(-0.30,0.30,hash(fi+2.0)); float y=mix(-0.08,0.43,fract(TIME*fall_speed+hash(fi+17.0))); vec2 q=p-vec2(x,y); float drop=(1.0-smoothstep(0.008,0.015,abs(q.x)))*(1.0-smoothstep(0.025,0.055,abs(q.y))); color+=vec3(0.12,0.55,1.0)*drop; alpha=max(alpha,drop);}
	COLOR=vec4(color,alpha*fade);
}
