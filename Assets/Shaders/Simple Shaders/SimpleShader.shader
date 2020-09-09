// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"Simple/Simple Shader"
{
    Properties{
        _Color ("Color Tint",Color) = (1,1,1,1)
    }
    SubShader{
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            uniform float4 _Color;
            struct a2v{
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };
            //POSITION 模型坐标   SV_POSITION 裁剪坐标
            v2f vert(a2v v) 
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.normal * 0.5 + fixed3(0.5,0.5,0.5);
                return o;
            }
            //SV_Target 渲染目标（这里是缓存帧）
            fixed4 frag(v2f i):SV_Target{
                fixed3 c = i.color;
                c *= _Color;
                return fixed4(c,1);
            }
            ENDCG
        }
    }
}