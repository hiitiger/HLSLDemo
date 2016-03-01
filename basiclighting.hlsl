
struct Material
{
    float4	ambient;
    float4	diffuse;
    float4	specular;	//specular中第4个元素代表材质的表面光滑程度
};

struct DirLight
{
    float4	ambient;
    float4	diffuse;
    float4	specular;

    float3	dir;
    float	unused;
};


struct PointLight
{
    float4 ambient;
    float4 diffuse;
    float4 specular;

    float3 position;
    float range;

    float3 att; //attenuation (a0, a1, a2)
    float pad;
};


void ComputeDirLight(Material material, DirLight dirLight, float3 normal, float3 viewDirection,
    out float4 ambient, out float4 diffuse, out float4 specular)
{

    ambient = float4(0.0f, 0.0f, 0.f, 0.f);
    diffuse = float4(0.f, 0.f, 0.f, 0.f);
    specular = float4(0.f, 0.f, 0.f, 0.f);

    ambient = material.ambient * dirLight.ambient;

    float3 lightDir = -dirLight.dir;

    float lightIntensity = saturate(dot(normal, lightDir));

    if (lightIntensity > 0)
    {
        diffuse = saturate(material.diffuse * dirLight.diffuse * lightIntensity);

        float3 reflection = reflect(dirLight.dir, normal);

        float specFactor = pow(max(saturate(dot(reflection, viewDirection)), 0.f), material.specular.w);

        specular = material.specular * dirLight.specular * specFactor;
    }
}

void ComputePointLight(Material material, PointLight pointLight, float3 pos, float3 normal, float3 viewDirection,
    out float4 ambient, out float4 diffuse, out float4 specular)
{
    ambient = float4(0.0f, 0.0f, 0.f, 0.f);
    diffuse = float4(0.f, 0.f, 0.f, 0.f);
    specular = float4(0.f, 0.f, 0.f, 0.f);

    float3 lightDir = pointLight.position - pos;

    float d = length(lightDir);
    if( d > pointLight.range )
        return;

    ambient = material.ambient * pointLight.ambient;
    
     // Normalize the light vector.
    lightDir /= d; 

    float diffuseFactor = saturate(dot(normal, lightDir));

    if (diffuseFactor > 0)
    {
        diffuse = saturate(material.diffuse * pointLight.diffuse * diffuseFactor);

        float3 reflection = reflect(-lightDir, normal);

        float specFactor = pow(max(saturate(dot(reflection, viewDirection)), 0.f), material.specular.w);

        specular = material.specular * pointLight.specular * specFactor;
    }

    float att = 1.0f / dot(pointLight.att, float3(1.0f, d, d*d));
 
    diffuse *= att;
    specular *= att;
}


cbuffer MatrixBuffer
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

cbuffer cbPerFrame
{
    DirLight gDirLight;
    PointLight gPointLight;
    float3 cameraPosition;
};

cbuffer cbPerObject
{
    Material gMaterial;
};

struct VertexInputType
{
    float4 position : POSITION;
    float3 normal : NORMAL;

};

struct PixelInputType
{
    float4 position : SV_POSITION;
    float4 worldposition: POSITION;
    float3 normal : NORMAL;
};
////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType LightVertexShader(VertexInputType input)
{
    PixelInputType output;

    // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;

    // Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);

    // Calculate the normal vector against the world matrix only.
    output.normal = mul(input.normal, (float3x3)worldMatrix);

    //保存世界坐标位置来计算视角
    output.worldposition = mul(input.position, worldMatrix);

    return output;
}

float4 LightPixelShader(PixelInputType input) : SV_TARGET
{
    float4 color;

    float4 ambient = { 0.f, 0.f, 0.f, 0.f };
    float4 diffuse = { 0.f, 0.f, 0.f, 0.f };
    float4 specular = { 0.f, 0.f, 0.f, 0.f };

    float3 viewDirection;

    input.normal = normalize(input.normal);

    // Determine the viewing direction based on the position of the camera and the position of the vertex in the world.
    viewDirection = cameraPosition.xyz - input.worldposition.xyz;

    // Normalize the viewing direction vector.
    viewDirection = normalize(viewDirection);

    ComputeDirLight(gMaterial, gDirLight, input.normal, viewDirection, ambient, diffuse, specular);

    color = saturate(ambient + diffuse + specular);

    ComputePointLight(gMaterial, gPointLight, input.worldposition.xyz, input.normal, viewDirection, ambient, diffuse, specular);
    
    color = saturate(color + (ambient + diffuse + specular));
    
    color.a = gMaterial.diffuse.a;

    return color;
}


technique11 LightingDraw3
{
    Pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, LightVertexShader()));
        SetPixelShader(CompileShader(ps_5_0, LightPixelShader()));
    }
}
