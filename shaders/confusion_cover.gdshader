shader_type canvas_item;
render_mode unshaded;
// Chaos Halo: rotating rainbow question-mark icons.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.0, 1.0) = 0.9;
uniform float radius_scale : hint_range(0.5, 2.0) = 1.3;
uniform int icon_count : hint_range(1, 8) = 5;
uniform float rotation_speed : hint_range(0.1, 3.0) = 1.1;
float box(vec2 p,vec2 half_size){vec2 d=abs(p)-half_size; return 1.0-smoothstep(0.0,0.012,length(max(d,vec2(0.0)))+min(max(d.x,d.y),0.0));}
void fragment(){
	vec2 p=UV-vec2(0.5); float fade=smoothstep(0.0,0.1,progress)*(1.0-smoothstep(0.86,1.0,progress)); float radius=0.23*radius_scale; float ring=1.0-smoothstep(0.012,0.03,abs(length(p)-radius)); vec3 color=vec3(0.25,0.85,1.0)*ring*brightness; float alpha=ring*0.65;
	for(int i=0;i<8;i++){if(i>=icon_count){break;} float fi=float(i); float a=TIME*rotation_speed+6.28318*fi/float(icon_count); vec2 q=(p-vec2(cos(a),sin(a))*radius)/0.055; float top=box(q-vec2(0.0,-0.22),vec2(0.28,0.12)); float right=box(q-vec2(0.20,0.0),vec2(0.10,0.20)); float middle=box(q-vec2(0.02,0.17),vec2(0.13,0.10)); float stem=box(q-vec2(0.0,0.36),vec2(0.08,0.10)); float dot=box(q-vec2(0.0,0.62),vec2(0.08)); float icon=max(max(top,right),max(max(middle,stem),dot)); vec3 rainbow=0.58+0.42*cos(6.28318*(fi/max(float(icon_count),1.0)+vec3(0.0,0.67,0.33))); color+=rainbow*icon*brightness; alpha=max(alpha,icon);}
	COLOR=vec4(color,alpha*fade);
}
