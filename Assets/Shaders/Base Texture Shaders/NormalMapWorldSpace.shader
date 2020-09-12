Shader"BaseTexture/NormalMapWorldSpace"{
    Properties{        
        _Color ("Color Tint" , Color) = (1,1,1,1)
        _MainTex ("Main Tex" , 2D) = "white" {}
        // "bump"是unity内置的发现纹理，当没有提供任何法显纹理时，"bump"就对应了模型自带的法线信息
        _BumpMap ("NroMal Map" , 2D) = "bump" {}
        _BumpScale ("Bump Scale" , float) = 1.0
        _Specular ("Specular" , Color) = (1,1,1,1)
        _Gloss ("Gloss" , Range (8.0 , 256)) = 20
    }
    SubShader{
        Pass{
            Tags{
                "LightMode" = "ForwardBase"    
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color ;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //tangent类型是float4，因为w分量用来决定切线空间中的第三个坐标轴-副切线的方向性
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;                
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };
            
            // 在定点着色器中计算从切线空间到世界空间的变换矩阵
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                
                float3 worldPos = mul(unity_ObjectToWorld , v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;
                
                // 变换矩阵的计算可有定点的切线，副切线和法线在世界空间下的表示来得到
                o.TtoW0 = float4(worldTangent.x , worldBinormal.x , worldNormal.x , worldPos.x);
                o.TtoW1 = float4(worldTangent.y , worldBinormal.y , worldNormal.y , worldPos.y);
                o.TtoW2 = float4(worldTangent.z , worldBinormal.z , worldNormal.z , worldPos.z);
                
                return o;
            }
            
            fixed4 frag(v2f i):SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w , i.TtoW1.w , i.TtoW2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                
                // 获取切线空间下的法线
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1 - saturate(dot(bump.xy , bump.xy)));
                // 将法线从切线空间转到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz , bump),dot(i.TtoW1.xyz , bump),dot(i.TtoW2.xyz , bump)));
                
                fixed3 albedo = tex2D(_MainTex,i.uv.xy) * _Color;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.xyz * albedo * max(0 , dot(lightDir,bump));
                
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.xyz * _Specular.xyz * pow(max(0,dot( halfDir , bump)),_Gloss);
                
                return fixed4(ambient + diffuse + specular,1);
            }
            ENDCG
        }
    }
}