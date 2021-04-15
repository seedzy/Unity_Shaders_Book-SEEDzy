Shader "SEEDzy/Custom/Geometry_Triangle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GrassCol("三角形颜色", Color) = (1,1,1,1)
        _GrassButtomCol("三角形底部颜色", Color) = (1,1,1,1)
        _GrassColOffset("三角形颜色偏移",Range(0, 5)) = 1
        
        _GrassHei("三角形高度", float) = 1
        _GrassWid("三角形宽度", Range(0, 1)) = 1
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
            float _GrassWid;
            fixed4 _GrassButtomCol;
            float _GrassColOffset;


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
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 tangent : TEXCOORD3;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD2;
            };



            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }



            g2f PerTriangle(float3 pos,float2 uv)
            {
                g2f o;
                o.vertex = UnityObjectToClipPos(pos);
                o.uv = uv;
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

                triStream.Append(PerTriangle(input[0].vertex + mul(tangentToObject, float3(_GrassWid,0,0)), float2(0,0)));
                triStream.Append(PerTriangle(input[0].vertex + mul(tangentToObject, float3(-_GrassWid,0,0)), float2(1,0)));
                triStream.Append(PerTriangle(input[0].vertex + mul(tangentToObject, float3(0,0,_GrassHei)), float2(0.5,1)));
                triStream.RestartStrip();
            
            }

            fixed4 frag (g2f i) : SV_Target
            {
                float offset = smoothstep(0, _GrassColOffset,i.uv.y);
                fixed3 finCol = offset* _GrassCol + (1 - offset) * _GrassButtomCol;
                return fixed4(finCol.rgb, 1);
            }
            ENDCG
        }
    }
}

