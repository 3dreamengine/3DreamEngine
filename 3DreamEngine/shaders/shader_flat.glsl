//part of the 3DreamEngine by Luke100000
//shader.glsl - the main vertex and fragment shader

//required for secondary depth buffer and AO
#ifdef AO_ENABLED
	varying float depth;
#endif

varying vec3 normalVec;

//lighting
#ifdef LIGHTING
	//light pos and color (r, g, b and distance meter)
	extern highp vec3 lightPos[MAX_LIGHTS];
	extern highp vec4 lightColor[MAX_LIGHTS];
	extern int lightCount;
#endif

//transformations
#ifdef SHADOWS_ENABLED
	extern highp mat4 transformProjShadow; //projective transformation for shadows
#endif

extern highp mat4 transformProj;          //projective transformation
extern highp mat4 transform;              //model transformation

//ambient
extern mediump vec3 ambient;              //ambient sun color

//viewer
extern highp vec3 viewPos;                //position of viewer in world space
varying highp vec3 vertexPos;             //vertex position for pixel shader

//shadows
#ifdef SHADOWS_ENABLED
	varying highp vec4 vertexPosShadow;   //projected vertex position on shadow map
#endif



#ifdef PIXEL

//shadows
#ifdef SHADOWS_ENABLED
	extern sampler2DShadow tex_shadow;
#endif

//for flat shading and textured emission, this value works as a multiplier
//for textured non-emission-texture shader this is the global value
extern float emission;

//texture used to simulate reflections
#ifdef REFLECTIONS_DAY
	extern Image background_day;                //background day texture

	//an optional texture for night, blending done automatically
	#ifdef REFLECTIONS_NIGHT
		extern Image background_night;          //background night texture
		extern mediump vec3 background_color;   //background color
		extern float background_time;           //background day/night factor
	#endif
#endif

void effect() {
	//get specular level, either from the texture, the vertex on flat shading or the fallback global value
	float spec = VaryingTexCoord.a * 0.95;
	
	//apply shadow
	#ifdef SHADOWS_ENABLED
		float bias = 0.0005;
		vec3 shadowUV = vertexPosShadow.xyz * 0.5 + 0.5 - vec3(0.0, 0.0, bias);
		
		float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
		float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
		if (oy > 1.1) oy = 0.0;
		
		float texelSize = 1.0 / 4096.0;
		float shadow = (
			texture(tex_shadow, shadowUV + vec3(-1.5 + ox, 0.5 + oy, 0.0) * texelSize) +
			texture(tex_shadow, shadowUV + vec3(0.5 + ox, 0.5 + oy, 0.0) * texelSize) +
			texture(tex_shadow, shadowUV + vec3(-1.5 + ox, -1.5 + oy, 0.0) * texelSize) +
			texture(tex_shadow, shadowUV + vec3(0.5 + ox, -1.5 + oy, 0.0) * texelSize)
		) * 0.25;
	#endif
	
	//base light
	mediump vec3 lighting = ambient;
	
	highp vec3 viewVec = normalize(viewPos - vertexPos);
	highp vec3 normal = normalize(normalVec);

	//point source lightings
	#ifdef LIGHTING
		//lighting
		for (int i = 0; i < lightCount; i++) {
			#ifdef SHADOWS_ENABLED
				float power = (i == 0 ? shadow : 1.0);
			#else
				float power = 1.0;
			#endif
			
			highp vec3 lightVecN;
			if (lightColor[i].a == 0.0) {
				lightVecN = lightPos[i];
			} else {
				highp vec3 lightVec = lightPos[i] - vertexPos;
				lightVecN = normalize(lightVec);
				
				float distance = length(lightVec) * lightColor[i].a;
				power /= (0.005 + distance * distance);
			}
			
			float diffuse = clamp(dot(normal, lightVecN), 0.0, 1.0);
			float NdotH = clamp(dot(normal, normalize(viewVec + lightVecN)), 0.0, 1.0);
			float specular = pow(NdotH, spec * 64.0);
			
			lighting += (specular + diffuse) * lightColor[i].rgb * power;
		}
	#endif
	
	//reflections
	#ifdef REFLECTIONS_DAY
		//get reflected normal
		highp vec3 n = reflect(viewVec, normal);
		
		//get UV coord
		float u = atan(n.x, n.z) * 0.1591549430919 - 0.25;
		float v = n.y * 0.5 + 0.5;
		mediump vec2 uv = vec2(u, v);
		
		//get (optional blend) the color of the sky/background
		#ifdef REFLECTIONS_NIGHT
			mediump vec3 reflection = mix(Texel(background_day, uv), Texel(background_night, uv), background_time).rgb * background_color;
		#else
			mediump vec3 reflection = Texel(background_day, uv).rgb;
		#endif
		
		mediump vec4 col = vec4(mix(VaryingColor.rgb * lighting * ambient, reflection, spec), VaryingColor.a);
	#else
		mediump vec4 col = vec4(VaryingColor.rgb * lighting, VaryingColor.a);
	#endif
	
	//emission
	col += VaryingColor * emission;
	
	//pass color to canvas
	love_Canvases[0] = col;
	
	love_Canvases[NORMAL_CANVAS_ID] = vec4(normal, 1.0);
	love_Canvases[POSITION_CANVAS_ID] = vec4(vertexPos, 1.0);
	
	//pass overflow of final color to the HDR canvas
	#ifdef BLOOM_ENABLED
		love_Canvases[BLOOM_CANVAS_ID] = (vec4(col.rgb, 1.0) - vec4(1.0, 1.0, 1.0, 0.0)) * vec4(0.125, 0.125, 0.125, 1.0);
	#endif

	//normal and reflectiness for normal/reflection canvas
	#ifdef SSR_ENABLED
		love_Canvases[REFLECTINESS_CANVAS_ID] = vec4(spec, 1.0, 1.0, 1.0);
	#endif

}//end effetcs()
#endif


#ifdef VERTEX

//optional data for the wind shader
#ifdef VARIANT_WIND
	extern float wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
#endif

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	//calculate vertex position
	#ifdef VARIANT_WIND
		//where vertex_position.a is used for the waving strength
		highp vec4 pos = transform * (
			vec4(vertex_position.xyz, 1.0)
			+ vec4((cos(vertex_position.x*0.25*shader_wind_scale + wind) + cos((vertex_position.z*4.0+vertex_position.y)*shader_wind_scale + wind*2.0)) * vertex_position.a * shader_wind_strength, 0.0, 0.0, 0.0)
		);
	#else
		highp vec4 pos = transform * vertex_position;
	#endif
	
	//pass raw vertex position to fragment shader
	vertexPos = pos.xyz;
	
	//projective transform for the shadow
	#ifdef SHADOWS_ENABLED
		vertexPosShadow = transformProjShadow * pos;
	#endif
	
	//projective transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract normal vector
	normalVec = (transform * vec4(VertexTexCoord.xyz*2.0-1.0, 0.0)).xyz;
	
	//extract and pass depth
	#ifdef AO_ENABLED
		depth = vPos.z;
	#endif
	
	return vPos;
} //end of position()
#endif