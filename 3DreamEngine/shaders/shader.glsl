//part of the 3DreamEngine by Luke100000
//shader.glsl - the main vertex and fragment shader

//required for secondary depth buffer and AO
#ifdef AO_ENABLED
	varying float depth;
#endif

//lighting
#ifdef LIGHTING
	//light pos and color (r, g, b and distance meter)
	extern highp vec3 lightPos[MAX_LIGHTS];
	extern lowp vec4 lightColor[MAX_LIGHTS];
	extern int lightCount;
#endif

//transformations
#ifdef SHADOWS_ENABLED
	extern highp mat4 transformProjShadow; //projective transformation for shadows
#endif

extern highp mat4 transformProj;           //projective transformation
extern highp mat4 transform;               //model transformation

//ambient
extern mediump vec3 ambient;               //ambient sun color

//viewer
extern highp vec3 viewPos;                 //position of viewer in world space
varying highp vec3 vertexPos;              //vertex position for pixel shader

//shadows
#ifdef SHADOWS_ENABLED
	varying highp vec4 vertexPosShadow;    //projected vertex position on shadow map
#endif

varying mat3 objToWorldSpace;


#ifdef PIXEL

//textures
#ifndef TEX_ALBEDO
	extern vec4 albedo;
#elif defined ARRAY_IMAGE
	uniform ArrayImage MainTex;
#else
	uniform Image MainTex;
#endif

#ifndef TEX_NORMAL
	extern vec3 normalT;
#elif defined ARRAY_IMAGE
	extern ArrayImage tex_normal;
#else
	extern Image tex_normal;
#endif

#ifndef TEX_ROUGHNESS
	extern float roughness;
#elif defined ARRAY_IMAGE
	extern ArrayImage tex_roughness;
#else
	extern Image tex_roughness;
#endif

#ifndef TEX_METALLIC
	extern float metallic;
#elif defined ARRAY_IMAGE
	extern ArrayImage tex_metallic;
#else
	extern Image tex_metallic;
#endif

#ifndef TEX_AO
	extern float ao;
#elif defined ARRAY_IMAGE
	extern ArrayImage tex_ao;
#else
	extern Image tex_ao;
#endif

#ifndef TEX_EMISSION
	extern float emissionFactor;
#elif defined ARRAY_IMAGE
	extern ArrayImage tex_emission;
#else
	extern Image tex_emission;
#endif


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

//shadows
#ifdef SHADOWS_ENABLED
	extern sampler2DShadow tex_shadow;
#endif

const float pi = 3.14159265359;
const float ipi = 0.31830988618;

float DistributionGGX(vec3 normal, vec3 halfView, float roughness) {
    float a = pow(roughness, 4.0);
	
    float NdotH = max(dot(normal, halfView), 0.0);
    float NdotH2 = NdotH * NdotH;
	
    float denom = NdotH2 * (a - 1.0) + 1.0;
    denom = pi * denom * denom;
	
    return a / max(denom, 0.0001);
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r*r) / 8.0;
    float denom = NdotV * (1.0 - k) + k;
    return NdotV / denom;
}

