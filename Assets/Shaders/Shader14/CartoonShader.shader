Shader "SEEDzy/Unity Shaders Book/Chapter 14/CartoonShader"
{
    Properties 
    {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_Outline ("Outline", Range(0, 1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01
	}
    SubShader
    {

        Pass
        {
            NAME "OUTLINE"
        	Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            half _Outline;
            fixed4 _OutlineColor;

            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };



            v2f vert (appdata v)
            {
                v2f o;
                //Obj 2 View
                o.pos = mul(UNITY_MATRIX_MV, v.vertex);
                //normal obj 2 view 通过 mv逆转置矩阵
                float3 vNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                vNormal = normalize(float3(vNormal.xy, -0.5));
                o.pos = o.pos + float4(vNormal * _Outline, 0);

                o.pos = mul(UNITY_MATRIX_P, o.pos);
                
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(_OutlineColor.rgb, 1); 
            }
            ENDCG
        }
        
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
			
			Cull Back
		
			CGPROGRAM
		
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _Specular;
			float _SpecularScale;
			sampler2D _Ramp;

			struct appdata
            {
                float4 vertex : POSITION;
				float2 uv : TEXCOORD;
                float3 normal : NORMAL;
				//float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD0;
            	float3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
            };

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half3 worldNormalDir = normalize(i.worldNormal);
				half3 worldLightDir = normalize(WorldSpaceLightDir(i.worldPos));
				half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
				
				fixed4 c = tex2D (_MainTex, i.uv);
				fixed3 albedo = c.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				fixed diff =  dot(worldNormalDir, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;
				
				fixed spec = dot(worldNormalDir, worldHalfDir);
				fixed w = fwidth(spec) * 2.0;
				fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
				
				return fixed4(ambient + diffuse + specular, 1.0);
				

				
			}
			
			ENDCG
        }
    }
	FallBack "Diffuse"
}
