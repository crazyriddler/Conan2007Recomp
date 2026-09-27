#define CONAN_RECOMP 1
#ifndef SHADER_COMMON_H_INCLUDED
#define SHADER_COMMON_H_INCLUDED

#define SPEC_CONSTANT_R11G11B10_NORMAL  (1 << 0)
#define SPEC_CONSTANT_ALPHA_TEST        (1 << 1)

#ifdef CONAN_RECOMP
    // Alpha test converted to alpha-to-coverage (foliage antialiasing option).
    #define SPEC_CONSTANT_ALPHA_TO_COVERAGE (1 << 3)
    #define SPEC_CONSTANT_SOFT_PARTICLE_RGBA (1 << 4)
    #define SPEC_CONSTANT_SOFT_PARTICLE_ALPHA (1 << 5)
#endif
#ifdef UNLEASHED_RECOMP
    #define SPEC_CONSTANT_BICUBIC_GI_FILTER (1 << 2)
    #define SPEC_CONSTANT_ALPHA_TO_COVERAGE (1 << 3)
    #define SPEC_CONSTANT_REVERSE_Z         (1 << 4)
#endif

// SPIR-V vertex input locations, shared with reblue's host input-layout
// builder. A semantic missing here gets no location from the emitter.
#define REBLUE_VERTEX_INPUT_LOCATIONS(X) \
    X(Position,  0,  0) \
    X(Position,  1,  1) \
    X(Position,  2,  2) \
    X(Position,  3,  3) \
    X(Position,  4,  4) \
    X(Normal,    0,  5) \
    X(Tangent,   0,  6) \
    X(TexCoord,  0,  7) \
    X(TexCoord,  1,  8) \
    X(TexCoord,  2,  9) \
    X(Color,     0, 10)

// SPEC_CONSTANTS_ONLY keeps the HLSL below out of host C++ TUs, which IntelliSense would otherwise parse.
#if (!defined(__cplusplus) || defined(__INTELLISENSE__)) && !defined(SHADER_COMMON_SPEC_CONSTANTS_ONLY)

#define FLT_MIN asfloat(0xff7fffff)
#define FLT_MAX asfloat(0x7f7fffff)

#ifdef __spirv__

struct PushConstants
{
    uint64_t VertexShaderConstants;
    uint64_t PixelShaderConstants;
    uint64_t SharedConstants;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> g_PushConstants;

#ifdef REBLUE_RECOMP
// 256-bit boolean register file (BD bool addresses reach ~158), then per-usage 16-bit-pair swap masks.
#define g_Booleans(i)              vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 256 + (i)*4)
#define g_SwappedTexcoords         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 288)
#define g_HalfPixelOffset          vk::RawBufferLoad<float2>(g_PushConstants.SharedConstants + 292)
#define g_AlphaThreshold           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 300)
#define g_SwappedNormals           vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 304)
#define g_SwappedBinormals         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 308)
#define g_SwappedTangents          vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 312)
#define g_SwappedBlendWeights      vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 316)
#define g_SwappedPositions         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 320)
#define g_SintTexcoords            vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 324)
#define g_ShadowPcfScale           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 328)
#elif defined(CONAN_RECOMP)
// Conan layout (tools/xenosrecomp/patches): c16-c17 = the 256-bit Xenos bool file
// (VS 0..127, PS 128..255, LSB-first per dword like SHADER_CONSTANT_BOOL_*),
// c18 = misc, c19-c26 = the 32 Xenos loop constants (SHADER_CONSTANT_LOOP_00..31:
// count bits 0-7, start bits 8-15, signed step bits 16-23; VS i0-15 = 0-15,
// PS i0-15 = 16-31).
#define g_Booleans(i)              vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 256 + (i)*4)
#define g_SwappedTexcoords         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 288)
#define g_HalfPixelOffset          vk::RawBufferLoad<float2>(g_PushConstants.SharedConstants + 292)
#define g_AlphaThreshold           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 300)
#define g_LoopConstant(i)          vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 304 + (i)*4)
#define g_ScreenXform              vk::RawBufferLoad<float4>(g_PushConstants.SharedConstants + 432)
#define g_SpecConstantsRuntime     vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 448)
#else
#define g_Booleans                 vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 256)
#define g_SwappedTexcoords         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 260)
#define g_HalfPixelOffset          vk::RawBufferLoad<float2>(g_PushConstants.SharedConstants + 264)
#define g_AlphaThreshold           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 272)
#endif

[[vk::constant_id(0)]] const uint g_SpecConstants = 0;

#define g_SpecConstants() g_SpecConstants

#else

#ifdef REBLUE_RECOMP
#define DEFINE_SHARED_CONSTANTS() \
    uint4 g_BooleansArr[2] : packoffset(c16); \
    uint g_SwappedTexcoords : packoffset(c18.x); \
    float2 g_HalfPixelOffset : packoffset(c18.y); \
    float g_AlphaThreshold : packoffset(c18.w); \
    uint g_SwappedNormals : packoffset(c19.x); \
    uint g_SwappedBinormals : packoffset(c19.y); \
    uint g_SwappedTangents : packoffset(c19.z); \
    uint g_SwappedBlendWeights : packoffset(c19.w); \
    uint g_SwappedPositions : packoffset(c20.x); \
    uint g_SintTexcoords : packoffset(c20.y); \
    float g_ShadowPcfScale : packoffset(c20.z);

#define g_Booleans(i) (g_BooleansArr[(i) / 4][(i) % 4])
#elif defined(CONAN_RECOMP)
#define DEFINE_SHARED_CONSTANTS() \
    uint4 g_BooleansArr[2] : packoffset(c16); \
    uint g_SwappedTexcoords : packoffset(c18.x); \
    float2 g_HalfPixelOffset : packoffset(c18.y); \
    float g_AlphaThreshold : packoffset(c18.w); \
    uint4 g_LoopConstantsArr[8] : packoffset(c19); \
    float4 g_ScreenXform : packoffset(c27);     uint g_SpecConstantsRuntime : packoffset(c28.x); float g_PixelPosScale : packoffset(c28.y); float g_ShadowAtlasTexelScale : packoffset(c28.z); float g_ShadowSoftness : packoffset(c28.w); float2 g_SoftParticleW : packoffset(c29.x); float g_SoftParticleDistance : packoffset(c29.z); float g_SoftParticleTexelScale : packoffset(c29.w); uint g_SoftParticleDepth : packoffset(c30.x);

#define g_Booleans(i) (g_BooleansArr[(i) / 4][(i) % 4])
#define g_LoopConstant(i) (g_LoopConstantsArr[(i) / 4][(i) % 4])
#else
#define DEFINE_SHARED_CONSTANTS() \
    uint g_Booleans : packoffset(c16.x); \
    uint g_SwappedTexcoords : packoffset(c16.y); \
    float2 g_HalfPixelOffset : packoffset(c16.z); \
    float g_AlphaThreshold : packoffset(c17.x);
#endif

uint g_SpecConstants();

#endif

#if defined(REBLUE_RECOMP) || defined(CONAN_RECOMP)
// Test Xenos boolean register N in the unified VS(0..127)/PS(128..255) file.
#define BOOL_BIT(n) ((g_Booleans((n) / 32u) & (1u << ((n) & 31u))) != 0)
#endif

#ifdef CONAN_RECOMP
// xenos::LoopConstant: aL = start + iteration * step.
// Macros take the 32-bit loop constant value: g_LoopConstant(id), or a literal
// from the shader's definition table (defi).
#define LOOP_COUNT(c) ((c) & 0xFFu)
#define LOOP_START(c) int(((c) >> 8) & 0xFFu)
#define LOOP_STEP(c)  (int((c) << 8) >> 24)
#endif

#ifdef CONAN_RECOMP
// Bit 31 of a texture descriptor index = the fetch constant's RGB sign is GAMMA:
// Xenos returns linear values, converted with its piecewise-linear curve
// (xenos::PWLGammaToLinear, applied after filtering like the Xenia/ReXGlue
// Xenos backend).
// Bits 16-27 = host scale of a texture rendered larger than its guest size
// (render_scale resolve targets, 8.8 fixed point, 0 = 1:1): texel offsets and
// filter weights stay in guest texels, like on Xenos. SRV indices use bits 0-14.
#define TEX_INDEX(i) ((i) & 0x7FFFu)
#define TEX_SCALE(i) ((((i) >> 16) & 0xFFFu) ? float(((i) >> 16) & 0xFFFu) / 256.0 : 1.0)
float3 conanPwlGammaToLinear(float3 g)
{
    g = saturate(g);
    float3 hi = select(g >= 192.0 / 255.0, 8.0 / 1024.0, 4.0 / 1024.0);
    float3 lo = select(g >= 64.0 / 255.0, 2.0 / 1024.0, 1.0 / 1024.0);
    float3 scale = select(g >= 96.0 / 255.0, hi, lo);
    float3 offset = select(g >= 96.0 / 255.0, select(g >= 192.0 / 255.0, -1024.0, -256.0),
                           select(g >= 64.0 / 255.0, -64.0, 0.0));
    float3 l = g * ((255.0 * 1024.0) * scale) + offset;
    l += trunc(l * scale);
    return l * (1.0 / 1023.0);
}
float4 conanGamma(uint resourceDescriptorIndex, float4 value)
{
    if (resourceDescriptorIndex & 0x80000000u)
        value.rgb = conanPwlGammaToLinear(value.rgb);
    return value;
}
#else
#define TEX_INDEX(i) (i)
#define TEX_SCALE(i) 1.0
#define conanGamma(i, v) (v)
#endif

Texture2D<float4> g_Texture2DDescriptorHeap[] : register(t0, space0);
Texture3D<float4> g_Texture3DDescriptorHeap[] : register(t0, space1);
TextureCube<float4> g_TextureCubeDescriptorHeap[] : register(t0, space2);
SamplerState g_SamplerDescriptorHeap[] : register(s0, space3);

uint2 getTexture2DDimensions(Texture2D<float4> texture)
{
    uint2 dimensions;
    texture.GetDimensions(dimensions.x, dimensions.y);
    return dimensions;
}

// Texel grid the guest shader addresses (the guest texture size).
float2 getGuestTexture2DDimensions(uint resourceDescriptorIndex, Texture2D<float4> texture)
{
    return float2(getTexture2DDimensions(texture)) / TEX_SCALE(resourceDescriptorIndex);
}

float4 tfetch2DBicubic(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset);

float4 tfetch2D(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset)
{
#ifdef CONAN_RECOMP
    // Bit 28: smooth (cubic B-spline) magnification, set by the host for small
    // textures of blended effects (particles, glows) - bilinear magnification
    // of those shows diamond/block patterns at high render resolutions.
    if (resourceDescriptorIndex & 0x10000000u)
        return conanGamma(resourceDescriptorIndex, tfetch2DBicubic(resourceDescriptorIndex, samplerDescriptorIndex, texCoord, offset));
#endif
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    return conanGamma(resourceDescriptorIndex, texture.Sample(g_SamplerDescriptorHeap[samplerDescriptorIndex], texCoord + offset / getGuestTexture2DDimensions(resourceDescriptorIndex, texture)));
}

float2 getWeights2D(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset)
{
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    return select(isnan(texCoord), 0.0, frac(texCoord * getGuestTexture2DDimensions(resourceDescriptorIndex, texture) + offset - 0.5));
}

#ifdef REBLUE_RECOMP
// Bilinear-filtered shadow compare over the four neighboring depth texels.
float shadowCmp2D(uint resourceDescriptorIndex, float2 texCoord, float ref)
{
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    int2 dimensions = int2(getTexture2DDimensions(texture));
    float2 coord = texCoord * dimensions - 0.5;
    float2 weights = frac(coord);
    int2 base = int2(floor(coord));
    int2 c0 = clamp(base, int2(0, 0), dimensions - 1);
    int2 c1 = clamp(base + 1, int2(0, 0), dimensions - 1);
    float4 taps = float4(
        texture.Load(int3(c0, 0)).x,
        texture.Load(int3(c1.x, c0.y, 0)).x,
        texture.Load(int3(c0.x, c1.y, 0)).x,
        texture.Load(int3(c1, 0)).x) > ref;
    return lerp(lerp(taps.x, taps.y, weights.x), lerp(taps.z, taps.w, weights.x), weights.y);
}
#endif

float w0(float a)
{
    return (1.0f / 6.0f) * (a * (a * (-a + 3.0f) - 3.0f) + 1.0f);
}

float w1(float a)
{
    return (1.0f / 6.0f) * (a * a * (3.0f * a - 6.0f) + 4.0f);
}

float w2(float a)
{
    return (1.0f / 6.0f) * (a * (a * (-3.0f * a + 3.0f) + 3.0f) + 1.0f);
}

float w3(float a)
{
    return (1.0f / 6.0f) * (a * a * a);
}

float g0(float a)
{
    return w0(a) + w1(a);
}

float g1(float a)
{
    return w2(a) + w3(a);
}

float h0(float a)
{
    return -1.0f + w1(a) / (w0(a) + w1(a)) + 0.5f;
}

float h1(float a)
{
    return 1.0f + w3(a) / (w2(a) + w3(a)) + 0.5f;
}

float4 tfetch2DBicubic(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset)
{
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    SamplerState samplerState = g_SamplerDescriptorHeap[samplerDescriptorIndex];
    float2 dimensions = getGuestTexture2DDimensions(resourceDescriptorIndex, texture);
    
    float x = texCoord.x * dimensions.x + offset.x;
    float y = texCoord.y * dimensions.y + offset.y;

    x -= 0.5f;
    y -= 0.5f;
    float px = floor(x);
    float py = floor(y);
    float fx = x - px;
    float fy = y - py;

    float g0x = g0(fx);
    float g1x = g1(fx);
    float h0x = h0(fx);
    float h1x = h1(fx);
    float h0y = h0(fy);
    float h1y = h1(fy);

    float4 r =
        g0(fy) * (g0x * texture.Sample(samplerState, float2(px + h0x, py + h0y) / float2(dimensions)) +
            g1x * texture.Sample(samplerState, float2(px + h1x, py + h0y) / float2(dimensions))) +
        g1(fy) * (g0x * texture.Sample(samplerState, float2(px + h0x, py + h1y) / float2(dimensions)) +
            g1x * texture.Sample(samplerState, float2(px + h1x, py + h1y) / float2(dimensions)));

    return r;
}

float4 tfetch3D(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float3 texCoord)
{
    return conanGamma(resourceDescriptorIndex, g_Texture3DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)].Sample(g_SamplerDescriptorHeap[samplerDescriptorIndex], texCoord));
}