float GeometrySmith(vec3 normal, vec3 view, vec3 light, float roughness) {
    float NdotV = max(dot(normal, view), 0.0);
    float NdotL = max(dot(normal, light), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

void effect() {
	//values
	#ifdef TEX_ALBEDO
		#ifdef ARRAY_IMAGE
			vec4 albedo = Texel(MainTex, VaryingTexCoord.xyz);
		#else
			vec4 albedo = Texel(MainTex, VaryingTexCoord.xy);
		#endif
	#endif

	#ifdef TEX_NORMAL
		#ifdef ARRAY_IMAGE
			vec3 normal = normalize(objToWorldSpace * normalize(Texel(tex_normal, VaryingTexCoord.xyz).rgb - 0.5));
		#else
			vec3 normal = normalize(objToWorldSpace * normalize(Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
		#endif
	#else
		vec3 normal = normalize(objToWorldSpace * normalT);
	#endif

	#ifdef TEX_ROUGHNESS
		#ifdef ARRAY_IMAGE
			float roughness = Texel(tex_roughness, VaryingTexCoord.xyz).r;
		#else
			float roughness = Texel(tex_roughness, VaryingTexCoord.xy).r;
		#endif
	#endif

	#ifdef TEX_METALLIC
		#ifdef ARRAY_IMAGE
			float metallic = Texel(tex_metallic, VaryingTexCoord.xyz).r;
		#else
			float metallic = Texel(tex_metallic, VaryingTexCoord.xy).r;
		#endif
	#endif

	#ifdef TEX_AO
		#ifdef ARRAY_IMAGE
			float ao = Texel(tex_ao, VaryingTexCoord.xyz).r;
		#else
			float ao = Texel(tex_ao, VaryingTexCoord.xy).r;
		#endif
	#endif

	#ifdef TEX_EMISSION
		#ifdef ARRAY_IMAGE
			vec3 emission = Texel(tex_emission, VaryingTexCoord.xyz).rgb;
		#else
			vec3 emission = Texel(tex_emission, VaryingTexCoord.xy).rgb;
		#endif
	#else
		vec3 emission = albedo.xyz * emissionFactor;
	#endif
	

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
	
	highp vec3 viewVec = normalize(viewPos - vertexPos);
	
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
	#endif
	
	
	//fresnel
	vec3 F0 = mix(vec3(0.2), albedo.rgb, metallic);
	vec3 fresnel = F0 + (1.0 - F0) * pow(1.0 - clamp(dot(normal, viewVec), 0.0, 1.0), 5.0);
	
	//reflectiness
	vec3 reflectiness = mix(fresnel, vec3(1.0), metallic) * pow(1.0 - roughness, 2.0);
	
	//color
	#ifdef REFLECTIONS_DAY
		vec3 col = 0.25 * ambient * albedo.rgb * ao + emission * 4.0 + reflection * ambient * reflectiness;
	#else
		vec3 col = 0.25 * ambient * albedo.rgb * ao + emission * 4.0;
	#endif

	//point source lightings
	#ifdef LIGHTING
		for (int i = 0; i < lightCount; i++) {
			#ifdef SHADOWS_ENABLED
				float power = (i == 0 ? shadow : 1.0);
			#else
				float power = 1.0;
			#endif
			
			highp vec3 lightVec;
			if (lightColor[i].a == 0.0) {
				lightVec = lightPos[i];
			} else {
				highp vec3 lightVecR = lightPos[i] - vertexPos;
				lightVec = normalize(lightVecR);
				
				float distance = length(lightVecR) * lightColor[i].a;
				power /= (0.1 + distance * distance);
			}
			
			vec3 halfVec = normalize(viewVec + lightVec);
			
			float lightAngle = max(dot(lightVec, normal), 0.0);
			
			float NDF = DistributionGGX(normal, halfVec, roughness);   
			float G = GeometrySmith(normal, viewVec, lightVec, roughness);
			
			//diffuse
			vec3 diffuse = albedo.rgb * (1.0 - reflectiness) * ipi;
			
			//specular
			vec3 nominator = NDF * G * fresnel;
			float denominator = 4.0 * max(dot(normal, viewVec), 0.0) * max(dot(normal, lightVec), 0.0);
			vec3 specular = nominator / max(denominator, 0.00001);
			
			col += lightColor[i].rgb * 4.0 * (diffuse + specular) * power * lightAngle;
		}
	#endif
	
	//pass color to canvas
	love_Canvases[0] = vec4(col, 1.0);
	
	if (albedo.a < 0.5) {
		discard;
	}
	
	love_Canvases[NORMAL_CANVAS_ID] = vec4(normal, 1.0);
	love_Canvases[POSITION_CANVAS_ID] = vec4(vertexPos, 1.0);

	//pass overflow of final color to the HDR canvas
	#ifdef BLOOM_ENABLED
		love_Canvases[BLOOM_CANVAS_ID] = (vec4(col, 1.0) - vec4(1.0, 1.0, 1.0, 0.0)) * vec4(0.125, 0.125, 0.125, 1.0);
	#endif

	//normal and reflectiness for normal/reflection canvas
	#ifdef SSR_ENABLED
		love_Canvases[REFLECTINESS_CANVAS_ID] = vec4(length(reflectiness), 1.0, 1.0, 1.0);
	#endif
}
#endif


#ifdef VERTEX
//optional data for the wind shader
#ifdef VARIANT_WIND
	extern float wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
#endif

//additional vertex attributes
attribute highp vec3 VertexNormal;
attribute highp vec3 VertexTangent;
attribute highp vec3 VertexBiTangent;

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
	
	//transform into tangential space
	vec3 T = normalize(vec3(transform * vec4((VertexTangent*2.0-1.0), 0.0)));
	vec3 N = normalize(vec3(transform * vec4((VertexNormal*2.0-1.0), 0.0)));
	vec3 B = normalize(vec3(transform * vec4((VertexBiTangent*2.0-1.0), 0.0)));
	
	objToWorldSpace = mat3(T, B, N);
	
	vertexPos = pos.xyz;
	
	//projection transform for the shadow
	#ifdef SHADOWS_ENABLED
		vertexPosShadow = transformProjShadow * pos;
		
		//not necessary for orthographic transforms
		//vertexPosShadow.xyz = vertexPosShadow.xyz / vertexPosShadow.w;
	#endif
	
	//projection transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract and pass depth
	#ifdef AO_ENABLED
		depth = vPos.z;
	#endif
	
	return vPos;
}
#endif