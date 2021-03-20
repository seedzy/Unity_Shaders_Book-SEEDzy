Shader "SEEDzy/Unity Shaders Book/Chapter 12/GaussianBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("Blur Size",Float) = 1
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        //存储纹素值，即一个像素的大小
        half4 _MainTex_TexelSize;
		float _BlurSize;
        
        struct a2v
        {
            float4 vertex : POSITION;
            half2 texcoord : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };

        //垂直滤波
        v2f vertBlurVertical(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = uv + half2(0, 1 * _MainTex_TexelSize.y * _BlurSize);
            o.uv[2] = uv + half2(0,-1 * _MainTex_TexelSize.y * _BlurSize);
            o.uv[3] = uv + half2(0, 2 * _MainTex_TexelSize.y * _BlurSize);
            o.uv[4] = uv + half2(0,-2 * _MainTex_TexelSize.y * _BlurSize);
            return o;
        }

        //水平滤波
        v2f vertBlurHorizental(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = uv + half2(1 * _MainTex_TexelSize.x * _BlurSize, 0);
            o.uv[2] = uv + half2(-1 * _MainTex_TexelSize.x * _BlurSize,0);
            o.uv[3] = uv + half2( 2 * _MainTex_TexelSize.x * _BlurSize,0);
            o.uv[4] = uv + half2(-2 * _MainTex_TexelSize.x * _BlurSize,0);
            return o;
        }

        fixed4 fragBlur(v2f j) : SV_Target
        {
            half weight[3] = {0.4026, 0.2442, 0.0545};
            fixed4 color = tex2D(_MainTex,j.uv[0]) * weight[0];
            //啊这。。weight[0]就没用呗----草率了。。。
            for(int i = 1; i < 3; i++)
            {
                color.rgb += tex2D(_MainTex,j.uv[i * 2 -1]).rgb * weight[i];
                color.rgb += tex2D(_MainTex,j.uv[i * 2]).rgb * weight[i];
               
            }
            return fixed4(color.rgb,1);
        }
            
        ENDCG
        
        
        ZTest Always Cull Off ZWrite Off
        
        pass
        {
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDCG
        }
        
        pass
        {
            CGPROGRAM
            #pragma vertex vertBlurHorizental
            #pragma fragment fragBlur
            ENDCG
        }
    }
}
