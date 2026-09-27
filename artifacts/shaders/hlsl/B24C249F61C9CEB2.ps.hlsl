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

#define AlphaMapSampler2_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 8)
#define AlphaMapSampler2_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 72)
#define AlphaMapSampler2_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 136)
#define AlphaMapSampler2_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 200)
#define ShiftMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2560, 0x10)
#define VolumeDiffuseMapSampler_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 20)
#define VolumeDiffuseMapSampler_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 84)
#define VolumeDiffuseMapSampler_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 148)
#define VolumeDiffuseMapSampler_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 212)
#define cameraNearFar vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2704, 0x10)
#define cloud_brightness vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2768, 0x10)
#define eyePosition vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2672, 0x10)
#define g_AlphaMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 4)
#define g_AlphaMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 68)
#define g_AlphaMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 132)
#define g_AlphaMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 196)
#define g_DiffuseMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 0)
#define g_DiffuseMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 64)
#define g_DiffuseMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 128)
#define g_DiffuseMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 192)
#define g_FogTable_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 24)
#define g_FogTable_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 88)
#define g_FogTable_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 152)
#define g_FogTable_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 216)
#define g_LightingPassCount vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2576, 0x10)
#define g_LuminanceMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 12)
#define g_LuminanceMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 76)
#define g_LuminanceMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 140)
#define g_LuminanceMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 204)
#define g_ShiftMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 16)
#define g_ShiftMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 80)
#define g_ShiftMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 144)
#define g_ShiftMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 208)
#define g_fTime vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2656, 0x10)
#define g_mProjectionToWorld(INDEX) select((INDEX) < 94, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (162 + min(INDEX, 93)) * 16, 0x10), 0.0)
#define land_brightness vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2752, 0x10)
#define rate_max vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2736, 0x10)
#define rate_min vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2720, 0x10)
#define viewVector vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2688, 0x10)
#define CONST_REL(INDEX) select((uint)(INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + min((uint)(INDEX), 255) * 16, 0x10), 0.0)

#else

cbuffer PixelShaderConstants : register(b1, space4)
{
	float4 g_PixelShaderConstantsArr[256] : packoffset(c0);
};

#define CONST_REL(INDEX) select((uint)(INDEX) < 256, g_PixelShaderConstantsArr[min((uint)(INDEX), 255)], 0.0)
#define ShiftMapUVScale g_PixelShaderConstantsArr[160]
#define cameraNearFar g_PixelShaderConstantsArr[169]
#define cloud_brightness g_PixelShaderConstantsArr[173]
#define eyePosition g_PixelShaderConstantsArr[167]
#define g_LightingPassCount g_PixelShaderConstantsArr[161]
#define g_fTime g_PixelShaderConstantsArr[166]
#define g_mProjectionToWorld(INDEX) CONST_REL(162 + (INDEX))
#define land_brightness g_PixelShaderConstantsArr[172]
#define rate_max g_PixelShaderConstantsArr[171]
#define rate_min g_PixelShaderConstantsArr[170]
#define viewVector g_PixelShaderConstantsArr[168]

cbuffer SharedConstants : register(b2, space4)
{
	uint AlphaMapSampler2_Texture2DDescriptorIndex : packoffset(c0.z);
	uint AlphaMapSampler2_Texture3DDescriptorIndex : packoffset(c4.z);
	uint AlphaMapSampler2_TextureCubeDescriptorIndex : packoffset(c8.z);
	uint AlphaMapSampler2_SamplerDescriptorIndex : packoffset(c12.z);
	uint VolumeDiffuseMapSampler_Texture2DDescriptorIndex : packoffset(c1.y);
	uint VolumeDiffuseMapSampler_Texture3DDescriptorIndex : packoffset(c5.y);
	uint VolumeDiffuseMapSampler_TextureCubeDescriptorIndex : packoffset(c9.y);
	uint VolumeDiffuseMapSampler_SamplerDescriptorIndex : packoffset(c13.y);
	uint g_AlphaMapTexture_Texture2DDescriptorIndex : packoffset(c0.y);
	uint g_AlphaMapTexture_Texture3DDescriptorIndex : packoffset(c4.y);
	uint g_AlphaMapTexture_TextureCubeDescriptorIndex : packoffset(c8.y);
	uint g_AlphaMapTexture_SamplerDescriptorIndex : packoffset(c12.y);
	uint g_DiffuseMapTexture_Texture2DDescriptorIndex : packoffset(c0.x);
	uint g_DiffuseMapTexture_Texture3DDescriptorIndex : packoffset(c4.x);
	uint g_DiffuseMapTexture_TextureCubeDescriptorIndex : packoffset(c8.x);
	uint g_DiffuseMapTexture_SamplerDescriptorIndex : packoffset(c12.x);
	uint g_FogTable_Texture2DDescriptorIndex : packoffset(c1.z);
	uint g_FogTable_Texture3DDescriptorIndex : packoffset(c5.z);
	uint g_FogTable_TextureCubeDescriptorIndex : packoffset(c9.z);
	uint g_FogTable_SamplerDescriptorIndex : packoffset(c13.z);
	uint g_LuminanceMapTexture_Texture2DDescriptorIndex : packoffset(c0.w);
	uint g_LuminanceMapTexture_Texture3DDescriptorIndex : packoffset(c4.w);
	uint g_LuminanceMapTexture_TextureCubeDescriptorIndex : packoffset(c8.w);
	uint g_LuminanceMapTexture_SamplerDescriptorIndex : packoffset(c12.w);
	uint g_ShiftMapTexture_Texture2DDescriptorIndex : packoffset(c1.x);
	uint g_ShiftMapTexture_Texture3DDescriptorIndex : packoffset(c5.x);
	uint g_ShiftMapTexture_TextureCubeDescriptorIndex : packoffset(c9.x);
	uint g_ShiftMapTexture_SamplerDescriptorIndex : packoffset(c13.x);
	DEFINE_SHARED_CONSTANTS();
};