struct CubeMapData
{
	#ifdef REBLUE_RECOMP
    // BD's cube-shadow PCF issues up to 9 cube ops per shader (bd_mirror_cs_ps /
    // bd_glass_cs_ps); overflowing this array drops the stored directions and
    // every tfetchCube reads OOB -> point-light shadows vanish.
    float3 cubeMapDirections[9];
    #else
    float3 cubeMapDirections[2];
    #endif
    uint cubeMapIndex;
};

float4 tfetchCube(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float3 texCoord, inout CubeMapData cubeMapData)
{
    return conanGamma(resourceDescriptorIndex, g_TextureCubeDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)].Sample(g_SamplerDescriptorHeap[samplerDescriptorIndex], cubeMapData.cubeMapDirections[texCoord.z]));
}

#ifdef REBLUE_RECOMP
// DEC3N normal decode; IA binds as R32_UINT so lane .x carries the raw bits (asuint recovers them).
float4 tfetchR11G11B10(float4 value)
{
    if (g_SpecConstants() & SPEC_CONSTANT_R11G11B10_NORMAL)
    {
        uint v = asuint(value.x);
        return float4(
            (v & 0x00000400 ? -1.0 : 0.0) + ((v & 0x3FF) / 1024.0),
            (v & 0x00200000 ? -1.0 : 0.0) + (((v >> 11) & 0x3FF) / 1024.0),
            (v & 0x80000000 ? -1.0 : 0.0) + (((v >> 22) & 0x1FF) / 512.0),
            0.0);
    }
    return value;
}

// Undo the engine bswap32 16-bit-pair swap (.yxwz) for any 16-bit-packed semantic flagged in the mask.
float4 swapFloats(uint swappedMask, float4 value, uint semanticIndex)
{
    return (swappedMask & (1u << semanticIndex)) != 0 ? value.yxwz : value;
}

// Recover X360 integer-cast-to-float TEXCOORDs from R16G16(B16A16)_UINT bindings (sign-extend low 16 bits).
float4 sintTexcoord(uint mask, float4 value, uint semanticIndex)
{
    if ((mask & (1u << semanticIndex)) != 0)
    {
        int4 si = (int4(asuint(value)) << 16) >> 16;
        return float4(si);
    }
    return value;
}
#else
float4 tfetchR11G11B10(uint4 value)
{
    if (g_SpecConstants() & SPEC_CONSTANT_R11G11B10_NORMAL)
    {
        return float4(
            (value.x & 0x00000400 ? -1.0 : 0.0) + ((value.x & 0x3FF) / 1024.0),
            (value.x & 0x00200000 ? -1.0 : 0.0) + (((value.x >> 11) & 0x3FF) / 1024.0),
            (value.x & 0x80000000 ? -1.0 : 0.0) + (((value.x >> 22) & 0x1FF) / 512.0),
            0.0);
    }
    else
    {
        return asfloat(value);
    }
}

float4 tfetchTexcoord(uint swappedTexcoords, float4 value, uint semanticIndex)
{
    return (swappedTexcoords & (1ull << semanticIndex)) != 0 ? value.yxwz : value;
}
#endif

float4 cube(float4 value, inout CubeMapData cubeMapData)
{
    uint index = cubeMapData.cubeMapIndex;
    cubeMapData.cubeMapDirections[index] = value.xyz;
    ++cubeMapData.cubeMapIndex;
    
    return float4(0.0, 0.0, 0.0, index);
}

float4 dst(float4 src0, float4 src1)
{
    float4 dest;
    dest.x = 1.0;
    dest.y = src0.y * src1.y;
    dest.z = src0.z;
    dest.w = src1.w;
    return dest;
}

float4 max4(float4 src0)
{
    return max(max(src0.x, src0.y), max(src0.z, src0.w));
}

float2 getPixelCoord(uint resourceDescriptorIndex, float2 texCoord)
{
    return getTexture2DDimensions(g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)]) * texCoord;
}

float computeMipLevel(float2 pixelCoord)
{
    float2 dx = ddx(pixelCoord);
    float2 dy = ddy(pixelCoord);
    float deltaMaxSqr = max(dot(dx, dx), dot(dy, dy));
    return max(0.0, 0.5 * log2(deltaMaxSqr));
}

#endif

#endif

#ifdef __spirv__

#define Use_DiffuseColor_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2720, 0x10)
#define Use_SpecularColor_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2736, 0x10)
#define ambient_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2704, 0x10)
#define brightness_scale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2752, 0x10)
#define cameraNearFar vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3056, 0x10)
#define cateye_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3264, 0x10)
#define cateye_noise vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3248, 0x10)
#define cateye_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3280, 0x10)
#define diffuse_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2640, 0x10)
#define diffuse_color2 vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2656, 0x10)
#define dilation vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3152, 0x10)
#define dilation_max vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3184, 0x10)
#define dilation_min vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3168, 0x10)
#define eyePosition vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3024, 0x10)
#define eyeball_size vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3296, 0x10)
#define g_CheapLights(INDEX) select((INDEX) < 192, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (64 + min(INDEX, 191)) * 16, 0x10), 0.0)
#define g_CloudInfo vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3072, 0x10)
#define g_DiffuseMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 8)
#define g_DiffuseMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 72)
#define g_DiffuseMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 136)
#define g_DiffuseMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 200)
#define g_EnvCubeMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 16)
#define g_EnvCubeMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 80)
#define g_EnvCubeMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 144)
#define g_EnvCubeMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 208)
#define g_FogTable_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 40)
#define g_FogTable_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 104)
#define g_FogTable_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 168)
#define g_FogTable_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 232)
#define g_LightCookie0_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 20)
#define g_LightCookie0_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 84)
#define g_LightCookie0_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 148)
#define g_LightCookie0_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 212)
#define g_LightCookie1_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 24)
#define g_LightCookie1_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 88)
#define g_LightCookie1_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 152)
#define g_LightCookie1_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 216)
#define g_LightCookie2_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 28)
#define g_LightCookie2_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 92)
#define g_LightCookie2_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 156)
#define g_LightCookie2_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 220)
#define g_LightCookie3_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 32)
#define g_LightCookie3_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 96)
#define g_LightCookie3_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 160)
#define g_LightCookie3_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 224)
#define g_LightingPassCount vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2768, 0x10)
#define g_NormalMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 0)
#define g_NormalMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 64)
#define g_NormalMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 128)
#define g_NormalMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 192)
#define g_NormalMapTexture2_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 4)
#define g_NormalMapTexture2_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 68)
#define g_NormalMapTexture2_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 132)
#define g_NormalMapTexture2_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 196)
#define g_ParallelLightEnabled vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2784, 0x10)
#define g_ParallelLightShadowTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 36)
#define g_ParallelLightShadowTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 100)
#define g_ParallelLightShadowTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 164)
#define g_ParallelLightShadowTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 228)
#define g_ParallelLights(INDEX) select((INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (0 + min(INDEX, 255)) * 16, 0x10), 0.0)
#define g_SceneAmbient vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3088, 0x10)
#define g_ShadowMapTextureAtlas_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 44)
#define g_ShadowMapTextureAtlas_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 108)
#define g_ShadowMapTextureAtlas_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 172)
#define g_ShadowMapTextureAtlas_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 236)
#define g_SpecularColorMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 12)
#define g_SpecularColorMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 76)
#define g_SpecularColorMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 140)
#define g_SpecularColorMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 204)
#define g_SpotLightEnabled(INDEX) select((INDEX) < 81, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (175 + min(INDEX, 80)) * 16, 0x10), 0.0)
#define g_SpotLights(INDEX) select((INDEX) < 232, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (24 + min(INDEX, 231)) * 16, 0x10), 0.0)
#define g_fTime vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3008, 0x10)
#define g_mMarkerToWorld(INDEX) select((INDEX) < 62, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (194 + min(INDEX, 61)) * 16, 0x10), 0.0)
#define g_mProjectionToWorld(INDEX) select((INDEX) < 72, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (184 + min(INDEX, 71)) * 16, 0x10), 0.0)
#define g_mWorld(INDEX) select((INDEX) < 77, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (179 + min(INDEX, 76)) * 16, 0x10), 0.0)
#define g_mWorldToObject(INDEX) select((INDEX) < 75, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (181 + min(INDEX, 74)) * 16, 0x10), 0.0)
#define glass_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3328, 0x10)
#define glass_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3312, 0x10)
#define iris_min vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3200, 0x10)
#define iris_offset vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3232, 0x10)
#define iris_size vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3216, 0x10)
#define lens_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3360, 0x10)
#define reflection_factor2 vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2576, 0x10)
#define refraction vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3344, 0x10)
#define specular_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2624, 0x10)
#define specular_color2 vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2560, 0x10)
#define specular_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2592, 0x10)
#define specular_power2 vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2608, 0x10)
#define use_bumpmap vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2672, 0x10)
#define use_bumpmap2 vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2688, 0x10)
#define viewVector vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3040, 0x10)
#define CONST_REL(INDEX) select((uint)(INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + min((uint)(INDEX), 255) * 16, 0x10), 0.0)

#else

cbuffer PixelShaderConstants : register(b1, space4)
{
	float4 g_PixelShaderConstantsArr[256] : packoffset(c0);
};

#define CONST_REL(INDEX) select((uint)(INDEX) < 256, g_PixelShaderConstantsArr[min((uint)(INDEX), 255)], 0.0)
#define Use_DiffuseColor_Texture g_PixelShaderConstantsArr[170]
#define Use_SpecularColor_Texture g_PixelShaderConstantsArr[171]
#define ambient_factor g_PixelShaderConstantsArr[169]
#define brightness_scale g_PixelShaderConstantsArr[172]
#define cameraNearFar g_PixelShaderConstantsArr[191]
#define cateye_factor g_PixelShaderConstantsArr[204]
#define cateye_noise g_PixelShaderConstantsArr[203]
#define cateye_power g_PixelShaderConstantsArr[205]
#define diffuse_color g_PixelShaderConstantsArr[165]
#define diffuse_color2 g_PixelShaderConstantsArr[166]
#define dilation g_PixelShaderConstantsArr[197]
#define dilation_max g_PixelShaderConstantsArr[199]
#define dilation_min g_PixelShaderConstantsArr[198]
#define eyePosition g_PixelShaderConstantsArr[189]
#define eyeball_size g_PixelShaderConstantsArr[206]
#define g_CheapLights(INDEX) CONST_REL(64 + (INDEX))
#define g_CloudInfo g_PixelShaderConstantsArr[192]
#define g_LightingPassCount g_PixelShaderConstantsArr[173]
#define g_ParallelLightEnabled g_PixelShaderConstantsArr[174]
#define g_ParallelLights(INDEX) CONST_REL(0 + (INDEX))
#define g_SceneAmbient g_PixelShaderConstantsArr[193]
#define g_SpotLightEnabled(INDEX) CONST_REL(175 + (INDEX))
#define g_SpotLights(INDEX) CONST_REL(24 + (INDEX))
#define g_fTime g_PixelShaderConstantsArr[188]
#define g_mMarkerToWorld(INDEX) CONST_REL(194 + (INDEX))
#define g_mProjectionToWorld(INDEX) CONST_REL(184 + (INDEX))
#define g_mWorld(INDEX) CONST_REL(179 + (INDEX))
#define g_mWorldToObject(INDEX) CONST_REL(181 + (INDEX))
#define glass_factor g_PixelShaderConstantsArr[208]
#define glass_power g_PixelShaderConstantsArr[207]
#define iris_min g_PixelShaderConstantsArr[200]
#define iris_offset g_PixelShaderConstantsArr[202]
#define iris_size g_PixelShaderConstantsArr[201]
#define lens_factor g_PixelShaderConstantsArr[210]
#define reflection_factor2 g_PixelShaderConstantsArr[161]
#define refraction g_PixelShaderConstantsArr[209]
#define specular_color g_PixelShaderConstantsArr[164]
#define specular_color2 g_PixelShaderConstantsArr[160]
#define specular_power g_PixelShaderConstantsArr[162]
#define specular_power2 g_PixelShaderConstantsArr[163]
#define use_bumpmap g_PixelShaderConstantsArr[167]
#define use_bumpmap2 g_PixelShaderConstantsArr[168]
#define viewVector g_PixelShaderConstantsArr[190]

