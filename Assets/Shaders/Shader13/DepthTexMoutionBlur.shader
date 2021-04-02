Shader "SEEDzy/Unity Shaders Book/Chapter 13/DepthTexMoutionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        
        sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		//sampler2D _CameraDepthTexture;
		float4x4 _CurrentViewProjectionInverseMatrix;
		float4x4 _PreviousViewProjectionMatrix;
		half _BlurSize;


        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float2 uv_Depth : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float2 uv_Depth : TEXCOORD1;
            float4 vertex : SV_POSITION;
        };


        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            o.uv_Depth = v.uv_Depth;

        	#if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0)
            {
            	//只是y轴方向相反
                o.uv_Depth.y = 1 - o.uv_Depth.y;
            }
            #endif
            
            
            return o;
        }
        
        //获取摄像机深度纹理，变量名不能错啊！！！！！
        UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
        fixed4 frag (v2f i) : SV_Target
        {
            //从深度纹理采样深度值
            float h = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_Depth);
            //通过UV坐标和深度值构建ndc空间下坐标
            half4 ndcPos = half4(i.uv_Depth.x * 2 - 1,i.uv_Depth.y * 2 - 1, h * 2 - 1, 1);
            //这两步是计算该点的世界坐标空间坐标，先用vp逆矩阵转换，再除以其w值，详细推导看笔记吧。
            float4 temPos = mul(_CurrentViewProjectionInverseMatrix,ndcPos);
            float4 worldPos = temPos/temPos.w;

            //现在计算该点上一帧时的proj位置,用上一帧的vp矩阵对该点wpos进行转换
            float4 previousProjPos = mul(_PreviousViewProjectionMatrix,worldPos);
            //齐次除法转ndc
            half4 preNdcPos = previousProjPos/previousProjPos.w;

            // 用两帧间距离差计算该像素速度
			float2 velocity = (ndcPos.xy - preNdcPos.xy)/2.0f;
			
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
        	//速度是矢量，取了速度方向上的三个点颜色求平均来得到当前点颜色
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
        }
        
        

        ENDCG
        
        Pass 
    	{      
			ZTest Always Cull Off ZWrite Off
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
    }
	FallBack off
}