#endif
	#define Do_Land_Premult BOOL_BIT(134)
	#define Use_Alpha_Texture BOOL_BIT(129)
	#define Use_Alpha_Texture2 BOOL_BIT(132)
	#define Use_DiffuseColor_Texture BOOL_BIT(128)
	#define Use_Luminance_Texture BOOL_BIT(130)
	#define Use_Shift_Texture BOOL_BIT(133)
	#define Use_VolumeDiffuseColor_Texture BOOL_BIT(131)

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
	float4 c252 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c253 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c254 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c255 = asfloat(uint4(0x3F800000, 0x0, 0x0, 0x0));

	float4 r0 = iTexCoord0;
	float4 r1 = iTexCoord1;
	float4 r2 = iTexCoord2;
	float4 r3 = iTexCoord3;
	float4 r4 = iTexCoord4;
	float4 r5 = 0.0;
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

	r1.xyzw = r0.wwww * g_mProjectionToWorld(3).wxyz;
	r1.xyzw = r0.zzzz * g_mProjectionToWorld(2).wxyz + r1.xyzw;
	r1.xyzw = r0.yyyy * g_mProjectionToWorld(1).wxyz + r1.xyzw;
	r3.xyzw = r0.xxxx * g_mProjectionToWorld(0).wxyz + r1.xyzw;
	r1.xyzw = -abs(r0.xxxx) > c255.yyyy;
	ps = clamp(rcp(r3.x), FLT_MIN, FLT_MAX);
	r0.x = ps;
	r3.xyz = r3.yzw * r0.xxx;
	p0 = g_LightingPassCount.x == 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r0.xz = max(c255.xy, c255.xy);
		if (Use_Shift_Texture)
		{
			r0.yw = r2.yx * ShiftMapUVScale.yx;
// conan_tfetch slot=4 mag=3 min=3 mip=3 aniso=7
			r0.y = tfetch2D(g_ShiftMapTexture_Texture2DDescriptorIndex, g_ShiftMapTexture_SamplerDescriptorIndex, r0.wy, float2(0, 0)).x;
		}
		else
		{
			ps = max(c255.x, c255.x);
			r0.y = ps;
		}
		r0.w = rate_max.x + -rate_min.x;
		r0.y = r0.w * r0.y;
		r2.z = g_fTime.x * rate_min.x + r0.y;
		if (Use_Alpha_Texture2)
		{
// conan_tfetch slot=2 mag=3 min=3 mip=3 aniso=7
			r0.x = tfetch2D(AlphaMapSampler2_Texture2DDescriptorIndex, AlphaMapSampler2_SamplerDescriptorIndex, r2.xy, float2(0, 0)).x;
		}
		if (Use_VolumeDiffuseColor_Texture)
		{
// conan_tfetch slot=5 mag=3 min=3 mip=3 aniso=7
			r1.xzw = tfetch3D(VolumeDiffuseMapSampler_Texture3DDescriptorIndex, VolumeDiffuseMapSampler_SamplerDescriptorIndex, r2.xyz).xyz;
			r0.y = dot(r1.wxz, r1.wxz);
			ps = saturate(sqrt(abs(r0.y)));
			r1.y = ps;
		}
		else
		{
			r1.xyzw = -abs(r0.xxxx) > c255.yyyy;
		}
		if (!Use_DiffuseColor_Texture)
		{
			r0.y = dot(r1.wxz, r1.wxz);
			ps = sqrt(abs(r0.y));
			r1.y = ps;
		}
		ps = cloud_brightness.x * r1.y;
		r0.y = ps;
		r4.xyz = r0.yyy * r1.xzw;
		if (Use_DiffuseColor_Texture)
		{
// conan_tfetch slot=0 mag=3 min=3 mip=3 aniso=7
			pixelCoord = getPixelCoord(g_DiffuseMapTexture_Texture2DDescriptorIndex, r2.xy);
			r1.xzw = tfetch2D(g_DiffuseMapTexture_Texture2DDescriptorIndex, g_DiffuseMapTexture_SamplerDescriptorIndex, r2.xy, float2(0, 0)).xyz;
		}
		else
		{
			r1.xzw = -abs(r0.xxx) > c255.yyy;
		}
		if (Use_Alpha_Texture)
		{
// conan_tfetch slot=1 mag=3 min=3 mip=3 aniso=7
			r0.z = tfetch2D(g_AlphaMapTexture_Texture2DDescriptorIndex, g_AlphaMapTexture_SamplerDescriptorIndex, r2.xy, float2(0, 0)).x;
		}
		ps = saturate(max(r0.z, r0.z));
		r0.y = ps;
		if (Use_Luminance_Texture)
		{
// conan_tfetch slot=3 mag=3 min=3 mip=3 aniso=7
			r0.w = tfetch2D(g_LuminanceMapTexture_Texture2DDescriptorIndex, g_LuminanceMapTexture_SamplerDescriptorIndex, r2.xy, float2(0, 0)).x;
			r1.xzw = r0.www * r1.xzw;
		}
		if (Do_Land_Premult)
		{
			r1.xzw = r1.xzw * r0.yyy;
		}
		ps = c255.x - r0.z;
		r0.y = ps;
		r0.y = r0.y * r1.y;
		r1.xyz = r1.xzw * land_brightness.xxx;
		ps = cloud_brightness.x * r0.y;
		r0.w = ps;
		r2.xyz = r4.xyz * r0.www + -r1.xyz;
		r1.xyz = r0.yyy * r2.xyz + r1.xyz;
		r1.xyz = r1.xyz * r0.xxx;
		if (!Do_Land_Premult)
		{
			ps = max(c255.x, c255.x);
			r0.y = ps;
		}
		r0.y = saturate(r0.z + r0.y);
		r1.w = r0.y * r0.x;
	}
	int aLSave0 = aL;
	uint loopConst0 = g_LoopConstant(16);
	[loop] for (uint loopIt0 = 0; loopIt0 < LOOP_COUNT(loopConst0); loopIt0++)
	{
		aL = LOOP_START(loopConst0) + int(loopIt0) * LOOP_STEP(loopConst0);
	}
	aL = aLSave0;
	r0.xyz = r3.xyz + -eyePosition.xyz;
	r0.y = dot(r0.zxy, viewVector.zxy);
	ps = cameraNearFar.y - cameraNearFar.x;
	r0.x = ps;
	r0.y = r0.y + -cameraNearFar.x;
	ps = clamp(rcp(r0.x), FLT_MIN, FLT_MAX);
	r0.x = ps;
	r0.x = saturate(r0.y * r0.x);
	ps = -abs(r0.x) > 0.0;
	r0.y = ps;
