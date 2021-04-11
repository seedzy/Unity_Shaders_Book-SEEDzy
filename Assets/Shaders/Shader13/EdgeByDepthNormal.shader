Shader "SEEDzy/Unity Shaders Book/Chapter 13/EdgeByDepthNormal"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
		_Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
    }
    
    SubShader
    {
        CGINCLUDE
        
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;
		
		sampler2D _CameraDepthNormalsTexture;

		struct a2v
		{
			float4 vert : POSITION;
			float2 uv[5] : TEXCOORD;
		}

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv[5] : TEXCOORD0;
		}

		v2f vert(a2v v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vert);

			o.uv[5] = v.uv[5];

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			fixed4 sample1 = tex2D(_MainTex,uv[1]);
			fixed4 sample2 = tex2D(_MainTex,uv[2]);
			fixed4 sample3 = tex2D(_MainTex,uv[3]);
			fixed4 sample4 = tex2D(_MainTex,uv[4]);

			fixed edge = 1;

		}

		fixed CheckNum(fixed4 top,fixed4 buttom)
		{
			half2 topNormal = top.xy;
			float topDepth = DecodeFloatRG(buttom.zw);
			half2 buttomNormal = buttom.xy;
			float buttomDepth = DecodeFloatRG(buttom.zw)

			float diffNormal = abs(topNormal - buttomNormal) * _Sensitivity.x;
			
		}

        
        ENDCG
    }
    
}
