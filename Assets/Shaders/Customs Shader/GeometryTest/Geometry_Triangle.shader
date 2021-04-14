Shader "SEEDzy/Custom/Geometry_Triangle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GrassCol("三角形颜色", Color) = (1,1,1,1)
        _GrassHei("三角形高度", float) = 1
        _GroundCol("平面颜色", Color) = (1,1,1,1)
        _Offset("测试", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GrassHei;
            fixed4 _GrassCol;
            fixed4 _GroundCol;
            float _Offset;


            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                //float4 worldPos : TEXCOORD2;
                float4 tangent : TEXCOORD3;
            };

            struct g2f
            {
                //float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed4 color : TEXCOORD1;
                //float4 worldPos : TEXCOORD2;
                //float3 normal : TEXCOORD3;
            };



            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }



            g2f PerTriangle(float3 pos)
            {
                g2f o;
                o.vertex = UnityObjectToClipPos(pos);
                o.color = _GrassCol;
                //o.uv = 
                return  o;
            }
            
            //设置单次操作最大顶点输出数，尽量低于20
            [maxvertexcount(12)]
            void geom(triangle v2g input[3],inout TriangleStream<g2f> triStream)
            {
                float3 bnormal = cross(input[0].normal,input[0].tangent) * input[0].tangent.w;

                //切线空间转模型
                float3x3 tangentToObject =
                float3x3(
                    input[0].tangent.x, bnormal.x, input[0].normal.x,
                    input[0].tangent.y, bnormal.y, input[0].normal.y,
                    input[0].tangent.z, bnormal.z, input[0].normal.z
                );

                triStream.Append(PerTriangle(input[0].vertex + mul(tangentToObject, float3(_Offset,0,0))));
                triStream.Append(PerTriangle(input[0].vertex + mul(tangentToObject, float3(-_Offset,0,0))));
                triStream.Append(PerTriangle(input[0].vertex + mul(tangentToObject, float3(0,0,_GrassHei))));
                
                //第一个point指出输入数据以点为单位，也可使用triangle&line
                //inout Pointstream指出输出的数据类型，也可使用triangleStream&lineStream
                g2f o;
                
                //传入平面三角
                // for(uint j = 0; j < 3; j++)
                // {
                //     //o.uv = input[j].uv;
                //     o.vertex = UnityObjectToClipPos(input[j].vertex);
                //     o.color = _GroundCol;
                //     //o.worldPos = input[j].worldPos;
                //     //o.normal = input[j].normal;
                //     triStream.Append(o);
                // }
                
            }

            fixed4 frag (g2f i) : SV_Target
            {
                //float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                //float3 worldNormalDir = normalize(UnityObjectToWorldNormal(i.normal));

                //fixed3 diff = (dot(worldLightDir,worldNormalDir) * 0.5 + 0.5) * _LightColor0;
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);

                //col = fixed4(col.rgb * i.color.rgb * diff,1);
                return i.color;
            }
            ENDCG
        }
    }
}