// conan_tfetch slot=6 mag=3 min=3 mip=3 aniso=7
	r0.xyzw = tfetch2D(g_FogTable_Texture2DDescriptorIndex, g_FogTable_SamplerDescriptorIndex, r0.xy, float2(0, 0)).xyzw;
	ps = c255.x - r0.w;
	r2.x = ps;
	r1.xyz = r2.xxx * r1.xyz;
	p0 = g_LightingPassCount.x == 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r1.xyz = r0.xyz * r0.www + r1.xyz;
	}
	oC0.xyzw = max(r1.xyzw, r1.xyzw);
	[branch] if (g_SpecConstants() & (SPEC_CONSTANT_SOFT_PARTICLE_RGBA | SPEC_CONSTANT_SOFT_PARTICLE_ALPHA))	{		float conanSceneZ = g_Texture2DDescriptorHeap[g_SoftParticleDepth].Load(int3(iPos.xy * g_SoftParticleTexelScale, 0)).x;
		float conanFade = saturate((rcp(conanSceneZ * g_SoftParticleW.x + g_SoftParticleW.y) - rcp(iPos.z * g_SoftParticleW.x + g_SoftParticleW.y)) / g_SoftParticleDistance);
		if (g_SpecConstants() & SPEC_CONSTANT_SOFT_PARTICLE_RGBA) oC0 *= conanFade; else oC0.w *= conanFade;
	}	[branch] if (g_SpecConstants() & SPEC_CONSTANT_ALPHA_TEST)	{		clip(oC0.w - g_AlphaThreshold);
	}	else if (g_SpecConstants() & SPEC_CONSTANT_ALPHA_TO_COVERAGE)	{		oC0.w *= 1.0 + computeMipLevel(pixelCoord) * 0.25;
		oC0.w = 0.5 + (oC0.w - g_AlphaThreshold) / max(fwidth(oC0.w), 1e-6);
	}	return;
}