cbuffer SharedConstants : register(b2, space4)
{
	uint g_DiffuseMapTexture_Texture2DDescriptorIndex : packoffset(c0.z);
	uint g_DiffuseMapTexture_Texture3DDescriptorIndex : packoffset(c4.z);
	uint g_DiffuseMapTexture_TextureCubeDescriptorIndex : packoffset(c8.z);
	uint g_DiffuseMapTexture_SamplerDescriptorIndex : packoffset(c12.z);
	uint g_EnvCubeMapTexture_Texture2DDescriptorIndex : packoffset(c1.x);
	uint g_EnvCubeMapTexture_Texture3DDescriptorIndex : packoffset(c5.x);
	uint g_EnvCubeMapTexture_TextureCubeDescriptorIndex : packoffset(c9.x);
	uint g_EnvCubeMapTexture_SamplerDescriptorIndex : packoffset(c13.x);
	uint g_FogTable_Texture2DDescriptorIndex : packoffset(c2.z);
	uint g_FogTable_Texture3DDescriptorIndex : packoffset(c6.z);
	uint g_FogTable_TextureCubeDescriptorIndex : packoffset(c10.z);
	uint g_FogTable_SamplerDescriptorIndex : packoffset(c14.z);
	uint g_LightCookie0_Texture2DDescriptorIndex : packoffset(c1.y);
	uint g_LightCookie0_Texture3DDescriptorIndex : packoffset(c5.y);
	uint g_LightCookie0_TextureCubeDescriptorIndex : packoffset(c9.y);
	uint g_LightCookie0_SamplerDescriptorIndex : packoffset(c13.y);
	uint g_LightCookie1_Texture2DDescriptorIndex : packoffset(c1.z);
	uint g_LightCookie1_Texture3DDescriptorIndex : packoffset(c5.z);
	uint g_LightCookie1_TextureCubeDescriptorIndex : packoffset(c9.z);
	uint g_LightCookie1_SamplerDescriptorIndex : packoffset(c13.z);
	uint g_LightCookie2_Texture2DDescriptorIndex : packoffset(c1.w);
	uint g_LightCookie2_Texture3DDescriptorIndex : packoffset(c5.w);
	uint g_LightCookie2_TextureCubeDescriptorIndex : packoffset(c9.w);
	uint g_LightCookie2_SamplerDescriptorIndex : packoffset(c13.w);
	uint g_LightCookie3_Texture2DDescriptorIndex : packoffset(c2.x);
	uint g_LightCookie3_Texture3DDescriptorIndex : packoffset(c6.x);
	uint g_LightCookie3_TextureCubeDescriptorIndex : packoffset(c10.x);
	uint g_LightCookie3_SamplerDescriptorIndex : packoffset(c14.x);
	uint g_NormalMapTexture_Texture2DDescriptorIndex : packoffset(c0.x);
	uint g_NormalMapTexture_Texture3DDescriptorIndex : packoffset(c4.x);
	uint g_NormalMapTexture_TextureCubeDescriptorIndex : packoffset(c8.x);
	uint g_NormalMapTexture_SamplerDescriptorIndex : packoffset(c12.x);
	uint g_NormalMapTexture2_Texture2DDescriptorIndex : packoffset(c0.y);
	uint g_NormalMapTexture2_Texture3DDescriptorIndex : packoffset(c4.y);
	uint g_NormalMapTexture2_TextureCubeDescriptorIndex : packoffset(c8.y);
	uint g_NormalMapTexture2_SamplerDescriptorIndex : packoffset(c12.y);
	uint g_ParallelLightShadowTexture_Texture2DDescriptorIndex : packoffset(c2.y);
	uint g_ParallelLightShadowTexture_Texture3DDescriptorIndex : packoffset(c6.y);
	uint g_ParallelLightShadowTexture_TextureCubeDescriptorIndex : packoffset(c10.y);
	uint g_ParallelLightShadowTexture_SamplerDescriptorIndex : packoffset(c14.y);
	uint g_ShadowMapTextureAtlas_Texture2DDescriptorIndex : packoffset(c2.w);
	uint g_ShadowMapTextureAtlas_Texture3DDescriptorIndex : packoffset(c6.w);
	uint g_ShadowMapTextureAtlas_TextureCubeDescriptorIndex : packoffset(c10.w);
	uint g_ShadowMapTextureAtlas_SamplerDescriptorIndex : packoffset(c14.w);
	uint g_SpecularColorMapTexture_Texture2DDescriptorIndex : packoffset(c0.w);
	uint g_SpecularColorMapTexture_Texture3DDescriptorIndex : packoffset(c4.w);
	uint g_SpecularColorMapTexture_TextureCubeDescriptorIndex : packoffset(c8.w);
	uint g_SpecularColorMapTexture_SamplerDescriptorIndex : packoffset(c12.w);
	DEFINE_SHARED_CONSTANTS();
};

#endif
	#define Do_AutoDilate BOOL_BIT(130)
	#define Use_EnvCubeMap_Texture BOOL_BIT(128)
	#define Use_MarkerSpace BOOL_BIT(129)

