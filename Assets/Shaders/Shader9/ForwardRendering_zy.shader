Shader "Unity Shaders Book/Chapter 9/SEEDzy/ForwardRendering"
{
    Properties
    {
        _Color("Diffuse Color",Color) = (1,1,1,1)
        _Specular("Specular Color",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8,256)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };


            fixed3 _Color;
            fixed3 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 worldNormalDir = normalize(i.worldNormal);

                fixed3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                fixed3 halfNormalDir = normalize(worldLightDir + viewDir);

                fixed3 diffuse = _Color * _LightColor0 * saturate(dot(worldLightDir,worldNormalDir));

                fixed3 specular = _Specular * _LightColor0 *pow(saturate(dot(halfNormalDir,worldNormalDir)),_Gloss);
                //光照有颜色、强度、衰减、方向、位置五个属性

                //平行光照无衰减，设置为1
                fixed atten = 1.0;
                
                return fixed4(ambient + (diffuse + specular) * atten,1);
            }
            ENDCG
        }
        
        Pass
        {
            Tags {"LightMode" = "ForwardAdd"}
            
            Blend One One
            
            CGPROGRAM
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityDeferredLibrary.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };


            fixed3 _Color;
            fixed3 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //根据光源类型决定光照方向，平行光可直接获得，但点光源、聚光灯等需要计算位置
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                #endif


                fixed3 worldNormalDir = normalize(i.worldNormal);

                fixed3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                fixed3 halfNormalDir = normalize(worldLightDir + viewDir);

                fixed3 diffuse = _Color * _LightColor0 * saturate(dot(worldLightDir,worldNormalDir));

                fixed3 specular = _Specular * _LightColor0 *pow(saturate(dot(halfNormalDir,worldNormalDir)),_Gloss);
                //光照有颜色、强度、衰减、方向、位置五个属性

                //根据光源类型决定光照衰减，平行光无衰减直接设置为1，但点光源、聚光灯等需要计算衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif

                
                return fixed4((diffuse + specular) * atten,1);
            }
            


            
            ENDCG
        }
        
    }
    FallBack "Specular"
}
