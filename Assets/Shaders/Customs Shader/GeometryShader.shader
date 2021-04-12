Shader "SEEDzy/Custom/GeometryShader/分解" { 
    Properties { 
        _MainTex("Texture", 2D) = "white" {} 
        _Height("Length", float) = 0.5 
        _Offset("Offset", float) = 0.1 
 
        _StripColor("StripColor", Color) = (1, 1, 1, 1) 
        _OutColor("OutColor", Color) = (1, 1, 1, 1) 
        _InColor("InColor", Color) = (1, 1, 1, 1) 
    } 
    SubShader { 
        Cull off 
        Pass { 
            Tags {"RenderType" = "Opaque"} 
 
            CGPROGRAM
            # pragma vertex vert
            # pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata { 
                float4 vertex: POSITION; 
                float2 uv: TEXCOORD0; 
            }; 
 
            struct v2f { 
                float4 vertex: SV_POSITION; 
                float4 objPos: TEXCOORD1; 
                float2 uv: TEXCOORD0; 
            }; 
 
            sampler2D _MainTex; 
            float4 _MainTex_ST; 
            float _Height; 
            float _Offset; 
            fixed4 _StripColor; 
 
            v2f vert(appdata v) { 
                v2f o; 
                o.vertex = UnityObjectToClipPos(v.vertex); 
                o.objPos = v.vertex; 
                o.uv = v.uv; 
                return o; 
            } 
 
            fixed4 frag(v2f i): SV_Target { 
                fixed4 col = tex2D(_MainTex, i.uv); 
 
                clip(_Height + _Offset - i.objPos.y); 
 
                if (i.objPos.y > _Height) 
                    col = _StripColor; 
 
                return col; 
            } 
            ENDCG 
        } 
 
        pass { 
            Tags { 
                "RenderType" = "Opaque" 
            } 
 
            CGPROGRAM
            # pragma vertex vert
            # pragma geometry geome
            # pragma fragment frag
            #include "UnityCG.cginc" 
 
            fixed4 _OutColor; 
            fixed4 _InColor; 
            float _Height; 
            float _Offset; 
 
            struct appdata { 
                float4 vertex: POSITION; 
                float2 uv: TEXCOORD0; 
                float3 normal: NORMAL; 
            }; 
 
            struct v2g { 
                float4 objPos: TEXCOORD0; 
                float3 normal: NORMAL; 
            }; 
 
            struct g2f { 
                float4 vertex: SV_POSITION; 
                fixed4 col: TEXCOORD0; 
            }; 
 
            void ADD_VERT(float4 v, g2f o, inout PointStream < g2f > outstream) { 
                o.vertex = v; 
                outstream.Append(o); 
            } 
 
            v2g vert(appdata v) { 
                v2g o; 
                o.objPos = v.vertex; 
                o.normal = v.normal; 
                return o; 
            } 
 
            [maxvertexcount(6)] 
            void geome(triangle v2g input[3], inout PointStream < g2f > outStream) { 
                g2f o; 
 
                //--------将一个三角面三个顶点的平均位置作为均值 
                float4 vertex = (input[0].objPos + input[1].objPos + input[2].objPos) / 3.0; 
                float3 normal = (input[0].normal + input[1].normal + input[2].normal) / 3.0; 
 
                if (vertex.y < _Height + _Offset) 
                    return; 
 
                //-------以v[0]为原点构建两个向量，用来在后续过程中通过这两个向量来构建三角面中自定义的点 
                float4 s = input[1].objPos - input[0].objPos; 
                float4 t = input[2].objPos - input[0].objPos; 
 
                o.col = _OutColor * 2; 
                for (int i = 0; i < 3; i++) { 
                    input[i].objPos.xyz += input[i].normal * (vertex.y - _Height); 
                    input[i].objPos = UnityObjectToClipPos(input[i].objPos); 
                    ADD_VERT(input[i].objPos, o, outStream); 
                } 
 
                o.col = _InColor * 2; 
 
                //-------通过s,t两个向量构建自定义点 
                float4 v[3]; 
 
                v[0] = 0.2 * s + 0.2 * t; 
                v[1] = 0.4 * s + 0.6 * t; 
                v[2] = 0.6 * s + 0.4 * t; 
 
                for (int i = 0; i < 3; i++) { 
                    v[i].xyz += normal * (vertex.y - _Height); 
                    v[i] = UnityObjectToClipPos(v[i]); 
                    ADD_VERT(v[i], o, outStream); 
                } 
            } 
 
            fixed4 frag(g2f i): SV_Target { 
                fixed4 col = i.col; 
                return col; 
            } 
            ENDCG 
 
        } 
    } 
} 