Shader "SEEDzy/Unity Shaders Book/Chapter 12/MotionBlur"
{
    Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurAmount ("Blur Amount", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		fixed _BlurAmount;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}
		
		fixed4 fragRGB (v2f i) : SV_Target {
			return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
		}
		
		half4 fragA (v2f i) : SV_Target {
			return tex2D(_MainTex, i.uv);
		}
		// half4 fragA (v2f i) : SV_Target {
		// 	fixed4 col =  tex2D(_MainTex, i.uv);
		// 	return fixed4(col.a,col.a,col.a,_BlurAmount);
		// }
		
		ENDCG
		
		ZTest on Cull off ZWrite off
		
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment fragRGB  
			
			ENDCG
		}
		
		Pass {   
			//Blend SrcAlpha OneMinusSrcAlpha
			Blend One Zero
			//Blend Zero one
			ColorMask A
			   	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragA
			  
			ENDCG
		}
	}
 	FallBack Off
}
