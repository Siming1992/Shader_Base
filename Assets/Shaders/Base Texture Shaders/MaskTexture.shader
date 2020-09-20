
// 遮罩允许我们保护某些区域，使它们免于某些修改

Shader"BaseTexture/MaskTexture"{
    Properties{
        _Color ("Color Tint" , Color) = (1,1,1,1)
        _MainTex ("Main Tex" , 2D) = "white"{}
        _BumpTex ("Bump Tex" , 2D) = "white"{}
        _BumpScale ("BumpScale" , float) = 1.0
        _SpecularMask ( "Specular Mask" , 2D) = "white"{}
        _SpecularScale ( "Specular Scale" , float) = 1.0
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
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord :TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 LightDir : TEXCOORD1;
                float3 viewDir :TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord , _MainTex).xy;
                
                TANGENT_SPACE_ROTATION;
                o.LightDir = mul(rotation , ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation , ObjSpaceViewDir(v.vertex)).xyz;
                
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 tangentLightDir = normalize(i.LightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpTex , i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy , tangentNormal.xy)));
     
                fixed3 albedo = tex2D(_MainTex , i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0 , dot(tangentLightDir , tangentNormal));
                
                float3 halfDir = normalize(tangentLightDir + tangentViewDir);
                //这里使用的纹理每个纹素的rgb分量都是一样的，表明了该点对应的高光反射的的强度，这里我们选择r分量来计算掩码值
                //我们使用的这张遮罩纹理很多空间被浪费了，在实际的游戏制作中，我们往往会充分利用遮罩纹理的每一个颜色同道来存储不同的表面属性
                fixed specularMask = tex2D(_SpecularMask , i.uv).r * _SpecularScale;
                fixed3 specular = _LightColor0 * _Specular.rgb * pow(max(0 , dot(tangentNormal , halfDir)) , _Gloss) * specularMask;
                
                return fixed4(ambient + diffuse + specular , 1.0); //tex2D(_SpecularMask , i.uv) );
            }
            ENDCG
        }
    }
}