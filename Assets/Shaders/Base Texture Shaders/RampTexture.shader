
// 用渐变纹理来控制漫反射的结果，可以使我们更新加灵活的控制光照结果

Shader"BaseTexture/Ramp Texture"{
    Properties{
        _Color ("Color Tint" , Color) = (1,1,1,1)
        _RampTex ("Ramp Tex" , 2D) = "white"{}
        _Specular ("Specular" , Color) = (1,1,1,1)
        _Gloss ("Gloss" , Range (8.0 , 256)) = 20   
    }
    Subshader{
        Pass{
            Tags{
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #include "Lighting.cginc"
            
            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord :TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv :TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord , _RampTex);
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed halfLambert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;
                // 我们得到的 halfLambert 的范围被映射到了[1,0]之间，然后使用 halfLambert 来构建一个纹理坐标，并用这个纹理坐标对_RampTex进行采样
                // 由于 _RampTex 实际就是一个一维纹理（纵轴上颜色不变），银子纹理坐标的u和v都使用了 halfLambert
                fixed3 diffuseColor = tex2D(_RampTex , fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;
                
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(viewDir + worldLightDir);
                fixed3 specular = _LightColor0.rgb * _Specular * pow(max(0,dot(worldNormal,halfDir)) , _Gloss);
                
                return fixed4(ambient + diffuse + specular , 1.0);
            }
            ENDCG
        }
    }
}