#ifndef __spirv__
[shader("pixel")]
#endif
void main(
	in float4 iPos : SV_Position,
	in float4 iTexCoord0 : TEXCOORD0,
	in float4 iTexCoord1 : TEXCOORD1,
	in float4 iTexCoord2 : TEXCOORD2,
	in float4 iTexCoord3 : TEXCOORD3,
	in float4 iTexCoord4 : TEXCOORD4,
	in float4 iTexCoord5 : TEXCOORD5,
	in float4 iTexCoord6 : TEXCOORD6,
	in float4 iTexCoord7 : TEXCOORD7,
	in float4 iTexCoord8 : TEXCOORD8,
	in float4 iTexCoord9 : TEXCOORD9,
	in float4 iTexCoord10 : TEXCOORD10,
	in float4 iTexCoord11 : TEXCOORD11,
	in float4 iTexCoord12 : TEXCOORD12,
	in float4 iTexCoord13 : TEXCOORD13,
	in float4 iTexCoord14 : TEXCOORD14,
	in float4 iTexCoord15 : TEXCOORD15,
	in float4 iColor0 : COLOR0,
	in float4 iColor1 : COLOR1,
#ifdef __spirv__
	in bool iFace : SV_IsFrontFace
#else
	in uint iFace : SV_IsFrontFace
#endif
,
	out float4 oC0 : SV_Target0)
{
	float4 c244 = asfloat(uint4(0x41200000, 0x322BCC77, 0x40000000, 0x0));
	float4 c245 = asfloat(uint4(0xBDCCCCCD, 0x38D1B717, 0x3E3876E2, 0x3E22F983));
	float4 c246 = asfloat(uint4(0x3727C5AC, 0x42C8000D, 0x44160000, 0x3F22F983));
	float4 c247 = asfloat(uint4(0xBF6B851F, 0xBF68F5C3, 0xBDAE5A36, 0x3FC00000));
	float4 c248 = asfloat(uint4(0x0, 0x3F800000, 0x3E800000, 0x3F000000));
	float4 c249 = asfloat(uint4(0x40C90FDB, 0x3CAAAE5F, 0x3C75C28F, 0x40400000));
	float4 c250 = asfloat(uint4(0xBF000000, 0x3FC90FDB, 0xBB83126F, 0x3B83126F));
	float4 c251 = asfloat(uint4(0xBF800000, 0xC0490FDB, 0xBEA91D04, 0x3FC90FD8));
	float4 c252 = asfloat(uint4(0x3F800000, 0x3E4CCCCD, 0x3F7FF738, 0x40400000));
	float4 c253 = asfloat(uint4(0xC0000000, 0xBF000000, 0x3F000000, 0xC0490FDB));
	float4 c254 = asfloat(uint4(0xB9000000, 0x39400000, 0xB9C00000, 0xB8800000)) * g_ShadowAtlasTexelScale;
	float4 c255 = asfloat(uint4(0x39C00000, 0x38800000, 0x39000000, 0xB9400000)) * g_ShadowAtlasTexelScale;

	[branch] if (g_ShadowSoftness > 0.0)
	{
		float conanAngle = 6.2831853 * frac(52.9829189 * frac(dot(floor(iPos.xy), float2(0.06711056, 0.00583715))));
		float2 conanCS = float2(cos(conanAngle), sin(conanAngle)) * g_ShadowSoftness;
		c254 = float4(c254.x * conanCS.x - c254.y * conanCS.y, c254.x * conanCS.y + c254.y * conanCS.x, c254.z * conanCS.x - c254.w * conanCS.y, c254.z * conanCS.y + c254.w * conanCS.x);
		c255 = float4(c255.x * conanCS.x - c255.y * conanCS.y, c255.x * conanCS.y + c255.y * conanCS.x, c255.z * conanCS.x - c255.w * conanCS.y, c255.z * conanCS.y + c255.w * conanCS.x);
	}

	float4 r0 = iTexCoord0;
	float4 r1 = iTexCoord1;
	float4 r2 = iTexCoord2;
	float4 r3 = iTexCoord3;
	float4 r4 = iTexCoord4;
	float4 r5 = iColor0;
	float4 r6 = 0.0;
	float4 r7 = 0.0;
	float4 r8 = 0.0;
	float4 r9 = 0.0;
	float4 r10 = 0.0;
	float4 r11 = 0.0;
	float4 r12 = 0.0;
	float4 r13 = 0.0;
	float4 r14 = 0.0;
	float4 r15 = 0.0;
	float4 r16 = 0.0;
	float4 r17 = 0.0;
	float4 r18 = 0.0;
	float4 r19 = 0.0;
	float4 r20 = 0.0;
	float4 r21 = 0.0;
	float4 r22 = 0.0;
	float4 r23 = 0.0;
	float4 r24 = 0.0;
	float4 r25 = 0.0;
	float4 r26 = 0.0;
	float4 r27 = 0.0;
	float4 r28 = 0.0;
	float4 r29 = 0.0;
	float4 r30 = 0.0;
	float4 r31 = 0.0;
	int a0 = 0;
	int aL = 0;
	bool p0 = false;
	float ps = 0.0;
	float2 pixelCoord = 0.0;
	CubeMapData cubeMapData = (CubeMapData)0;

	r1.w = max(dilation.x, c245.y);
	r5.xyzw = r0.wwww * g_mProjectionToWorld(3).wxyz;
	r5.xyzw = r0.zzzz * g_mProjectionToWorld(2).wxyz + r5.xyzw;
	r5.xyzw = r0.yyyy * g_mProjectionToWorld(1).wxyz + r5.xyzw;
	r5.xyzw = r0.xxxx * g_mProjectionToWorld(0).wxyz + r5.xyzw;
	r3.w = min(r1.w, c252.x);
	ps = clamp(rcp(r5.x), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r5.xyz = r5.yzw * r1.www;
	if (Do_AutoDilate)
	{
		r0.x = g_fTime.x * c245.w + c253.z;
		ps = frac(r0.x);
		r0.x = ps;
		r0.x = r0.x * c249.x + c253.w;
		ps = sin(r0.x);
		r0.y = ps;
		ps = c252.x + r0.y;
		r0.x = ps;
		ps = c253.z * r0.x;
		r1.w = ps;
		r1.w = max(r1.w, c246.x);
		r3.w = min(r1.w, c252.x);
	}
	ps = max(g_mWorldToObject(2).z, g_mWorldToObject(2).z);
	r7.z = ps;
	r7.y = max(g_mWorldToObject(1).z, g_mWorldToObject(1).z);
	ps = max(g_mWorldToObject(2).x, g_mWorldToObject(2).x);
	r14.z = ps;
	r7.x = max(g_mWorldToObject(0).z, g_mWorldToObject(0).z);
	ps = max(g_mWorldToObject(1).x, g_mWorldToObject(1).x);
	r14.y = ps;
	r13.xyz = max(g_mWorld(1).xyz, g_mWorld(1).xyz);
	ps = max(g_mWorldToObject(0).x, g_mWorldToObject(0).x);
	r14.x = ps;
	if (Use_MarkerSpace)
	{
		r14.xyz = max(g_mMarkerToWorld(0).xyz, g_mMarkerToWorld(0).xyz);
		r13.xyz = max(g_mMarkerToWorld(1).xyz, g_mMarkerToWorld(1).xyz);
		r7.xyz = max(g_mMarkerToWorld(2).xyz, g_mMarkerToWorld(2).xyz);
	}
	r0.y = r2.y * c253.z;
	ps = clamp(rcp(iris_min.x), FLT_MIN, FLT_MAX);
	r0.x = ps;
	r2.z = r0.y * r0.x;
// conan_tfetch slot=0 mag=3 min=3 mip=3 aniso=7
	pixelCoord = getPixelCoord(g_NormalMapTexture_Texture2DDescriptorIndex, r2.xz);
	r6.xyz = tfetch2D(g_NormalMapTexture_Texture2DDescriptorIndex, g_NormalMapTexture_SamplerDescriptorIndex, r2.xz, float2(0, 0)).xyz;
// conan_tfetch slot=1 mag=3 min=3 mip=3 aniso=7
	r8.xyz = tfetch2D(g_NormalMapTexture2_Texture2DDescriptorIndex, g_NormalMapTexture2_SamplerDescriptorIndex, r2.xy, float2(0, 0)).xyz;
	r5.w = dot(r1.zxy, r1.zxy);
	ps = max(iris_min.x, iris_min.x);
	r6.w = dot(r4.zxy, r4.zxy);
	ps = c250.z + ps;
	r9.x = ps;
	r7.w = dot(r3.zxy, r3.zxy);
	ps = max(iris_min.x, iris_min.x);
	r8.xyz = r8.xyz * c244.zzz + c251.xxx;
	r11.xyz = r6.xyz * c244.zzz + c251.xxx;
	r6.xyz = -r5.xyz + eyePosition.xyz;
	ps = c250.w + ps;
	r9.y = ps;
	r2.w = dot(r6.zxy, r6.zxy);
	ps = r9.y - r9.x;
	r1.w = ps;
	r0.y = dot(r11.zxy, r11.zxy);
	ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r4.w = dot(r8.zxy, r8.zxy);
	ps = clamp(rsqrt(abs(r7.w)), FLT_MIN, FLT_MAX);
	r7.w = ps;
	r10.yzw = r7.www * r3.xyz;
	ps = clamp(rsqrt(abs(r6.w)), FLT_MIN, FLT_MAX);
	r3.x = ps;
	r12.xyz = r3.xxx * r4.xyz;
	ps = clamp(rsqrt(abs(r5.w)), FLT_MIN, FLT_MAX);
	r3.x = ps;
	r3.xyz = r3.xxx * r1.xyz;
	ps = clamp(rsqrt(abs(r4.w)), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r8.xyz = r8.zxy * r1.xxx;
	ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r11.xyz = r11.zxy * r0.yyy;
	ps = clamp(rsqrt(abs(r2.w)), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r6.xyz = r6.xyz * r0.yyy;
	r1.y = dot(-r6.zxy, r3.zxy);
	ps = refraction.x * refraction.x;
	r1.z = ps;
	r4.xyz = r11.xxx * r3.xyz;
	ps = max(-r9.x, -r9.x);
	r9.xyz = r8.zzz * r12.xyz;
	ps = -r2.y + ps;
	r0.y = ps;
	r9.yzw = r8.yyy * r10.yzw + r9.xyz;
	r4.xyz = r11.zzz * r12.xyz + r4.xyz;
	r1.x = -r1.y * r1.y + c252.x;
	r10.x = r1.z * r1.x;
	ps = max(r0.y, r0.y);
	r4.xyz = r11.yyy * r10.yzw + r4.xyz;
	r0.y = dot(r4.zxy, r4.zxy);
	ps = saturate(r1.w * ps);
	r10.y = ps;
	r1.xz = -r10.xy + c252.xw;
	r1.w = r1.z + -r10.y;
	ps = r10.y * r10.y;
	r4.w = ps;
	r5.w = r4.w * r1.w;
	ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r1.w = abs(r2.y) > iris_min.x;
	r8.yzw = r8.xxx * r3.xyz;
	r10.xyz = r4.zxy * r0.yyy;
	ps = r1.x >= 0.0;
	r0.y = ps;
	r4.xz = select(use_bumpmap.xx > 0.0, r10.zy, r3.yx);
	r15.x = select(use_bumpmap.x > 0.0, r10.x, r3.z);
	r1.x = r1.x * r0.y;
	ps = refraction.x * r0.y;
	r1.z = ps;
	r9.x = r1.z * r1.y;
	ps = sqrt(abs(r1.x));
	r8.x = ps;
	r9.xyzw = r9.xyzw + r8.xyzw;
	r1.x = dot(r9.wyz, r9.wyz);
	ps = sqrt(abs(r2.w));
	r1.y = ps;
	r8.xyz = r3.xyz * r9.xxx;
	ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r11.xyz = r1.zzz * -r6.xyz + -r8.xyz;
	r8.xyz = -r11.xyz * r1.yyy + r5.xyz;
	r1.xyz = r9.yzw * r1.xxx;
	p0 = r1.w == 0.0;
	ps = p0 ? 0.0 : 1.0;
	r12.xyz = select(use_bumpmap2.xxx > 0.0, r1.xyz, r3.xyz);
	if (p0)
	{
		r0.x = r0.x * abs(r2.y);
	}
	if (p0)
	{
		ps = c253.z * r0.x;
		r2.w = ps;
	}
	if (!p0)
	{
		r1.x = -iris_min.x + c252.x;
	}
	if (!p0)
	{
		r1.y = abs(r2.y) + -iris_min.x;
		ps = clamp(rcp(r1.x), FLT_MIN, FLT_MAX);
		r1.x = ps;
	}
	if (!p0)
	{
		r1.x = r1.y * r1.x;
	}
	if (!p0)
	{
		r2.w = r1.x * c253.z + c253.z;
	}
	ps = c252.x - r2.w;
	r2.z = ps;
// conan_tfetch slot=3 mag=3 min=3 mip=3 aniso=7
	r10.xyz = tfetch2D(g_SpecularColorMapTexture_Texture2DDescriptorIndex, g_SpecularColorMapTexture_SamplerDescriptorIndex, r2.xz, float2(0, 0)).xyz;
// conan_tfetch slot=2 mag=3 min=3 mip=3 aniso=7
	r9.xyz = tfetch2D(g_DiffuseMapTexture_Texture2DDescriptorIndex, g_DiffuseMapTexture_SamplerDescriptorIndex, r2.xz, float2(0, 0)).xyz;
	r1.xz = -r2.yy + c247.xy;
	ps = max(iris_min.x, iris_min.x);
	r9.xyz = select(Use_DiffuseColor_Texture.xxx > 0.0, r9.xyz, diffuse_color.xyz);
	r10.yzw = select(Use_SpecularColor_Texture.xxx > 0.0, r10.xyz, specular_color.xyz);
	r3.xyz = -r3.xyz * eyeball_size.xxx + r5.xyz;
	r0.y = dot(r13.zxy, r13.zxy);
	ps = -c253.z + ps;
	r0.x = ps;
	r0.x = r0.x * c253.z + c253.z;
	ps = saturate(c246.y * r1.x);
	r19.y = ps;
	r2.y = -r19.y * c244.z + c252.w;
	r0.x = frac(r0.x);
	ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r0.x = r0.x * c249.x + c253.w;
	r16.xyz = r0.yyy * r13.xyz;
	ps = saturate(c246.y * r1.z);
	r20.y = ps;
	r1.yzw = r16.xyz * iris_offset.xxx + r3.xyz;
	r18.w = r20.y * r20.y;
	ps = sin(r0.x);
	r0.y = ps;
	r18.xyz = r1.yzw + -r8.xyz;
	ps = eyeball_size.x * r0.y;
	r0.y = ps;
	r3.xyz = r16.xyz * r0.yyy + r3.xyz;
	r0.y = -r0.y + iris_offset.x;
	ps = clamp(rcp(iris_size.x), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r19.x = abs(r0.y) * r1.x;
	r4.y = dot(r18.zxy, r18.zxy);
	ps = max(-r3.x, -r3.x);
	r20.zw = r19.xy * r19.xy;
	ps = r5.x + ps;
	r13.y = ps;
	r20.x = r20.w * r2.y;
	ps = max(-r3.y, -r3.y);
	r17.xyz = -r20.xyz + c252.xwx;
	ps = r5.y + ps;
	r13.z = ps;
	r15.w = r17.y + -r20.y;
	ps = sqrt(abs(r17.z));
	r6.w = ps;
	r2.z = min(abs(r19.x), r6.w);
	ps = max(-r3.z, -r3.z);
	r0.y = max(abs(r19.x), r6.w);
	ps = r5.z + ps;
	r13.w = ps;
	r4.w = min(r19.x, r6.w);
	ps = max(r19.x, r19.x);
	r15.y = ps;
	r2.y = abs(r19.x) > r6.w;
	ps = clamp(rsqrt(abs(r4.y)), FLT_MIN, FLT_MAX);
	r15.z = ps;
	r19.xyzw = r18.xyzw * r15.zzzw;
	ps = max(r6.w, r6.w);
	r15.z = ps;
	r18.w = -r4.w > r4.w;
	ps = max(r15.y, r15.z);
	r4.w = ps;
	r17.w = r4.w >= -r4.w;
	ps = clamp(rcp(r0.y), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r13.x = dot(r19.zxy, r11.zxy);
	ps = max(r2.z, r2.z);
	r18.xyz = r19.www * r13.yzw;
	ps = r0.y * ps;
	r4.w = ps;
	r17.xyzw = r18.xyzw * r17.xxxw;
	ps = r4.w * r4.w;
	r6.w = ps;
	r0.y = r6.w * c249.y + c247.z;
	r0.y = r6.w * r0.y + c245.z;
	r13.yzw = r17.xyz * lens_factor.xxx + r12.xyz;
	r2.z = dot(r13.wyz, r13.wyz);
	ps = sqrt(abs(r4.y));
	r4.y = ps;
	r0.y = r6.w * r0.y + c251.z;
	r0.y = r6.w * r0.y + c252.z;
	r0.y = r4.w * r0.y;
	ps = clamp(rsqrt(abs(r2.z)), FLT_MIN, FLT_MAX);
	r4.w = ps;
	r2.z = r0.y * c253.x + c250.y;
	r15.yz = r13.wx * r4.wy;
	r12.xyz = r15.zzz * r11.xyz + r8.xyz;
	r0.y = r2.z * r2.y + r0.y;
	r12.xyz = r12.xyz + -r1.yzw;
	ps = r0.y + r0.y;
	r2.y = ps;
	r2.y = r17.w * -r2.y + r0.y;
	r0.y = dot(r12.zxy, r12.zxy);
	r4.yw = r13.zy * r4.ww;
	ps = sqrt(abs(r0.y));
	r0.y = ps;
	r2.z = iris_size.x > r0.y;
	ps = -abs(r0.x) > 0.0;
	r13.y = ps;
	r2.y = -r2.y + c251.w;
	p0 = r2.z != 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (!p0)
	{
		r13.xzw = -abs(r0.xxx) > c248.xxx;
	}
	if (p0)
	{
		r1.x = r1.x * r0.y;
	}
	if (p0)
	{
		r1.x = -r1.x * r1.x + c252.x;
	}
	if (p0)
	{
		ps = sqrt(abs(r1.x));
		r1.x = ps;
	}
	if (p0)
	{
		r13.w = r1.x * iris_size.x + r15.z;
	}
	if (p0)
	{
		r8.xyz = r11.xyz * r13.www + r8.xyz;
	}
	if (p0)
	{
		r8.xyz = -r8.xyz + r1.yzw;
	}
	if (p0)
	{
		r1.x = dot(r8.zxy, r8.zxy);
	}
	if (p0)
	{
		ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
		r1.x = ps;
	}
	if (p0)
	{
		r13.xyz = r8.zxy * r1.xxx;
	}
	r14.w = -abs(r0.x) > c248.x;
	p0 = abs(r13.w) > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (!p0)
	{
		ps = max(r15.x, r15.x);
		r13.x = ps;
	}
	if (!p0)
	{
		r12.xyz = max(r5.xyz, r5.xyz);
		ps = max(r4.z, r4.z);
		r13.y = ps;
	}
	if (!p0)
	{
		r8.xyz = max(r6.xyz, r6.xyz);
		ps = max(r4.x, r4.x);
		r13.z = ps;
	}
	if (p0)
	{
		r12.xyz = -r6.xyz * r13.www + eyePosition.xyz;
	}
	if (p0)
	{
		r1.xyz = r12.xyz + -r1.yzw;
	}
	if (p0)
	{
		r11.xyz = r12.xyz + -r3.xyz;
	}
	if (p0)
	{
		r7.z = dot(r11.zxy, r7.zxy);
	}
	if (p0)
	{
		r0.y = dot(r1.zxy, r1.zxy);
	}
	if (p0)
	{
		r7.w = dot(r11.zxy, r14.zxy);
		ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
	}
	if (p0)
	{
		r1.xyz = r1.xyz * r0.yyy;
	}
	if (p0)
	{
		r1.w = dot(r1.zxy, -r16.zxy);
		ps = clamp(rcp(eyeball_size.x), FLT_MIN, FLT_MAX);
		r1.z = ps;
	}
	if (p0)
	{
		r0.y = -r1.w * r1.w + c252.x;
	}
	if (p0)
	{
		r14.z = -r1.w > r1.w;
		ps = sqrt(abs(r0.y));
		r0.y = ps;
	}
	if (p0)
	{
		r1.x = min(r1.w, r0.y);
		ps = max(r1.w, r1.w);
		r1.y = ps;
	}
	if (p0)
	{
		r11.x = min(abs(r1.w), r0.y);
		ps = cos(r0.x);
		r2.x = ps;
	}
	if (p0)
	{
		r0.x = max(abs(r1.w), r0.y);
		ps = clamp(rcp(r2.x), FLT_MIN, FLT_MAX);
		r7.y = ps;
	}
	if (p0)
	{
		r2.w = r0.y > abs(r1.w);
		ps = clamp(rcp(r0.x), FLT_MIN, FLT_MAX);
		r7.x = ps;
	}
	if (p0)
	{
		r11.yz = r7.yz * r1.zz;
		ps = max(r0.y, r0.y);
		r1.z = ps;
	}
	if (p0)
	{
		r7.xzw = r11.xyz * r7.xwy;
		ps = max(r1.y, r1.z);
		r0.x = ps;
	}
	if (p0)
	{
		r1.y = r0.x >= -r0.x;
		ps = min(abs(r7.w), abs(r7.z));
		r0.y = ps;
	}
	if (p0)
	{
		r18.w = -r1.x > r1.x;
		ps = max(abs(r7.w), abs(r7.z));
		r0.x = ps;
	}
	if (p0)
	{
		r1.x = max(-r7.w, r7.z);
		ps = max(-r7.w, -r7.w);
		r11.y = ps;
	}
	if (p0)
	{
		r1.z = abs(r7.w) > abs(r7.z);
		ps = max(r7.z, r7.z);
		r11.z = ps;
	}
	if (p0)
	{
		r11.x = -r7.z > r7.z;
		ps = min(r11.y, r11.z);
		r1.w = ps;
	}
	if (p0)
	{
		r11.z = -r1.w > r1.w;
		ps = clamp(rcp(r0.x), FLT_MIN, FLT_MAX);
		r0.x = ps;
	}
	if (p0)
	{
		r7.y = r0.y * r0.x;
	}
	if (p0)
	{
		r18.yz = r7.xy * r7.xy;
	}
	if (p0)
	{
		r0.x = r18.z * c249.y + c247.z;
	}
	if (p0)
	{
		r0.x = r18.z * r0.x + c245.z;
	}
	if (p0)
	{
		r0.x = r18.z * r0.x + c251.z;
	}
	if (p0)
	{
		r0.x = r18.z * r0.x + c252.z;
	}
	if (p0)
	{
		r11.y = r7.y * r0.x;
	}
	if (p0)
	{
		r0.xy = r11.yx * c253.xw;
	}
	if (p0)
	{
		r1.x = r1.x >= -r1.x;
		ps = c250.y + r0.x;
		r11.w = ps;
	}
	if (p0)
	{
		r1.zw = r11.zw * r1.xz;
	}
	if (p0)
	{
		r1.x = r1.w + r11.y;
	}
	if (p0)
	{
		r0.y = r1.x + r0.y;
	}
	if (p0)
	{
		ps = r0.y + r0.y;
		r1.x = ps;
	}
	if (p0)
	{
		r2.x = r1.z * -r1.x + r0.y;
	}
	if (p0)
	{
		r0.y = r2.x * c246.w + c253.z;
	}
	if (p0)
	{
		ps = frac(r0.y);
		r18.x = ps;
	}
	if (p0)
	{
		r1.xz = r18.yx * c249.yx;
	}
	if (p0)
	{
		r8.xyz = -r12.xyz + eyePosition.xyz;
		ps = c247.z + r1.x;
		r1.w = ps;
	}
	if (p0)
	{
		r11.xy = r18.wy * r1.yw;
	}
	if (p0)
	{
		r0.y = r11.y + c245.z;
		ps = max(abs(r7.z), abs(r7.z));
	}
	if (p0)
	{
		r1.w = r18.y * r0.y;
		ps = c244.x * ps;
		r1.y = ps;
	}
	if (p0)
	{
		r17.xzw = r1.yzw + c251.xyz;
	}
	if (p0)
	{
		r1.z = r18.y * r17.w;
		ps = sin(r17.z);
		r0.y = ps;
	}
	if (p0)
	{
		r2.z = dot(r8.zxy, r8.zxy);
		ps = cateye_noise.x * r0.y;
		r17.y = ps;
	}
	if (p0)
	{
		r1.xy = r17.xy * cateye_factor.xx;
		ps = max(dilation_max.x, dilation_max.x);
	}
	if (p0)
	{
		r1.xyz = r1.xyz + c252.xyz;
		ps = -dilation_min.x + ps;
		r1.w = ps;
	}
	if (p0)
	{
		r0.y = r1.x * r3.w + r1.y;
	}
	if (p0)
	{
		r0.y = r1.w * r0.y + dilation_min.x;
	}
	if (p0)
	{
		r14.x = r7.x * r1.z;
		ps = clamp(rcp(r0.y), FLT_MIN, FLT_MAX);
		r14.y = ps;
	}
	if (p0)
	{
		r7.xyzw = r14.xyyz * c253.xyzw;
	}
	if (p0)
	{
		r1.xy = r7.zx + c250.xy;
	}
	if (p0)
	{
		r0.y = r1.y * r2.w + r14.x;
	}
	if (p0)
	{
		r1.z = r0.y + r7.w;
	}
	if (p0)
	{
		r1.w = r1.z + r1.z;
		ps = clamp(rcp(r2.y), FLT_MIN, FLT_MAX);
		r0.y = ps;
	}
	if (p0)
	{
		r1.z = r11.x * -r1.w + r1.z;
	}
	if (p0)
	{
		r0.y = r1.z * r0.y;
		ps = clamp(rsqrt(abs(r2.z)), FLT_MIN, FLT_MAX);
		r1.z = ps;
	}
	if (p0)
	{
		r8.xyz = r8.xyz * r1.zzz;
		ps = clamp(log2(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
	}
	if (p0)
	{
		ps = cateye_power.x * r0.y;
		r1.z = ps;
	}
	if (p0)
	{
		r2.x = r2.x * c245.w;
		ps = exp2(r1.z);
		r1.z = ps;
	}
	if (p0)
	{
		r2.w = r7.y * r1.z + r1.x;
	}
	if (Use_EnvCubeMap_Texture)
	{
		r1.xyzw = select(c248.xxxy == 0.0, -r6.xyzz, c252.xxxx);
		r7.xyz = select(c248.xxy == 0.0, r4.wyy, r15.yyy);
		r7.w = dot(-r6.xyz, r7.xyz);
		r1.y = dot(r7.xyzw, r1.xyzw);
		r1.x = r15.y * r1.y;
		r1.yz = r4.wy * r1.yy;
		r1.xyz = -r6.zyx + -r1.xzy;
		r1.xyzw = cube(r1.zyxx, cubeMapData);
		r7.z = max(r1.w, r1.w);
		ps = clamp(rcp(abs(r1.z)), FLT_MIN, FLT_MAX);
		r2.y = ps;
		r7.xy = r1.yx * r2.yy + c247.ww;
// conan_tfetch slot=4 mag=3 min=3 mip=3 aniso=7
		r14.yzw = tfetchCube(g_EnvCubeMapTexture_TextureCubeDescriptorIndex, g_EnvCubeMapTexture_SamplerDescriptorIndex, r7.xyz, cubeMapData).yzx;
	}
	else
	{
		r14.yz = -abs(r0.xx) > c248.xx;
	}
	ps = max(-r2.w, -r2.w);
	r2.z = ps;
// conan_tfetch slot=0 mag=3 min=3 mip=3 aniso=7
	pixelCoord = getPixelCoord(g_NormalMapTexture_Texture2DDescriptorIndex, r2.xz);
	r1.xzw = tfetch2D(g_NormalMapTexture_Texture2DDescriptorIndex, g_NormalMapTexture_SamplerDescriptorIndex, r2.xz, float2(0, 0)).xyz;
// conan_tfetch slot=2 mag=3 min=3 mip=3 aniso=7
	r17.xyz = tfetch2D(g_DiffuseMapTexture_Texture2DDescriptorIndex, g_DiffuseMapTexture_SamplerDescriptorIndex, r2.xz, float2(0, 0)).xyz;
// conan_tfetch slot=3 mag=3 min=3 mip=3 aniso=7
	r2.xyz = tfetch2D(g_SpecularColorMapTexture_Texture2DDescriptorIndex, g_SpecularColorMapTexture_SamplerDescriptorIndex, r2.xz, float2(0, 0)).xyz;
	r1.y = dilation_min.x * dilation_max.x;
	r11.xyz = r9.xyz * brightness_scale.xxx;
	ps = -c245.x - -r2.w;
	r0.y = ps;
	r7.xyz = select(Use_SpecularColor_Texture.xxx > 0.0, r2.xyz, specular_color.xyz);
	r17.xyz = select(Use_DiffuseColor_Texture.xxx > 0.0, r17.xyz, diffuse_color.xyz);
	r9.xyz = -r3.xyz + r12.xyz;
	ps = dilation.x * r1.y;
	r0.x = ps;
	r2.xyz = r1.xzw * c244.zzz + c251.xxx;
	r1.x = dot(r2.zxy, r2.zxy);
	ps = saturate(c244.x * r0.y);
	r17.w = ps;
	r0.y = r0.x * cateye_factor.x;
	ps = r17.w * r17.w;
	r1.w = ps;
	r1.y = dot(r9.zxy, r9.zxy);
	ps = cateye_power.x * r0.y;
	r0.y = ps;
	r3.xyzw = -r17.xyzw + c249.zzzw;
	ps = eyeball_size.x * r0.y;
	r0.y = ps;
	r0.x = r3.w + -r17.w;
	ps = clamp(rsqrt(abs(r1.y)), FLT_MIN, FLT_MAX);
	r1.y = ps;
	r12.xyz = r9.xyz * r1.yyy;
	ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r9.xyz = r2.zxy * r1.xxx;
	ps = iris_min.x * r0.y;
	r0.y = ps;
	r1.xyz = r9.xxx * r13.yzx;
	ps = max(r1.w, r1.w);
	r2.xyz = r12.yzx * r13.xyz;
	ps = r0.x * ps;
	r0.x = ps;
	r10.x = r0.x * -r7.x + r7.x;
	r7.xy = r0.xx * -r7.yz + r7.yz;
	r3.xyz = r0.xxx * r3.xyz + r17.xyz;
	r2.xyz = r12.zxy * r13.zxy + -r2.xyz;
	ps = refraction.x * r0.y;
	r0.y = ps;
	r12.xyz = r2.zxy * r13.zxy;
	ps = iris_size.x * r0.y;
	r0.y = ps;
	r12.xyz = r2.yzx * r13.xyz + -r12.xyz;
	r3.xyz = r3.xyz * brightness_scale.xxx;
	ps = iris_offset.x * r0.y;
	r0.y = ps;
	r1.xyz = r9.zzz * r12.xyz + r1.xyz;
	r1.yzw = r9.yyy * r2.xyz + r1.xyz;
	r1.x = dot(r1.wyz, r1.wyz);
	ps = lens_factor.x * r0.y;
	r2.x = ps;
	r14.x = r2.x * c244.y;
	ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r1.xyz = r1.yzw * r1.xxx;
	p0 = g_LightingPassCount.x == 0.0;
	ps = p0 ? 0.0 : 1.0;
	r9.xyz = select(use_bumpmap.xxx > 0.0, r1.xyz, r16.xyz);
	if (p0)
	{
		r1.xyz = select(c248.xxy == 0.0, r4.wyy, r15.yyy);
		r2.xyz = r3.xyz + -r11.xyz;
		r2.xyz = r5.www * r2.xyz + r11.xyz;
		r0.y = dot(r6.xyz, r1.xyz);
		r1.x = saturate(dot(r9.zxy, r8.zxy));
		ps = saturate(max(r0.y, r0.y));
		r1.y = ps;
		r0.y = r0.y + -c251.x;
		ps = clamp(log2(r1.x), FLT_MIN, FLT_MAX);
		r1.x = ps;
		r0.y = saturate(r0.y * c253.z);
		ps = clamp(log2(r1.y), FLT_MIN, FLT_MAX);
		r1.y = ps;
		r7.w = -r0.y * c244.z + c252.w;
		r1.xy = r1.xy * c246.zz;
		r7.z = -r0.x + c252.x;
		ps = exp2(r1.x);
		r0.x = ps;
		r1.z = r0.y * r0.y;
		ps = exp2(r1.y);
		r0.y = ps;
		r1.xy = r0.xy * c248.zw;
		r0.xy = r1.xz * r7.zw;
		ps = c252.x - r0.y;
		r0.y = ps;
		r12.xyz = r14.wyz * reflection_factor2.xxx;
		ps = clamp(log2(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		ps = glass_power.x * r0.y;
		r0.y = ps;
		r2.xyz = r2.xyz * g_SceneAmbient.xyz;
		ps = exp2(r0.y);
		r0.y = ps;
		ps = glass_factor.x * r0.y;
		r1.w = ps;
		r2.xyz = r2.xyz * ambient_factor.xxx + r1.www;
		r2.xyz = r12.xyz * g_SceneAmbient.xyz + r2.xyz;
		r1.xyz = r2.xyz + r1.yyy;
		r14.xyz = r1.xyz + r0.xxx;
	}
	else
	{
		r14.yz = max(r14.xx, r14.xx);
	}
	ps = -abs(r0.x) > 0.0;
	r0.x = ps;
	int aLSave0 = aL;
	uint loopConst0 = g_LoopConstant(16);
	[loop] for (uint loopIt0 = 0; loopIt0 < LOOP_COUNT(loopConst0); loopIt0++)
	{
		aL = LOOP_START(loopConst0) + int(loopIt0) * LOOP_STEP(loopConst0);
		ps = c252.w * r0.x;
		r0.y = ps;
		r0.x = r0.x + c252.x;
		ps = max(r0.y, r0.y);
		a0 = (int)clamp(floor(r0.y + 0.5), -256.0, 255.0);
		r1.yzw = -r5.xyz * CONST_REL(66 + a0).www + CONST_REL(66 + a0).xyz;
		r1.x = dot(r1.wyz, r1.wyz);
		r0.y = r1.x * CONST_REL(65 + a0).y;
		ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
		r1.x = ps;
		r16.xyz = r1.yzw * r1.xxx;
		r1.zw = r16.zz * r15.xy;
		r17.w = saturate(dot(r16.zxy, r9.zxy));
		r2.xyz = r16.xyz + r6.xyz;
		r12.xyz = r16.xyz + r8.xyz;
		ps = clamp(log2(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r0.y = r0.y * CONST_REL(65 + a0).z;
		r1.x = dot(r12.zxy, r12.zxy);
		r1.y = dot(r2.zxy, r2.zxy);
		ps = saturate(exp2(r0.y));
		r0.y = ps;
		r0.y = -r0.y + c252.x;
		ps = clamp(rsqrt(abs(r1.y)), FLT_MIN, FLT_MAX);
		r1.y = ps;
		r2.xyz = r2.zxy * r1.yyy;
		ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
		r1.x = ps;
		r13.xyz = r12.xyz * r1.xxx;
		r12.xyz = r0.yyy * CONST_REL(64 + a0).xyz;
		r17.xyz = r12.xyz * specular_color2.xyz;
		r0.y = saturate(dot(r13.zxy, r9.zxy));
		r1.xy = r2.xx * r15.yx;
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r7.w = ps;
		r13.y = saturate(dot(r2.yz, r4.zx) + r1.y);
		r13.z = saturate(dot(r16.xy, r4.zx) + r1.z);
		r13.w = saturate(dot(r16.xy, r4.wy) + r1.w);
		r13.x = saturate(dot(r2.yz, r4.wy) + r1.x);
		r1.xyw = r12.xyz * r17.www;
		ps = clamp(log2(r13.x), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r2.xyz = r12.xyz * r13.zzz;
		ps = clamp(log2(r13.y), FLT_MIN, FLT_MAX);
		r7.z = ps;
		r16.xy = r7.zw * specular_power.xx;
		ps = specular_power2.x * r0.y;
		r1.z = ps;
		r18.xyz = r2.xyz * r11.xyz;
		ps = exp2(r1.z);
		r1.z = ps;
		r19.xyz = r1.xyw * r3.xyz + -r18.xyz;
		r1.x = r17.x * r1.z;
		ps = exp2(r16.x);
		r1.y = ps;
		r7.zw = r12.yz * r7.xy;
		r2.xyzw = r12.xxyz * r10.xyzw;
		r12.xyz = r12.xyz * r13.www;
		r18.xyz = r5.www * r19.xyz + r18.xyz;
		r1.zw = r13.zw * r1.yz;
		r14.xyz = r18.xyz + r14.xyz;
		ps = exp2(r16.y);
		r1.y = ps;
		r2.xyzw = r2.xyzw * r1.yzzz;
		r1.yzw = r17.yzw * r1.wwy;
		ps = max(r2.x, r2.x);
		r16.xy = r7.zw * r1.ww;
		ps = r17.w * ps;
		r16.z = ps;
		r16.xyz = r16.xyz + -r2.zwy;
		ps = max(r1.x, r1.x);
		r2.xyz = r5.www * r16.xyz + r2.zwy;
		r2.xyz = r14.zyx + r2.yxz;
		ps = r13.w * ps;
		r1.x = ps;
		r2.xyz = r12.yzx * diffuse_color2.yzx + r2.yxz;
		r14.xyz = r2.zxy + r1.xyz;
	}
	aL = aLSave0;
	p0 = g_SpotLightEnabled(0).x > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r2.xyzw = r5.zzzz * g_SpotLights(2).wxyz + g_SpotLights(3).wxyz;
		r1.xyz = -r5.xyz + g_SpotLights(7).xyz;
		r2.xyzw = r5.yyyy * g_SpotLights(1).wxyz + r2.xyzw;
		r2.xyzw = r5.xxxx * g_SpotLights(0).zyxw + r2.wzyx;
		r0.x = dot(r1.zxy, r1.zxy);
		ps = g_SpotLights(5).z * r0.x;
		r1.w = ps;
		ps = clamp(log2(abs(r1.w)), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r1.w = r1.w * g_SpotLights(5).w;
		ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r1.xyz = r1.xyz * r0.xxx;
		ps = saturate(exp2(r1.w));
		r0.x = ps;
		r0.x = -r0.x + c252.x;
		p0 = -r2.w > 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = -abs(r0.x) > 0.0;
			r0.x = ps;
		}
		ps = clamp(rcp(r2.w), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r22.xyz = r2.xyz * r0.yyy;
		r2.xy = saturate(max(r22.zy, r22.zy));
		r7.zw = r2.xy * g_SpotLights(9).xy + g_SpotLights(9).zw;
		r13.xyzw = r7.wzwz + c254.xyzw;
		r12.xyzw = r7.wzwz + c255.xyzw;
// conan_tfetch slot=5 mag=3 min=3 mip=3 aniso=7
		r2.xyz = tfetch2D(g_LightCookie0_Texture2DDescriptorIndex, g_LightCookie0_SamplerDescriptorIndex, r22.zy, float2(0, 0)).xyz;
		r18.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.yx, float2(0, 0)).xy;
		r18.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.wz, float2(0, 0)).xy;
		r20.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0, 0)).xy;
		r20.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0, 0)).xy;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r19.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r19.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r19.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r19.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r17.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r17.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r17.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r17.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r21.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r21.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r21.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r21.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r12.yx, float2(0.5, 0.5)).x;
		r13.yzw = r1.xyz + r6.xyz;
		r12.xyw = r1.xyz + r8.xyz;
		r0.y = dot(r12.wxy, r12.wxy);
		r1.w = dot(r13.wyz, r13.wyz);
		r2.w = max(r22.x, c248.x);
		r16.xyzw = r16.xyzw > r2.wwww;
		r22.xyzw = r21.xyzw > r2.wwww;
		r17.xyzw = r17.xyzw > r2.wwww;
		r19.xyzw = r19.xyzw > r2.wwww;
		ps = max(r1.z, r1.z);
		r21.xyzw = r19.yxwz != c248.xxxx;
		ps = r15.x * ps;
		r12.z = ps;
		r19.xyzw = r17.yxwz != c248.xxxx;
		ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r17.xyzw = r16.yxwz != c248.xxxx;
		ps = r22.y != 0.0;
		r13.x = ps;
		r16.xyz = r13.wyz * r1.www;
		ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r12.xyw = r12.xyw * r0.yyy;
		ps = r22.x != 0.0;
		r13.y = ps;
		r0.y = saturate(dot(r12.wxy, r9.zxy));
		ps = r22.w != 0.0;
		r13.z = ps;
		r12.xy = r16.xx * r15.yx;
		ps = r22.z != 0.0;
		r13.w = ps;
		r17.xyzw = r17.yxwz + -r13.yxwz;
		ps = max(r1.z, r1.z);
		r21.xyzw = r21.yxwz + -r19.yxwz;
		ps = r15.y * ps;
		r12.w = ps;
		r19.xyzw = r21.xyzw * r20.zzxx + r19.yxwz;
		r17.xyzw = r17.xyzw * r18.zzxx + r13.yxwz;
		r13.z = saturate(dot(r1.xy, r4.zx) + r12.z);
		r13.w = saturate(dot(r1.xy, r4.wy) + r12.w);
		r13.x = saturate(dot(r16.yz, r4.wy) + r12.x);
		r13.y = saturate(dot(r16.yz, r4.zx) + r12.y);
		r12.xy = r19.yw + -r19.xz;
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r16.y = ps;
		r12.xy = r12.xy * r20.wy + r19.xz;
		r12.zw = r17.yw + -r17.xz;
		ps = clamp(log2(r13.x), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r12.zw = r12.zw * r18.wy + r17.xz;
		ps = clamp(log2(r13.y), FLT_MIN, FLT_MAX);
		r16.x = ps;
		r17.w = saturate(dot(r1.zxy, r9.zxy));
		ps = specular_power2.x * r0.y;
		r1.y = ps;
		r1.xw = r16.xy * specular_power.xx;
		ps = exp2(r1.y);
		r16.y = ps;
		r1.y = dot(r12.xywz, c248.zzzz);
		ps = exp2(r1.x);
		r16.x = ps;
		r1.y = select(-r7.z > 0.0, c252.x, r1.y);
		r1.y = select(-abs(g_SpotLights(6).x) >= 0.0, abs(c252.x), r1.y);
		r2.xyz = r1.yyy * r2.xyz;
		ps = max(r13.z, r13.z);
		r2.xyz = r2.xyz * g_SpotLights(4).xyz;
		ps = r16.x * ps;
		r1.y = ps;
		r2.xyz = r2.xyz * r0.xxx;
		ps = max(r13.w, r13.w);
		r17.xyz = r2.xyz * specular_color2.xyz;
		ps = r16.y * ps;
		r1.z = ps;
		r12.xyz = r2.xyz * r13.www;
		ps = max(r2.y, r2.y);
		r19.xyz = r2.xyz * r17.www;
		ps = r7.x * ps;
		r7.z = ps;
		r18.xyz = r2.xyz * r13.zzz;
		ps = max(r2.z, r2.z);
		r2.xyzw = r2.xxyz * r10.xyzw;
		ps = r7.y * ps;
		r7.w = ps;
		r18.xyz = r18.xyz * r11.xyz;
		ps = exp2(r1.w);
		r1.x = ps;
		r2.xyzw = r2.xyzw * r1.xyyy;
		ps = max(r17.x, r17.x);
		r19.xyz = r19.xyz * r3.xyz + -r18.xyz;
		r1.yzw = r17.yzw * r1.zzx;
		ps = r16.y * ps;
		r1.x = ps;
		r16.xy = r7.zw * r1.ww;
		ps = max(r2.x, r2.x);
		r18.xyz = r5.www * r19.xyz + r18.xyz;
		r14.xyz = r18.xyz + r14.xyz;
		ps = r17.w * ps;
		r16.z = ps;
		r16.xyz = r16.xyz + -r2.zwy;
		ps = max(r1.x, r1.x);
		r2.xyz = r5.www * r16.xyz + r2.zwy;
		r2.xyz = r14.zyx + r2.yxz;
		ps = r13.w * ps;
		r1.x = ps;
		r2.xyz = r12.yzx * diffuse_color2.yzx + r2.yxz;
		r14.xyz = r2.zxy + r1.xyz;
		p0 = g_SpotLightEnabled(1).x > 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			r1.xyzw = r5.zzzz * g_SpotLights(12).wxyz + g_SpotLights(13).wxyz;
			r2.xyz = -r5.xyz + g_SpotLights(17).xyz;
			r1.xyzw = r5.yyyy * g_SpotLights(11).wxyz + r1.xyzw;
			r1.xyzw = r5.xxxx * g_SpotLights(10).zyxw + r1.wzyx;
			r0.x = dot(r2.zxy, r2.zxy);
			ps = g_SpotLights(15).z * r0.x;
			r2.w = ps;
			ps = clamp(log2(abs(r2.w)), FLT_MIN, FLT_MAX);
			r2.w = ps;
			r2.w = r2.w * g_SpotLights(15).w;
			ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
			r0.x = ps;
			r2.xyz = r2.xyz * r0.xxx;
			ps = saturate(exp2(r2.w));
			r0.x = ps;
			r0.x = -r0.x + c252.x;
			p0 = -r1.w > 0.0;
			ps = p0 ? 0.0 : 1.0;
			if (p0)
			{
				ps = -abs(r0.x) > 0.0;
				r0.x = ps;
			}
			ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r22.xyz = r1.xyz * r0.yyy;
			r1.xy = saturate(max(r22.zy, r22.zy));
			r7.zw = r1.xy * g_SpotLights(19).xy + g_SpotLights(19).zw;
			r13.xyzw = r7.wzwz + c254.xyzw;
			r1.xyzw = r7.wzwz + c255.xyzw;
// conan_tfetch slot=6 mag=3 min=3 mip=3 aniso=7
			r12.xyz = tfetch2D(g_LightCookie1_Texture2DDescriptorIndex, g_LightCookie1_SamplerDescriptorIndex, r22.zy, float2(0, 0)).xyz;
			r17.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0, 0)).xy;
			r17.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0, 0)).xy;
			r19.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0, 0)).xy;
			r19.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0, 0)).xy;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r20.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r20.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r20.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r20.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r18.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r18.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r18.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r18.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r21.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r21.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r21.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r21.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0.5, 0.5)).x;
			r13.yzw = r2.xyz + r6.xyz;
			r1.xyw = r2.xyz + r8.xyz;
			r0.y = dot(r1.wxy, r1.wxy);
			r2.w = dot(r13.wyz, r13.wyz);
			r1.z = max(r22.x, c248.x);
			r16.xyzw = r16.xyzw > r1.zzzz;
			r22.xyzw = r21.xyzw > r1.zzzz;
			r18.xyzw = r18.xyzw > r1.zzzz;
			r20.xyzw = r20.xyzw > r1.zzzz;
			ps = max(r2.z, r2.z);
			r21.xyzw = r20.yxwz != c248.xxxx;
			ps = r15.x * ps;
			r1.z = ps;
			r18.xyzw = r18.yxwz != c248.xxxx;
			ps = clamp(rsqrt(abs(r2.w)), FLT_MIN, FLT_MAX);
			r2.w = ps;
			r16.xyzw = r16.yxwz != c248.xxxx;
			ps = r22.y != 0.0;
			r13.x = ps;
			r20.xyz = r13.wyz * r2.www;
			ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r1.xyw = r1.xyw * r0.yyy;
			ps = r22.x != 0.0;
			r13.y = ps;
			r0.y = saturate(dot(r1.wxy, r9.zxy));
			ps = r22.w != 0.0;
			r13.z = ps;
			r1.xy = r20.xx * r15.yx;
			ps = r22.z != 0.0;
			r13.w = ps;
			r16.xyzw = r16.yxwz + -r13.yxwz;
			ps = max(r2.z, r2.z);
			r21.xyzw = r21.yxwz + -r18.yxwz;
			ps = r15.y * ps;
			r1.w = ps;
			r18.xyzw = r21.xyzw * r19.zzxx + r18.yxwz;
			r16.xyzw = r16.xyzw * r17.zzxx + r13.yxwz;
			r13.z = saturate(dot(r2.xy, r4.zx) + r1.z);
			r13.w = saturate(dot(r2.xy, r4.wy) + r1.w);
			r13.x = saturate(dot(r20.yz, r4.wy) + r1.x);
			r13.y = saturate(dot(r20.yz, r4.zx) + r1.y);
			r20.xy = r18.yw + -r18.xz;
			ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
			r1.z = ps;
			r18.xy = r20.xy * r19.wy + r18.xz;
			r1.xy = r16.yw + -r16.xz;
			ps = clamp(log2(r13.x), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r18.zw = r1.xy * r17.wy + r16.xz;
			ps = clamp(log2(r13.y), FLT_MIN, FLT_MAX);
			r1.x = ps;
			r17.w = saturate(dot(r2.zxy, r9.zxy));
			ps = specular_power2.x * r0.y;
			r1.y = ps;
			r1.xw = r1.xz * specular_power.xx;
			ps = exp2(r1.y);
			r16.y = ps;
			r1.y = dot(r18.xywz, c248.zzzz);
			ps = exp2(r1.x);
			r16.x = ps;
			r1.y = select(-r7.z > 0.0, c252.x, r1.y);
			r1.y = select(-abs(g_SpotLights(16).x) >= 0.0, abs(c252.x), r1.y);
			r2.xyz = r1.yyy * r12.xyz;
			ps = max(r13.z, r13.z);
			r2.xyz = r2.xyz * g_SpotLights(14).xyz;
			ps = r16.x * ps;
			r1.y = ps;
			r2.xyz = r2.xyz * r0.xxx;
			ps = max(r13.w, r13.w);
			r17.xyz = r2.xyz * specular_color2.xyz;
			ps = r16.y * ps;
			r1.z = ps;
			r12.xyz = r2.xyz * r13.www;
			ps = max(r2.y, r2.y);
			r19.xyz = r2.xyz * r17.www;
			ps = r7.x * ps;
			r7.z = ps;
			r18.xyz = r2.xyz * r13.zzz;
			ps = max(r2.z, r2.z);
			r2.xyzw = r2.xxyz * r10.xyzw;
			ps = r7.y * ps;
			r7.w = ps;
			r18.xyz = r18.xyz * r11.xyz;
			ps = exp2(r1.w);
			r1.x = ps;
			r2.xyzw = r2.xyzw * r1.xyyy;
			ps = max(r17.x, r17.x);
			r19.xyz = r19.xyz * r3.xyz + -r18.xyz;
			r1.yzw = r17.yzw * r1.zzx;
			ps = r16.y * ps;
			r1.x = ps;
			r16.xy = r7.zw * r1.ww;
			ps = max(r2.x, r2.x);
			r18.xyz = r5.www * r19.xyz + r18.xyz;
			r14.xyz = r18.xyz + r14.xyz;
			ps = r17.w * ps;
			r16.z = ps;
			r16.xyz = r16.xyz + -r2.zwy;
			ps = max(r1.x, r1.x);
			r2.xyz = r5.www * r16.xyz + r2.zwy;
			r2.xyz = r14.zyx + r2.yxz;
			ps = r13.w * ps;
			r1.x = ps;
			r2.xyz = r12.yzx * diffuse_color2.yzx + r2.yxz;
			r14.xyz = r2.zxy + r1.xyz;
			p0 = g_SpotLightEnabled(2).x > 0.0;
			ps = p0 ? 0.0 : 1.0;
			if (p0)
			{
				r1.xyzw = r5.zzzz * g_SpotLights(22).wxyz + g_SpotLights(23).wxyz;
				r2.xyz = -r5.xyz + g_SpotLights(27).xyz;
				r1.xyzw = r5.yyyy * g_SpotLights(21).wxyz + r1.xyzw;
				r1.xyzw = r5.xxxx * g_SpotLights(20).zyxw + r1.wzyx;
				r0.x = dot(r2.zxy, r2.zxy);
				ps = g_SpotLights(25).z * r0.x;
				r2.w = ps;
				ps = clamp(log2(abs(r2.w)), FLT_MIN, FLT_MAX);
				r2.w = ps;
				r2.w = r2.w * g_SpotLights(25).w;
				ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
				r0.x = ps;
				r2.xyz = r2.xyz * r0.xxx;
				ps = saturate(exp2(r2.w));
				r0.x = ps;
				r0.x = -r0.x + c252.x;
				p0 = -r1.w > 0.0;
				ps = p0 ? 0.0 : 1.0;
				if (p0)
				{
					ps = -abs(r0.x) > 0.0;
					r0.x = ps;
				}
				ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r22.xyz = r1.xyz * r0.yyy;
				r1.xy = saturate(max(r22.zy, r22.zy));
				r7.zw = r1.xy * g_SpotLights(29).xy + g_SpotLights(29).zw;
				r13.xyzw = r7.wzwz + c254.xyzw;
				r1.xyzw = r7.wzwz + c255.xyzw;
// conan_tfetch slot=7 mag=3 min=3 mip=3 aniso=7
				r12.xyz = tfetch2D(g_LightCookie2_Texture2DDescriptorIndex, g_LightCookie2_SamplerDescriptorIndex, r22.zy, float2(0, 0)).xyz;
				r17.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0, 0)).xy;
				r17.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0, 0)).xy;
				r19.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0, 0)).xy;
				r19.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0, 0)).xy;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r20.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r20.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r20.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r20.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r18.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r18.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r18.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r18.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r21.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r21.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r21.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r21.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
				r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0.5, 0.5)).x;
				r13.yzw = r2.xyz + r6.xyz;
				r1.xyw = r2.xyz + r8.xyz;
				r0.y = dot(r1.wxy, r1.wxy);
				r2.w = dot(r13.wyz, r13.wyz);
				r1.z = max(r22.x, c248.x);
				r16.xyzw = r16.xyzw > r1.zzzz;
				r22.xyzw = r21.xyzw > r1.zzzz;
				r18.xyzw = r18.xyzw > r1.zzzz;
				r20.xyzw = r20.xyzw > r1.zzzz;
				ps = max(r2.z, r2.z);
				r21.xyzw = r20.yxwz != c248.xxxx;
				ps = r15.x * ps;
				r1.z = ps;
				r18.xyzw = r18.yxwz != c248.xxxx;
				ps = clamp(rsqrt(abs(r2.w)), FLT_MIN, FLT_MAX);
				r2.w = ps;
				r16.xyzw = r16.yxwz != c248.xxxx;
				ps = r22.y != 0.0;
				r13.x = ps;
				r20.xyz = r13.wyz * r2.www;
				ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r1.xyw = r1.xyw * r0.yyy;
				ps = r22.x != 0.0;
				r13.y = ps;
				r0.y = saturate(dot(r1.wxy, r9.zxy));
				ps = r22.w != 0.0;
				r13.z = ps;
				r1.xy = r20.xx * r15.yx;
				ps = r22.z != 0.0;
				r13.w = ps;
				r16.xyzw = r16.yxwz + -r13.yxwz;
				ps = max(r2.z, r2.z);
				r21.xyzw = r21.yxwz + -r18.yxwz;
				ps = r15.y * ps;
				r1.w = ps;
				r18.xyzw = r21.xyzw * r19.zzxx + r18.yxwz;
				r16.xyzw = r16.xyzw * r17.zzxx + r13.yxwz;
				r13.z = saturate(dot(r2.xy, r4.zx) + r1.z);
				r13.w = saturate(dot(r2.xy, r4.wy) + r1.w);
				r13.x = saturate(dot(r20.yz, r4.wy) + r1.x);
				r13.y = saturate(dot(r20.yz, r4.zx) + r1.y);
				r20.xy = r18.yw + -r18.xz;
				ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
				r1.z = ps;
				r18.xy = r20.xy * r19.wy + r18.xz;
				r1.xy = r16.yw + -r16.xz;
				ps = clamp(log2(r13.x), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r18.zw = r1.xy * r17.wy + r16.xz;
				ps = clamp(log2(r13.y), FLT_MIN, FLT_MAX);
				r1.x = ps;
				r17.w = saturate(dot(r2.zxy, r9.zxy));
				ps = specular_power2.x * r0.y;
				r1.y = ps;
				r1.xw = r1.xz * specular_power.xx;
				ps = exp2(r1.y);
				r16.y = ps;
				r1.y = dot(r18.xywz, c248.zzzz);
				ps = exp2(r1.x);
				r16.x = ps;
				r1.y = select(-r7.z > 0.0, c252.x, r1.y);
				r1.y = select(-abs(g_SpotLights(26).x) >= 0.0, abs(c252.x), r1.y);
				r2.xyz = r1.yyy * r12.xyz;
				ps = max(r13.z, r13.z);
				r2.xyz = r2.xyz * g_SpotLights(24).xyz;
				ps = r16.x * ps;
				r1.y = ps;
				r2.xyz = r2.xyz * r0.xxx;
				ps = max(r13.w, r13.w);
				r17.xyz = r2.xyz * specular_color2.xyz;
				ps = r16.y * ps;
				r1.z = ps;
				r12.xyz = r2.xyz * r13.www;
				ps = max(r2.y, r2.y);
				r19.xyz = r2.xyz * r17.www;
				ps = r7.x * ps;
				r7.z = ps;
				r18.xyz = r2.xyz * r13.zzz;
				ps = max(r2.z, r2.z);
				r2.xyzw = r2.xxyz * r10.xyzw;
				ps = r7.y * ps;
				r7.w = ps;
				r18.xyz = r18.xyz * r11.xyz;
				ps = exp2(r1.w);
				r1.x = ps;
				r2.xyzw = r2.xyzw * r1.xyyy;
				ps = max(r17.x, r17.x);
				r19.xyz = r19.xyz * r3.xyz + -r18.xyz;
				r1.yzw = r17.yzw * r1.zzx;
				ps = r16.y * ps;
				r1.x = ps;
				r16.xy = r7.zw * r1.ww;
				ps = max(r2.x, r2.x);
				r18.xyz = r5.www * r19.xyz + r18.xyz;
				r14.xyz = r18.xyz + r14.xyz;
				ps = r17.w * ps;
				r16.z = ps;
				r16.xyz = r16.xyz + -r2.zwy;
				ps = max(r1.x, r1.x);
				r2.xyz = r5.www * r16.xyz + r2.zwy;
				r2.xyz = r14.zyx + r2.yxz;
				ps = r13.w * ps;
				r1.x = ps;
				r2.xyz = r12.yzx * diffuse_color2.yzx + r2.yxz;
				r14.xyz = r2.zxy + r1.xyz;
				p0 = g_SpotLightEnabled(3).x > 0.0;
				ps = p0 ? 0.0 : 1.0;
				if (p0)
				{
					r1.xyzw = r5.zzzz * g_SpotLights(32).wxyz + g_SpotLights(33).wxyz;
					r2.xyz = -r5.xyz + g_SpotLights(37).xyz;
					r1.xyzw = r5.yyyy * g_SpotLights(31).wxyz + r1.xyzw;
					r1.xyzw = r5.xxxx * g_SpotLights(30).zyxw + r1.wzyx;
					r0.x = dot(r2.zxy, r2.zxy);
					ps = g_SpotLights(35).z * r0.x;
					r2.w = ps;
					ps = clamp(log2(abs(r2.w)), FLT_MIN, FLT_MAX);
					r2.w = ps;
					r2.w = r2.w * g_SpotLights(35).w;
					ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
					r0.x = ps;
					r2.xyz = r2.xyz * r0.xxx;
					ps = saturate(exp2(r2.w));
					r0.x = ps;
					r0.x = -r0.x + c252.x;
					p0 = -r1.w > 0.0;
					ps = p0 ? 0.0 : 1.0;
					if (p0)
					{
						ps = -abs(r0.x) > 0.0;
						r0.x = ps;
					}
					ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r22.xyz = r1.xyz * r0.yyy;
					r1.xy = saturate(max(r22.zy, r22.zy));
					r7.zw = r1.xy * g_SpotLights(39).xy + g_SpotLights(39).zw;
					r13.xyzw = r7.wzwz + c254.xyzw;
					r1.xyzw = r7.wzwz + c255.xyzw;
// conan_tfetch slot=8 mag=3 min=3 mip=3 aniso=7
					r12.xyz = tfetch2D(g_LightCookie3_Texture2DDescriptorIndex, g_LightCookie3_SamplerDescriptorIndex, r22.zy, float2(0, 0)).xyz;
					r17.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0, 0)).xy;
					r17.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0, 0)).xy;
					r19.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0, 0)).xy;
					r19.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0, 0)).xy;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r20.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r20.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r20.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r20.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r18.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r18.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r18.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r18.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r13.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r21.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r21.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r21.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r21.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
					r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0.5, 0.5)).x;
					r13.yzw = r2.xyz + r6.xyz;
					r1.xyw = r2.xyz + r8.xyz;
					r0.y = dot(r1.wxy, r1.wxy);
					r2.w = dot(r13.wyz, r13.wyz);
					r1.z = max(r22.x, c248.x);
					r16.xyzw = r16.xyzw > r1.zzzz;
					r22.xyzw = r21.xyzw > r1.zzzz;
					r18.xyzw = r18.xyzw > r1.zzzz;
					r20.xyzw = r20.xyzw > r1.zzzz;
					ps = max(r2.z, r2.z);
					r21.xyzw = r20.yxwz != c248.xxxx;
					ps = r15.x * ps;
					r1.z = ps;
					r18.xyzw = r18.yxwz != c248.xxxx;
					ps = clamp(rsqrt(abs(r2.w)), FLT_MIN, FLT_MAX);
					r2.w = ps;
					r16.xyzw = r16.yxwz != c248.xxxx;
					ps = r22.y != 0.0;
					r13.x = ps;
					r20.xyz = r13.wyz * r2.www;
					ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r1.xyw = r1.xyw * r0.yyy;
					ps = r22.x != 0.0;
					r13.y = ps;
					r0.y = saturate(dot(r1.wxy, r9.zxy));
					ps = r22.w != 0.0;
					r13.z = ps;
					r1.xy = r20.xx * r15.yx;
					ps = r22.z != 0.0;
					r13.w = ps;
					r16.xyzw = r16.yxwz + -r13.yxwz;
					ps = max(r2.z, r2.z);
					r21.xyzw = r21.yxwz + -r18.yxwz;
					ps = r15.y * ps;
					r1.w = ps;
					r18.xyzw = r21.xyzw * r19.zzxx + r18.yxwz;
					r16.xyzw = r16.xyzw * r17.zzxx + r13.yxwz;
					r13.z = saturate(dot(r2.xy, r4.zx) + r1.z);
					r13.w = saturate(dot(r2.xy, r4.wy) + r1.w);
					r13.x = saturate(dot(r20.yz, r4.wy) + r1.x);
					r13.y = saturate(dot(r20.yz, r4.zx) + r1.y);
					r20.xy = r18.yw + -r18.xz;
					ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
					r1.z = ps;
					r18.xy = r20.xy * r19.wy + r18.xz;
					r1.xy = r16.yw + -r16.xz;
					ps = clamp(log2(r13.x), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r18.zw = r1.xy * r17.wy + r16.xz;
					ps = clamp(log2(r13.y), FLT_MIN, FLT_MAX);
					r1.x = ps;
					r17.w = saturate(dot(r2.zxy, r9.zxy));
					ps = specular_power2.x * r0.y;
					r1.y = ps;
					r1.xw = r1.xz * specular_power.xx;
					ps = exp2(r1.y);
					r16.y = ps;
					r1.y = dot(r18.xywz, c248.zzzz);
					ps = exp2(r1.x);
					r16.x = ps;
					r1.y = select(-r7.z > 0.0, c252.x, r1.y);
					r1.y = select(-abs(g_SpotLights(36).x) >= 0.0, abs(c252.x), r1.y);
					r2.xyz = r1.yyy * r12.xyz;
					ps = max(r13.z, r13.z);
					r2.xyz = r2.xyz * g_SpotLights(34).xyz;
					ps = r16.x * ps;
					r1.y = ps;
					r2.xyz = r2.xyz * r0.xxx;
					ps = max(r13.w, r13.w);
					r17.xyz = r2.xyz * specular_color2.xyz;
					ps = r16.y * ps;
					r1.z = ps;
					r12.xyz = r2.xyz * r13.www;
					ps = max(r2.y, r2.y);
					r19.xyz = r2.xyz * r17.www;
					ps = r7.x * ps;
					r7.z = ps;
					r18.xyz = r2.xyz * r13.zzz;
					ps = max(r2.z, r2.z);
					r2.xyzw = r2.xxyz * r10.xyzw;
					ps = r7.y * ps;
					r7.w = ps;
					r18.xyz = r18.xyz * r11.xyz;
					ps = exp2(r1.w);
					r1.x = ps;
					r2.xyzw = r2.xyzw * r1.xyyy;
					ps = max(r17.x, r17.x);
					r19.xyz = r19.xyz * r3.xyz + -r18.xyz;
					r1.yzw = r17.yzw * r1.zzx;
					ps = r16.y * ps;
					r1.x = ps;
					r16.xy = r7.zw * r1.ww;
					ps = max(r2.x, r2.x);
					r18.xyz = r5.www * r19.xyz + r18.xyz;
					r14.xyz = r18.xyz + r14.xyz;
					ps = r17.w * ps;
					r16.z = ps;
					r16.xyz = r16.xyz + -r2.zwy;
					ps = max(r1.x, r1.x);
					r2.xyz = r5.www * r16.xyz + r2.zwy;
					r2.xyz = r14.zyx + r2.yxz;
					ps = r13.w * ps;
					r1.x = ps;
					r2.xyz = r12.yzx * diffuse_color2.yzx + r2.yxz;
					r14.xyz = r2.zxy + r1.xyz;
				}
			}
		}
	}
	p0 = g_ParallelLightEnabled.x > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r16.z = max(g_ParallelLights(14).w, g_ParallelLights(14).w);
		ps = max(g_ParallelLights(15).z, g_ParallelLights(15).z);
		r1.z = ps;
		r16.y = max(g_ParallelLights(13).w, g_ParallelLights(13).w);
		ps = max(g_ParallelLights(14).z, g_ParallelLights(14).z);
		r2.z = ps;
		r16.x = max(g_ParallelLights(12).w, g_ParallelLights(12).w);
		ps = max(g_ParallelLights(13).z, g_ParallelLights(13).z);
		r2.y = ps;
		r1.xy = max(g_ParallelLights(23).zw, g_ParallelLights(23).zw);
		ps = max(g_ParallelLights(12).z, g_ParallelLights(12).z);
		r2.x = ps;
		r12.xy = max(g_ParallelLights(14).xy, g_ParallelLights(14).xy);
		ps = max(g_ParallelLights(23).y, g_ParallelLights(23).y);
		r7.w = ps;
		r12.zw = max(g_ParallelLights(13).xy, g_ParallelLights(13).xy);
		ps = max(g_ParallelLights(23).x, g_ParallelLights(23).x);
		r7.z = ps;
		r17.xyz = max(g_ParallelLights(15).wxy, g_ParallelLights(15).wxy);
		ps = max(g_ParallelLights(12).y, g_ParallelLights(12).y);
		r0.x = ps;
		r1.w = dot(g_ParallelLights(19).zxy, g_ParallelLights(19).zxy);
		ps = clamp(rcp(r0.w), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r0.z = r0.y * r0.z;
		ps = max(g_ParallelLights(12).x, g_ParallelLights(12).x);
		r0.y = ps;
		r0.w = g_ParallelLights(16).z > r0.z;
		ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r13.xyz = r1.www * g_ParallelLights(19).xyz;
		p0 = r0.w != 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = max(g_ParallelLights(11).z, g_ParallelLights(11).z);
			r1.z = ps;
		}
		if (p0)
		{
			r2.z = max(g_ParallelLights(10).z, g_ParallelLights(10).z);
			ps = max(g_ParallelLights(10).w, g_ParallelLights(10).w);
			r16.z = ps;
		}
		if (p0)
		{
			r2.y = max(g_ParallelLights(9).z, g_ParallelLights(9).z);
			ps = max(g_ParallelLights(9).w, g_ParallelLights(9).w);
			r16.y = ps;
		}
		if (p0)
		{
			r2.x = max(g_ParallelLights(8).z, g_ParallelLights(8).z);
			ps = max(g_ParallelLights(8).w, g_ParallelLights(8).w);
			r16.x = ps;
		}
		if (p0)
		{
			r7.zw = max(g_ParallelLights(22).xy, g_ParallelLights(22).xy);
			ps = max(g_ParallelLights(22).w, g_ParallelLights(22).w);
			r1.y = ps;
		}
		if (p0)
		{
			r12.xy = max(g_ParallelLights(10).xy, g_ParallelLights(10).xy);
			ps = max(g_ParallelLights(22).z, g_ParallelLights(22).z);
			r1.x = ps;
		}
		if (p0)
		{
			r0.xy = max(g_ParallelLights(8).yx, g_ParallelLights(8).yx);
			ps = max(g_ParallelLights(9).y, g_ParallelLights(9).y);
			r12.w = ps;
		}
		if (p0)
		{
			r17.xyz = max(g_ParallelLights(11).wxy, g_ParallelLights(11).wxy);
			ps = max(g_ParallelLights(9).x, g_ParallelLights(9).x);
			r12.z = ps;
		}
		r0.w = g_ParallelLights(16).y > r0.z;
		p0 = r0.w != 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = max(g_ParallelLights(7).z, g_ParallelLights(7).z);
			r1.z = ps;
		}
		if (p0)
		{
			r2.z = max(g_ParallelLights(6).z, g_ParallelLights(6).z);
			ps = max(g_ParallelLights(6).w, g_ParallelLights(6).w);
			r16.z = ps;
		}
		if (p0)
		{
			r2.y = max(g_ParallelLights(5).z, g_ParallelLights(5).z);
			ps = max(g_ParallelLights(5).w, g_ParallelLights(5).w);
			r16.y = ps;
		}
		if (p0)
		{
			r2.x = max(g_ParallelLights(4).z, g_ParallelLights(4).z);
			ps = max(g_ParallelLights(4).w, g_ParallelLights(4).w);
			r16.x = ps;
		}
		if (p0)
		{
			r7.zw = max(g_ParallelLights(21).xy, g_ParallelLights(21).xy);
			ps = max(g_ParallelLights(21).w, g_ParallelLights(21).w);
			r1.y = ps;
		}
		if (p0)
		{
			r12.xy = max(g_ParallelLights(6).xy, g_ParallelLights(6).xy);
			ps = max(g_ParallelLights(21).z, g_ParallelLights(21).z);
			r1.x = ps;
		}
		if (p0)
		{
			r0.xy = max(g_ParallelLights(4).yx, g_ParallelLights(4).yx);
			ps = max(g_ParallelLights(5).y, g_ParallelLights(5).y);
			r12.w = ps;
		}
		if (p0)
		{
			r17.xyz = max(g_ParallelLights(7).wxy, g_ParallelLights(7).wxy);
			ps = max(g_ParallelLights(5).x, g_ParallelLights(5).x);
			r12.z = ps;
		}
		r0.z = g_ParallelLights(16).x > r0.z;
		p0 = r0.z != 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = max(g_ParallelLights(3).z, g_ParallelLights(3).z);
			r1.z = ps;
		}
		if (p0)
		{
			r2.z = max(g_ParallelLights(2).z, g_ParallelLights(2).z);
			ps = max(g_ParallelLights(2).w, g_ParallelLights(2).w);
			r16.z = ps;
		}
		if (p0)
		{
			r2.y = max(g_ParallelLights(1).z, g_ParallelLights(1).z);
			ps = max(g_ParallelLights(1).w, g_ParallelLights(1).w);
			r16.y = ps;
		}
		if (p0)
		{
			r2.x = max(g_ParallelLights(0).z, g_ParallelLights(0).z);
			ps = max(g_ParallelLights(0).w, g_ParallelLights(0).w);
			r16.x = ps;
		}
		if (p0)
		{
			r7.zw = max(g_ParallelLights(20).xy, g_ParallelLights(20).xy);
			ps = max(g_ParallelLights(20).w, g_ParallelLights(20).w);
			r1.y = ps;
		}
		if (p0)
		{
			r12.xy = max(g_ParallelLights(2).xy, g_ParallelLights(2).xy);
			ps = max(g_ParallelLights(20).z, g_ParallelLights(20).z);
			r1.x = ps;
		}
		if (p0)
		{
			r0.xy = max(g_ParallelLights(0).yx, g_ParallelLights(0).yx);
			ps = max(g_ParallelLights(1).y, g_ParallelLights(1).y);
			r12.w = ps;
		}
		if (p0)
		{
			r17.xyz = max(g_ParallelLights(3).wxy, g_ParallelLights(3).wxy);
			ps = max(g_ParallelLights(1).x, g_ParallelLights(1).x);
			r12.z = ps;
		}
		r16.x = dot(r5.zxy, r16.zxy);
		r0.z = dot(r5.zy, r12.xz) + c248.x;
		r0.w = dot(r5.zy, r12.yw) + c248.x;
		r16.yz = r5.xx * r0.yx + r0.zw;
		r0.xyw = r16.xyz + r17.xyz;
		r0.z = dot(r5.zxy, r2.zxy);
		ps = clamp(rcp(r0.x), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r0.xy = saturate(r0.yw * r1.ww);
		r0.xy = r0.xy * r7.zw;
		r1.xyz = r0.xyz + r1.xyz;
		r0.xyzw = r1.yxyx + c254.xyzw;
		r19.xyzw = r1.yxyx + c255.xyzw;
		r12.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.yx, float2(0, 0)).xy;
		r12.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.wz, float2(0, 0)).xy;
		r17.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.yx, float2(0, 0)).xy;
		r17.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.wz, float2(0, 0)).xy;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r18.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r18.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r18.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r18.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r0.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r2.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r2.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r2.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r2.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r0.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r0.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r0.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
		r0.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r19.yx, float2(-0.5, 0.5)).x;
		r1.w = r1.z * r1.w;
		r1.w = max(r1.w, c248.x);
		r0.xyzw = r0.xyzw > r1.wwww;
		r2.xyzw = r2.xyzw > r1.wwww;
		r16.xyzw = r16.xyzw > r1.wwww;
		r19.xyzw = r18.xyzw > r1.wwww;
		r18.xyzw = r16.yxwz != c248.xxxx;
		ps = r19.y != 0.0;
		r16.x = ps;
		r2.xyzw = r2.yxwz != c248.xxxx;
		ps = r19.x != 0.0;
		r16.y = ps;
		r0.xyzw = r0.yxwz != c248.xxxx;
		ps = r19.w != 0.0;
		r16.z = ps;
		r2.xyzw = r2.yxwz + -r0.yxwz;
		ps = r19.z != 0.0;
		r16.w = ps;
		r18.xyzw = r18.yxwz + -r16.yxwz;
		r16.xyzw = r18.xyzw * r17.zzxx + r16.yxwz;
		r2.xyzw = r2.xyzw * r12.zzxx + r0.yxwz;
		r0.zw = r2.yw + -r2.xz;
		r0.xy = r16.yw + -r16.xz;
		p0 = abs(g_ParallelLights(18).z) > 0.0;
		ps = p0 ? 0.0 : 1.0;
		r0.xy = r0.xy * r17.wy + r16.xz;
		r0.zw = r0.zw * r12.wy + r2.xz;
		r0.x = dot(r0.xywz, c248.zzzz);
		ps = max(c252.x, c252.x);
		r0.y = ps;
		r0.x = select(-r1.x > 0.0, c252.x, r0.x);
		if (p0)
		{
			r0.yz = r5.yx * g_CloudInfo.xx + g_CloudInfo.yy;
// conan_tfetch slot=9 mag=3 min=3 mip=3 aniso=7
			r0.yzw = tfetch2D(g_ParallelLightShadowTexture_Texture2DDescriptorIndex, g_ParallelLightShadowTexture_SamplerDescriptorIndex, r0.zy, float2(0, 0)).xyz;
		}
		else
		{
			r0.zw = max(c252.xx, c252.xx);
		}
		r12.w = saturate(dot(r13.zxy, r9.zxy));
		r6.xyz = r13.xyz + r6.xyz;
		r0.xyw = r0.yzw * r0.xxx;
		r1.xyw = r13.xyz + r8.xyz;
		r0.z = dot(r1.wxy, r1.wxy);
		r2.xyz = r0.xyw * g_ParallelLights(17).xyz;
		ps = max(r13.z, r13.z);
		r0.x = dot(r6.zxy, r6.zxy);
		ps = r15.x * ps;
		r1.z = ps;
		r12.xyz = r2.xyz * specular_color2.xyz;
		ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r0.xyw = r6.xyz * r0.xxx;
		ps = clamp(rsqrt(abs(r0.z)), FLT_MIN, FLT_MAX);
		r0.z = ps;
		r1.xyw = r1.xyw * r0.zzz;
		ps = max(r13.z, r13.z);
		r0.z = saturate(dot(r1.wxy, r9.zxy));
		ps = r15.y * ps;
		r1.w = ps;
		r1.xy = r0.ww * r15.yx;
		ps = clamp(log2(r0.z), FLT_MIN, FLT_MAX);
		r0.z = ps;
		r6.y = saturate(dot(r0.xy, r4.zx) + r1.y);
		r6.z = saturate(dot(r13.xy, r4.zx) + r1.z);
		r6.w = saturate(dot(r13.xy, r4.wy) + r1.w);
		r6.x = saturate(dot(r0.xy, r4.wy) + r1.x);
		r1.xyz = r2.xyz * r12.www;
		ps = clamp(log2(r6.x), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r8.xyz = r2.xyz * r6.zzz;
		ps = clamp(log2(r6.y), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r4.zw = r0.xz * specular_power.xx;
		ps = specular_power2.x * r0.y;
		r0.x = ps;
		r8.xyz = r8.xyz * r11.xyz;
		ps = exp2(r0.x);
		r0.z = ps;
		r3.xyz = r1.xyz * r3.xyz + -r8.xyz;
		r0.x = r12.x * r0.z;
		ps = exp2(r4.z);
		r0.y = ps;
		r4.xy = r2.yz * r7.xy;
		r1.xyzw = r2.xxyz * r10.xyzw;
		r2.xyz = r2.xyz * r6.www;
		r3.xyz = r5.www * r3.xyz + r8.xyz;
		r0.zw = r6.zw * r0.yz;
		r3.xyz = r3.xyz + r14.xyz;
		ps = exp2(r4.w);
		r0.y = ps;
		r1.xyzw = r1.xyzw * r0.yzzz;
		r0.yzw = r12.yzw * r0.wwy;
		ps = max(r1.x, r1.x);
		r4.xy = r4.xy * r0.ww;
		ps = r12.w * ps;
		r4.z = ps;
		r4.xyz = r4.xyz + -r1.zwy;
		ps = max(r0.x, r0.x);
		r1.xyz = r5.www * r4.xyz + r1.zwy;
		r1.xyz = r3.zyx + r1.yxz;
		ps = r6.w * ps;
		r0.x = ps;
		r1.xyz = r2.yzx * diffuse_color2.yzx + r1.yxz;
		r14.xyz = r1.zxy + r0.xyz;
	}
	r0.xyz = r5.xyz + -eyePosition.xyz;
	r0.y = dot(r0.zxy, viewVector.zxy);
	ps = cameraNearFar.y - cameraNearFar.x;
	r0.x = ps;
	r0.y = r0.y + -cameraNearFar.x;
	ps = clamp(rcp(r0.x), FLT_MIN, FLT_MAX);
	r0.x = ps;
	r0.x = saturate(r0.y * r0.x);
	ps = -abs(r0.x) > 0.0;
	r0.y = ps;
// conan_tfetch slot=10 mag=3 min=3 mip=3 aniso=7
	r0.xyzw = tfetch2D(g_FogTable_Texture2DDescriptorIndex, g_FogTable_SamplerDescriptorIndex, r0.xy, float2(0, 0)).xyzw;
	ps = c252.x - r0.w;
	r1.x = ps;
	r1.xyz = r1.xxx * r14.xyz;
	p0 = g_LightingPassCount.x != 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
	}
	else
	{
		r1.xyz = r0.xyz * r0.www + r1.xyz;
	}
	oC0.xyz = max(r1.xyzz, r1.xyzz);
	oC0.w = 1.0;
	[branch] if (g_SpecConstants() & (SPEC_CONSTANT_SOFT_PARTICLE_RGBA | SPEC_CONSTANT_SOFT_PARTICLE_ALPHA))	{		float conanSceneZ = g_Texture2DDescriptorHeap[g_SoftParticleDepth].Load(int3(iPos.xy * g_SoftParticleTexelScale, 0)).x;
		float conanFade = saturate((rcp(conanSceneZ * g_SoftParticleW.x + g_SoftParticleW.y) - rcp(iPos.z * g_SoftParticleW.x + g_SoftParticleW.y)) / g_SoftParticleDistance);
		if (g_SpecConstants() & SPEC_CONSTANT_SOFT_PARTICLE_RGBA) oC0 *= conanFade; else oC0.w *= conanFade;
	}	[branch] if (g_SpecConstants() & SPEC_CONSTANT_ALPHA_TEST)	{		clip(oC0.w - g_AlphaThreshold);
	}	else if (g_SpecConstants() & SPEC_CONSTANT_ALPHA_TO_COVERAGE)	{		oC0.w *= 1.0 + computeMipLevel(pixelCoord) * 0.25;
		oC0.w = 0.5 + (oC0.w - g_AlphaThreshold) / max(fwidth(oC0.w), 1e-6);
	}	return;
}
#ifndef __spirv__
#ifdef CONAN_RECOMP
uint g_SpecConstants() { return g_SpecConstantsRuntime; }
#else
uint g_SpecConstants() { return 0; }
#endif
#endif
