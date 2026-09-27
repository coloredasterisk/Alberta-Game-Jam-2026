shader_type canvas_item;
render_mode unshaded;
// Wing Streak: bright directional speed lines.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.0, 1.0) = 0.8;
uniform float trail_length : hint_range(0.5, 2.0) = 1.4;
uniform int line_count : hint_range(1, 20) = 18;
uniform float burst_speed : hint_range(0.1, 4.0) = 1.8;
uniform float facing : hint_range(-1.0, 1.0) = 1.0;
float hash(float n){return fract(sin(n*73.17)*65314.176);}
void fragment(){
	vec2 p=UV-vec2(0.5); p.x*=facing; float fade=smoothstep(0.0,0.08,progress)*(1.0-smoothstep(0.86,1.0,progress)); vec3 color=vec3(0.0); float alpha=0.0;
	for(int i=0;i<20;i++){if(i>=line_count){break;} float fi=float(i); float y=mix(-0.38,0.38,hash(fi+1.0)); float offset=fract(TIME*burst_speed*mix(0.7,1.4,hash(fi+5.0))+hash(fi+9.0)); float head=mix(-0.40,0.30,offset); float len=mix(0.035,0.17,hash(fi+13.0))*trail_length; float horizontal=smoothstep(head-len,head,p.x)*(1.0-smoothstep(head,head+0.018,p.x)); float vertical=1.0-smoothstep(0.004,0.011,abs(p.y-y)); float line=horizontal*vertical; color+=mix(vec3(0.35,0.78,1.0),vec3(1.0),brightness)*line; alpha=max(alpha,line);}
	COLOR=vec4(color,alpha*fade*brightness);
}
