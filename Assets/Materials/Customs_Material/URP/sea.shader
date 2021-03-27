﻿Shader "URP/sea"
{
	Properties
	{
    	_lightPos("lightPos", Vector) = (0 , 1, 0, 0)
		_Alpha("Alpha",Range(0,100)) = 1
		_test("test",Range(-1,1)) = 1
		_FenelPower("FenelPower",Range(0,100)) = 1
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags {"RenderPipLine" = "UniversalPipeline"}
		

		HLSLINCLUDE

		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		//#include "UnityCG.cginc"
		
		CBUFFER_START(UnityPerMaterial)

		float _Alpha;
		float _FenelPower;
		float _test;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		uniform float4 _lightPos;
		
		CBUFFER_END

		// 声明深度纹理，注意该名称是指定的
        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);

		SAMPLER(sampler_CubeMap);
			
		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float3 normal : NORMAL;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;

			float3 worldNormal : TEXCOORD1;
			float4 projPos : TEXCOORD2;
			float3 worldPos : TEXCOORD3;
		};

		
		

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = TransformObjectToHClip(v.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);

			
			o.projPos = ComputeScreenPos(o.vertex);
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldNormal = TransformObjectToWorldNormal(v.normal);
			//这两句一样的，看源码
			//COMPUTE_EYEDEPTH(o.projPos.z);
			o.projPos.z = -TransformWorldToView(TransformObjectToWorld(v.vertex)).z;
			//o.projPos.xy = o.projPos.xy/o.projPos.w;
			return o;
		}
		
		half4 cosine_gradient(float x,  half4 phase, half4 amp, half4 freq, half4 offset){
			const float TAU = 2. * 3.14159265;
  			phase *= TAU;
  			x *= TAU;
		
  			return half4(
    			offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
    			offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
    			offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
    			offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
  			);
		}
		half3 toRGB(half4 grad){
  			 return grad.rgb;
		}
		float2 rand(float2 st, int seed)
		{
			float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
			return -1 + 2 * frac(sin(s) * 43758.5453123);
		}
		float noise(float2 st, int seed)
		{
			st.y += _Time[1];
		
			float2 p = floor(st);
			float2 f = frac(st);
 	
			float w00 = dot(rand(p, seed), f);
			float w10 = dot(rand(p + float2(1, 0), seed), f - float2(1, 0));
			float w01 = dot(rand(p + float2(0, 1), seed), f - float2(0, 1));
			float w11 = dot(rand(p + float2(1, 1), seed), f - float2(1, 1));
			
			float2 u = f * f * (3 - 2 * f);
 	
			return lerp(lerp(w00, w10, u.x), lerp(w01, w11, u.x), u.y);
		}
		float3 swell(float3 normal , float3 pos , float anisotropy){
			float height = noise(pos.xz * 0.1,0);
			height *= anisotropy ;
			normal = normalize(
				cross ( 
					float3(0,ddy(height),1),
					float3(1,ddx(height),0)
				)
			);
			return normal;
		}

		//UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);	
		half4 frag (v2f i) : SV_Target
		{
			i.projPos.xy /= i.projPos.w;
			// sample the texture
			half4 col = tex2D(_MainTex, i.uv);
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.projPos.xy);
			float sceneZ = LinearEyeDepth(depth,_ZBufferParams);

    		//float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
			float partZ = i.projPos.z;
			float volmeZ = saturate( (sceneZ - partZ)/_Alpha);

			 const half4 phases = half4(0.28, 0.50, 0.07, 0.);
			 const half4 amplitudes = half4(4.02, 0.34, 0.65, 0.);
			 const half4 frequencies = half4(0.00, 0.48, 0.08, 0.);
			 const half4 offsets = half4(0.00, 0.16, 0.00, 0.);

			half4 cos_grad = cosine_gradient(1-volmeZ, phases, amplitudes, frequencies, offsets);
  			cos_grad = clamp(cos_grad + _test, 0., 1.);
  			col.rgb = toRGB(cos_grad);
				
			 //波にゆらぎを与える
			half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

			//エイリアシング防止
			float3 v = i.worldPos - _WorldSpaceCameraPos;
			float anisotropy = saturate(1/(ddy(length ( v.xz )))/5);
			float3 swelledNormal = swell(i.worldNormal , i.worldPos , anisotropy);

			 //relfection color
            half3 reflDir = reflect(-worldViewDir, swelledNormal);
			//half4 reflectionColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 0);
			half4 reflectionColor = SAMPLE_TEXTURECUBE(unity_SpecCube0,samplerunity_SpecCube0,reflDir);
			/* speclar
			float spe = pow( saturate(dot( reflDir, normalize(_lightPos.xyz))),100);
			float3 lightColor = float3(1,1,1);
			reflectionColor += 0.4 * half4((spe * lightColor).xxxx);
			*/

			// fresnel reflect 
			float f0 = 0.02;
     		float vReflect = f0 + (1-f0) * pow(
				(1 - dot(worldViewDir,swelledNormal)),
			 _FenelPower);
			vReflect = saturate(vReflect * 2.0);

			col = lerp(col , reflectionColor , vReflect);

			float alpha = saturate(volmeZ);
			
  			col.a = alpha;

			return col;
		}


		half4 frag2(v2f i) : SV_Target
		{
			i.projPos.xy /= i.projPos.w;
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.projPos.xy);
			
			float sceneZ = LinearEyeDepth(depth,_ZBufferParams);
			
			half4 col = half4(1,1,1,1);
			col.xyz *= sceneZ * 0.1;
			return col;
		}
		ENDHLSL
		
		Pass
		{
			Tags { "RenderType"="Opaque" "RenderPipLine" = "UniversalPipeline"}
			Blend SrcAlpha OneMinusSrcAlpha 
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			
			ENDHLSL
		}
	}
}
