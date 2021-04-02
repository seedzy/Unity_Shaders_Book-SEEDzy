Shader "SEEDzy/Unity Shaders Book/Chapter 13/FogWithDepthTex"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
		
		float4x4 _FrustumCornersRay;
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;

        struct a2v
        {
        	float4 vert : POSITION;
	        half2 uv : TEXCOORD0;
        };


        struct v2f
        {
	        half2 uv : TEXCOORD0;
        	half2 uv_Depth : TEXCOORD1;
        	float4 pos : SV_POSITION;
        	float4 interpolatedRay : TEXCOORD2;
        };

        v2f vert(a2v v)
        {
	        v2f o;
        	o.pos = UnityObjectToClipPos(v.vert);
        	//传递UV坐标进行插值
        	o.uv = v.uv;
        	o.uv_Depth = v.uv;

        	#if UNITY_UV_STARTS_AT_TOP
        	if(_MainTex_TexelSize.y < 0)
        		o.uv_Depth.y = 1 - o.uv_Depth.y;
        	#endif

        	fixed index;
        	
        	if (v.uv.x < 0.5 && v.uv.y < 0.5) {
				index = 0;
			} else if (v.uv.x > 0.5 && v.uv.y < 0.5) {
				index = 1;
			} else if (v.uv.x > 0.5 && v.uv.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

        	//处理平台坐标差异，有上面一步再来这步不会出问题吗
        	#if UNITY_UV_STARTS_AT_TOP
        	if(_MainTex_TexelSize.y < 0)
        		index = 3 - index;
        	#endif

        	o.interpolatedRay = _FrustumCornersRay[index];
        	return o;

        }

        //获取摄像机深度纹理，变量名不能错啊！！！！！
        UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
		fixed4 frag(v2f i) : SV_Target
        {
        	fixed3 depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_Depth);

        	//01深度值转观察空间深度
        	float3 lineDepth = LinearEyeDepth(depth);

        	//计算该点相对于摄像机的偏移量
        	float3 offset = lineDepth * i.interpolatedRay.xyz;

        	float3 worldPos = _WorldSpaceCameraPos + offset;

        	fixed4 col = tex2D(_MainTex,i.uv);

        	//雾浓度和世界坐标高度相关，再结合上输入的雾浓度
        	float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			fogDensity = saturate(fogDensity * _FogDensity);

        	fixed3 finCol = lerp(col.xyz,_FogColor,fogDensity);
        	
        	return fixed4(finCol,col.w);
		}

        
        ENDCG
    	
    	Pass {
			ZTest Always Cull Off ZWrite Off
			     	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
    }
	FallBack off
}
