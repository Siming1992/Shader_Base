// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//C_diffuse = (C_light * M_diffuse) max(0,n*l)      

Shader"BaseLight/DiffuseVertexLevel"
{
    Properties{
        _Diffuse ("Diffuse",Color) = (1,1,1,1)
    }
    SubShader{
        Pass{
            Tags{
                "LightMode" = "ForwardBase"     //只有定义了正确的lightmode，才能得到unity的内置光照变量，比如_LightColor0
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            fixed4 _Diffuse;
            struct a2v {
                float4 vertex : POSITION;   //模型坐标
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;   //裁剪坐标
                fixed3 color : COLOR;
            };
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //UNITY_LIGHTMODEL_AMBIENT 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //计算发现和光源方向之间的点积时，需要两者处于统一坐标空间下才有意义，在这里选择世界坐标
                //使用顶点变换矩阵的逆转置矩阵对发现进行相同的变换，模型空间到世界空间的变换矩阵的逆矩阵 unity_WorldToObject
                //通过调换mul函数中的位置，得到和转置矩阵相同的矩阵乘法，法线是三维矢量
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //unity提供给我们一个内置变量——LightColor0来访问该pass处光源的颜色和强度信息，（想要得到正确的值需要定义合适的LightMode标签）
                //光源方向的计算并不具有通用性，这里我们假设场景中只有一个光源且是平行光，但如果是多个光源或者类型是点光源等，直接使用__WorldSpaceLightPos0就不能得到正确结果了
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));
				//环境光和漫反射相加，得到最终光照效果
                o.color = ambient + diffuse;
                return o;
            }
            fixed4 frag(v2f i):SV_Target{
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
}