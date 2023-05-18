Shader "Unlit/ProximityGridShader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _GridFrequency("Grid Frequency", Float) = 1
        _GridRamp("Grid Ramp", Float) = 1
        _DistanceFalloff("Distance Falloff", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 norm : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 objPos : TEXCOORD1;
                float3 norm : NORMAL;
                float3 viewDir : VIEWDIR;
            };

            float4 _Color;
            float _GridFrequency;
            float _GridRamp;
            float _DistanceFalloff;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex;
                o.uv = v.uv;
                o.norm = v.norm;
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float GetGrid(float2 uv, float frequency, float ramp)
            {
                float2 gridBase = (uv * frequency) % 1;
                gridBase = abs(abs(gridBase) - .5) * 2;
                gridBase = pow(gridBase, ramp);
                gridBase = saturate(gridBase);

                half grid = sqrt(gridBase.x + gridBase.y);
                return grid;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //i.viewDir = normalize(i.viewDir);
                float distance = i.vertex.w;

                float gridA = GetGrid(i.uv, _GridFrequency, _GridRamp);
                gridA *= 1 - distance * _DistanceFalloff;
                gridA = saturate(gridA);
                float gridB = GetGrid(i.uv, _GridFrequency * 2, _GridRamp * distance);
                gridB *= 1 - distance * _DistanceFalloff * 2;
                gridB = saturate(gridB);
                float ret = pow((gridA + gridB) * 2, 2);
                ret = saturate(ret);
                ret *= distance;
                return ret * _Color;
            }
            ENDCG
        }
    }
}
