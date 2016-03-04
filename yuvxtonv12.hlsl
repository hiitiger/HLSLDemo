Texture2D image;

uniform float o_width;
uniform float o_height;

uniform float o_width_i;
uniform float o_height_i;

uniform float c_width;
uniform float c_height;

uniform float c_width_i;
uniform float c_height_i;

SamplerState samplerDef{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

struct VertexIn {
    float3 PosNdc : POSITION;
    float2 Tex : TEXCOORD;
};

struct VertexOut {
    float4 PosNdc : SV_POSITION;
    float2 Tex : TEXCOORD;
};

VertexOut VShader(VertexIn vin) {
    VertexOut vout;
    vout.PosNdc = float4(vin.PosNdc, 1.0f);
    vout.Tex = vin.Tex;
    return vout;
};

//input yuv444 width * height
//output nv12 (width/4) * (height*1.5)
float4 PShaderNV12(VertexOut pin) : SV_Target{

    float y = floor(pin.Tex.y * o_height + 0.1);
    float x = floor(pin.Tex.x * o_width + 0.1);

    if(y<o_height) // y
    {
        x  = x * 4.0;
        x += 0.5;
        y += 0.5;

        float2 samplepos0 = float2((x) * o_width_i, y * o_height_i);
        float2 samplepos1 = float2((x + 1.0) * o_width_i, y * o_height_i);
        float2 samplepos2 = float2((x + 2.0) * o_width_i, y * o_height_i);
        float2 samplepos3 = float2((x + 3.0) * o_width_i, y * o_height_i);

        float4 colorpos0 = image.Sample(samplerDef, samplepos0);
        float4 colorpos1 = image.Sample(samplerDef, samplepos1);
        float4 colorpos2 = image.Sample(samplerDef, samplepos2);
        float4 colorpos3 = image.Sample(samplerDef, samplepos3);

        return float4(colorpos0.r, colorpos1.r, colorpos2.r, colorpos3.r);
    }
    else
    {
        x  = x * 4.0;
        y = floor(y - o_height  + 0.1) * 2.0;

        x += 1.0;
        y += 1.0;
         
        float2 samplepos0 = float2((x) * o_width_i, y * o_height_i);
        float2 samplepos1 = float2((x + 2.0) * o_width_i, y * o_height_i);
 
        float4 colorpos0 = image.Sample(samplerDef, samplepos0);
        float4 colorpos1 = image.Sample(samplerDef, samplepos1);

        return float4(colorpos0.g, colorpos0.b, colorpos1.g, colorpos1.b);
    }

};

technique11 DrawNV12 {
pass P0{
    SetVertexShader(CompileShader(vs_5_0, VShader()));
    SetPixelShader(CompileShader(ps_5_0, PShaderYUV420()));
    }
}