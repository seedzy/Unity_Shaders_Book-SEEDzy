Shader "Unity Shaders Book/Chapter 8/SEEDzy/Alpha BlendZWrite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaScale ("Alpha Scale",Range(0,1)) = 0.5
        _Color ("Main Tint", Color) = (1,1,1,1)
        
        
    }
    SubShader
    {
        //renderType：? ignoreProjector：当前shader不会受到投影器影响(Projectors)
        //通常使用透明度测试都应使用这三个标签
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True"}
        LOD 100
        //该pass写入模型深度信息
        Pass
        {
            ZWrite On
            //设置颜色通道谢掩码
            ColorMask 0
        }
        
        
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Zwrite Off
            //Cull Off 
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;
            fixed4 _Color;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //模型空间顶点法线转世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //纹理偏移缩放
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //顶点模型空间坐标转世界
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldNormal = normalize(i.worldNormal);
                //获得世界空间坐标点到光源处方向
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // sample the texture
                fixed4 texcol = tex2D(_MainTex, i.uv);

                //材质反射率反射率？
                fixed3 albedo = texcol.rgb * _Color;
                
                fixed3 ambient = albedo * UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 diffuse = _LightColor0 * saturate(dot(worldLightDir,worldNormal)) * albedo;
                
                return fixed4(ambient + diffuse,texcol.a * _AlphaScale);
                
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
