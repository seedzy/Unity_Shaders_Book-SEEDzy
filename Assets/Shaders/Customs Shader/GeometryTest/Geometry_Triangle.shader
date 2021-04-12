Shader "SEEDzy/Custom/Geometry_Triangle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GrassCol("三角形颜色", Color) = (1,1,1,1)
        _GrassHei("三角形高度", float) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GrassHei;
            fixed4 _GrassCol;


            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed4 color : TEXCOORD1;
            };



            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            //设置单次操作最大顶点输出数，尽量低于20
            [maxvertexcount(3)]
            void geom(line v2g input[2],inout TriangleStream<g2f> triStream)
            {
                //第一个point指出输入数据以点为单位，也可使用triangle&line
                //inout Pointstream指出输出的数据类型，也可使用triangleStream&lineStream
                g2f o;
                //新构成的三角形顶端应在两点中点法线方向的线上
                float4 tipPos = (input[0].vertex + input[1].vertex)/2;
                float3 tipNormal = normalize(input[0].normal + input[1].normal);

                //传入三角形顶端数据
                o.uv = (input[0].uv + input[1].uv)/2;
                o.vertex = float4(tipPos.xyz + tipNormal * _GrassHei,tipPos.w);
                o.vertex = UnityObjectToClipPos(o.vertex);
                o.color = _GrassCol;
                triStream.Append(o);

                //传入其余两点
                for(int i = 0; i<2; i++)
                {
                    o.uv = input[i].uv;
                    o.vertex = UnityObjectToClipPos(input[i].vertex);
                    o.color = fixed4(1,1,1,1);
                    triStream.Append(o);
                }

                //构建三角
                triStream.RestartStrip();     
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                col = col * i.color;
                return col;
            }
            ENDCG
        }
    }
}
