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

//input yuv444 o_width * o_height
//output yuv420p (o_width/4) * (o_height*1.5)

float4 PShaderYUV420P(VertexOut pin) : SV_Target{

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
    else if (y < o_height * 1.25) //u
    {
        y = floor(y - o_height + 0.1);

        //calc as w * (h_d2)
        float pixel_offset = floor(y * o_width * 2 + x * 8.0) + 0.1;

        //map to original (x,y)
        y = floor(pixel_offset * o_width_i * 2.0);
        x = floor(fmod(pixel_offset, o_width));

        
        //move to center of pixel
       // x += 0.5;
       // y += 0.5;

        //move to center of 4 pixels
        x += 1.0;
        y += 1.0;


        float2 samplepos0 = float2(x * o_width_i, y * o_height_i);
        float2 samplepos1 = float2((x + 2.0) * o_width_i, y * o_height_i);
      
        if(x + 4.0 > o_width)
        {
            //move to center of pixel
          // x = 0.5;
            
           //move to center of 4 pixels
            x = 1.0;

            y += 2.0;
        }
        else
        {
            x += 4.0;
        }
        float2 samplepos2 = float2(x * o_width_i, y * o_height_i);
        float2 samplepos3 = float2((x + 2.0) * o_width_i, y * o_height_i);

        float4 colorpos0 = image.Sample(samplerDef, samplepos0);
        float4 colorpos1 = image.Sample(samplerDef, samplepos1);
        float4 colorpos2 = image.Sample(samplerDef, samplepos2);
        float4 colorpos3 = image.Sample(samplerDef, samplepos3);

        return float4(colorpos0.g, colorpos1.g, colorpos2.g, colorpos3.g);
    }
    else//v
    {
        y = floor(y - o_height * 1.25 + 0.1);

        //calc as w * (h_d2)

        float pixel_offset = floor(y * o_width * 2.0 + x * 8.0) + 0.1;

        //map to original (x,y)
        y = floor(pixel_offset / o_width * 2.0);
        x = floor(fmod(pixel_offset, o_width));

        //move to center of pixel
       // x += 0.5;
       // y += 0.5;
       // y += 1.0;


        //move to center of 4 pixels
        x += 1.0;
        y += 1.0;
         
         
        float2 samplepos0 = float2(x * o_width_i, y * o_height_i);
        float2 samplepos1 = float2((x + 2.0) * o_width_i, y * o_height_i);
      
        if(x + 4.0 > o_width)
        {
             //move to center of pixel
           // x = 0.5;
            
            //move to center of 4 pixels
            x = 1.0;

            y += 2.0;
        }
        else
        {
            x += 4.0;
        }
        float2 samplepos2 = float2(x * o_width_i, y * o_height_i);
        float2 samplepos3 = float2((x + 2.0) * o_width_i, y * o_height_i);

        float4 colorpos0 = image.Sample(samplerDef, samplepos0);
        float4 colorpos1 = image.Sample(samplerDef, samplepos1);
        float4 colorpos2 = image.Sample(samplerDef, samplepos2);
        float4 colorpos3 = image.Sample(samplerDef, samplepos3);

        return float4(colorpos0.b, colorpos1.b, colorpos2.b, colorpos3.b);
    }

};

technique11 DrawPlanarYUV420 {
pass P0{
    SetVertexShader(CompileShader(vs_5_0, VShader()));
    SetPixelShader(CompileShader(ps_5_0, PShaderYUV420P()));
    }
}