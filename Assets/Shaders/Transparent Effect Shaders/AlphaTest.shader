
// 透明度测试采用一种"霸道极端"的机制，只要一个片元的透明度不满足条件（通常是小于某个阈值），那么它对应的片元就会被舍弃，否则就会按照不透明物体的处理方式来处理它
// 透明度测试是不需要关闭深度写入的，要么完全透明（看不到），要么完全不透明（就想不透明物体那样）

Shader"Transparent Effect/AlphaTest"{
    Properties{
        _Color ("Main Tint" , Color) = (1,1,1,1)
        _MainTex ("Main Tex" , 2D) = "white"{}
        _Cutoff ("Alpha Cutoff" , Range(0,1)) = 0.5
    }
    SubShader{
        Tags{
            "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"
        }
        Pass{
            Tags{
                "LightModle" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            
            #include "Lighting.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o ;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld , v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);    
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed4 texColor = tex2D(_MainTex , i.uv);
                
                clip(texColor.a - _Cutoff);
                
                fixed3 albedo = texColor.rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal , worldLightDir));
                
                return fixed4(ambient + diffuse , 1.0);
            }
            ENDCG
        }
    }
}