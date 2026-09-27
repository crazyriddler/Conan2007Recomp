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

#define AlphaMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2784, 0x10)
#define DiffuseMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2720, 0x10)
#define GlossMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2768, 0x10)
#define NormalMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2736, 0x10)
#define SpecularMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2752, 0x10)
#define Use_Alpha_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2688, 0x10)
#define Use_DiffuseColor_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2640, 0x10)
#define Use_EnvCubeMap_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2704, 0x10)
#define Use_Gloss_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2672, 0x10)
#define Use_SpecularColor_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2656, 0x10)
#define ambient_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2624, 0x10)
#define cameraNearFar vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2992, 0x10)
#define diffuse_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2592, 0x10)
#define eyePosition vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2960, 0x10)
#define g_AlphaMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 16)
#define g_AlphaMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 80)
#define g_AlphaMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 144)
#define g_AlphaMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 208)
#define g_CheapLights(INDEX) select((INDEX) < 192, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (64 + min(INDEX, 191)) * 16, 0x10), 0.0)
#define g_CloudInfo vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3008, 0x10)
#define g_DiffuseMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 4)
#define g_DiffuseMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 68)
#define g_DiffuseMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 132)
#define g_DiffuseMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 196)
#define g_EnvCubeMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 20)
#define g_EnvCubeMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 84)
#define g_EnvCubeMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 148)
#define g_EnvCubeMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 212)
#define g_FogTable_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 44)
#define g_FogTable_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 108)
#define g_FogTable_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 172)
#define g_FogTable_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 236)
#define g_GlossMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 8)
#define g_GlossMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 72)
#define g_GlossMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 136)
#define g_GlossMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 200)
#define g_LightCookie0_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 24)
#define g_LightCookie0_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 88)
#define g_LightCookie0_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 152)
#define g_LightCookie0_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 216)
#define g_LightCookie1_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 28)
#define g_LightCookie1_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 92)
#define g_LightCookie1_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 156)
#define g_LightCookie1_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 220)
#define g_LightCookie2_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 32)
#define g_LightCookie2_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 96)
#define g_LightCookie2_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 160)
#define g_LightCookie2_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 224)
#define g_LightCookie3_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 36)
#define g_LightCookie3_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 100)
#define g_LightCookie3_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 164)
#define g_LightCookie3_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 228)
#define g_LightingPassCount vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2800, 0x10)
#define g_NormalMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 0)
#define g_NormalMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 64)
#define g_NormalMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 128)
#define g_NormalMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 192)
#define g_ParallelLightEnabled vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2816, 0x10)
#define g_ParallelLightShadowTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 40)
#define g_ParallelLightShadowTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 104)
#define g_ParallelLightShadowTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 168)
#define g_ParallelLightShadowTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 232)
#define g_ParallelLights(INDEX) select((INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (0 + min(INDEX, 255)) * 16, 0x10), 0.0)
#define g_SceneAmbient vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3024, 0x10)
#define g_ShadowMapTextureAtlas_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 48)
#define g_ShadowMapTextureAtlas_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 112)
#define g_ShadowMapTextureAtlas_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 176)
#define g_ShadowMapTextureAtlas_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 240)
#define g_SpecularColorMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 12)
#define g_SpecularColorMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 76)
#define g_SpecularColorMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 140)
#define g_SpecularColorMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 204)
#define g_SpotLightEnabled(INDEX) select((INDEX) < 79, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (177 + min(INDEX, 78)) * 16, 0x10), 0.0)
#define g_SpotLights(INDEX) select((INDEX) < 232, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (24 + min(INDEX, 231)) * 16, 0x10), 0.0)
#define g_mProjectionToWorld(INDEX) select((INDEX) < 75, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (181 + min(INDEX, 74)) * 16, 0x10), 0.0)
#define specular_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2576, 0x10)
#define specular_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2560, 0x10)
#define use_bumpmap vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2608, 0x10)
#define viewVector vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2976, 0x10)
#define CONST_REL(INDEX) select((uint)(INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + min((uint)(INDEX), 255) * 16, 0x10), 0.0)

#else

cbuffer PixelShaderConstants : register(b1, space4)
{
	float4 g_PixelShaderConstantsArr[256] : packoffset(c0);
};

#define CONST_REL(INDEX) select((uint)(INDEX) < 256, g_PixelShaderConstantsArr[min((uint)(INDEX), 255)], 0.0)
#define AlphaMapUVScale g_PixelShaderConstantsArr[174]
#define DiffuseMapUVScale g_PixelShaderConstantsArr[170]
#define GlossMapUVScale g_PixelShaderConstantsArr[173]
#define NormalMapUVScale g_PixelShaderConstantsArr[171]
#define SpecularMapUVScale g_PixelShaderConstantsArr[172]
#define Use_Alpha_Texture g_PixelShaderConstantsArr[168]
#define Use_DiffuseColor_Texture g_PixelShaderConstantsArr[165]
#define Use_EnvCubeMap_Texture g_PixelShaderConstantsArr[169]
#define Use_Gloss_Texture g_PixelShaderConstantsArr[167]
#define Use_SpecularColor_Texture g_PixelShaderConstantsArr[166]
#define ambient_factor g_PixelShaderConstantsArr[164]
#define cameraNearFar g_PixelShaderConstantsArr[187]
#define diffuse_color g_PixelShaderConstantsArr[162]
#define eyePosition g_PixelShaderConstantsArr[185]
#define g_CheapLights(INDEX) CONST_REL(64 + (INDEX))
#define g_CloudInfo g_PixelShaderConstantsArr[188]
#define g_LightingPassCount g_PixelShaderConstantsArr[175]
#define g_ParallelLightEnabled g_PixelShaderConstantsArr[176]
#define g_ParallelLights(INDEX) CONST_REL(0 + (INDEX))
#define g_SceneAmbient g_PixelShaderConstantsArr[189]
#define g_SpotLightEnabled(INDEX) CONST_REL(177 + (INDEX))
#define g_SpotLights(INDEX) CONST_REL(24 + (INDEX))
#define g_mProjectionToWorld(INDEX) CONST_REL(181 + (INDEX))
#define specular_color g_PixelShaderConstantsArr[161]
#define specular_power g_PixelShaderConstantsArr[160]
#define use_bumpmap g_PixelShaderConstantsArr[163]
#define viewVector g_PixelShaderConstantsArr[186]

cbuffer SharedConstants : register(b2, space4)
{
	uint g_AlphaMapTexture_Texture2DDescriptorIndex : packoffset(c1.x);
	uint g_AlphaMapTexture_Texture3DDescriptorIndex : packoffset(c5.x);
	uint g_AlphaMapTexture_TextureCubeDescriptorIndex : packoffset(c9.x);
	uint g_AlphaMapTexture_SamplerDescriptorIndex : packoffset(c13.x);
	uint g_DiffuseMapTexture_Texture2DDescriptorIndex : packoffset(c0.y);
	uint g_DiffuseMapTexture_Texture3DDescriptorIndex : packoffset(c4.y);
	uint g_DiffuseMapTexture_TextureCubeDescriptorIndex : packoffset(c8.y);
	uint g_DiffuseMapTexture_SamplerDescriptorIndex : packoffset(c12.y);
	uint g_EnvCubeMapTexture_Texture2DDescriptorIndex : packoffset(c1.y);
	uint g_EnvCubeMapTexture_Texture3DDescriptorIndex : packoffset(c5.y);
	uint g_EnvCubeMapTexture_TextureCubeDescriptorIndex : packoffset(c9.y);
	uint g_EnvCubeMapTexture_SamplerDescriptorIndex : packoffset(c13.y);
	uint g_FogTable_Texture2DDescriptorIndex : packoffset(c2.w);
	uint g_FogTable_Texture3DDescriptorIndex : packoffset(c6.w);
	uint g_FogTable_TextureCubeDescriptorIndex : packoffset(c10.w);
	uint g_FogTable_SamplerDescriptorIndex : packoffset(c14.w);
	uint g_GlossMapTexture_Texture2DDescriptorIndex : packoffset(c0.z);
	uint g_GlossMapTexture_Texture3DDescriptorIndex : packoffset(c4.z);
	uint g_GlossMapTexture_TextureCubeDescriptorIndex : packoffset(c8.z);
	uint g_GlossMapTexture_SamplerDescriptorIndex : packoffset(c12.z);
	uint g_LightCookie0_Texture2DDescriptorIndex : packoffset(c1.z);
	uint g_LightCookie0_Texture3DDescriptorIndex : packoffset(c5.z);
	uint g_LightCookie0_TextureCubeDescriptorIndex : packoffset(c9.z);
	uint g_LightCookie0_SamplerDescriptorIndex : packoffset(c13.z);
	uint g_LightCookie1_Texture2DDescriptorIndex : packoffset(c1.w);
	uint g_LightCookie1_Texture3DDescriptorIndex : packoffset(c5.w);
	uint g_LightCookie1_TextureCubeDescriptorIndex : packoffset(c9.w);
	uint g_LightCookie1_SamplerDescriptorIndex : packoffset(c13.w);
	uint g_LightCookie2_Texture2DDescriptorIndex : packoffset(c2.x);
	uint g_LightCookie2_Texture3DDescriptorIndex : packoffset(c6.x);
	uint g_LightCookie2_TextureCubeDescriptorIndex : packoffset(c10.x);
	uint g_LightCookie2_SamplerDescriptorIndex : packoffset(c14.x);
	uint g_LightCookie3_Texture2DDescriptorIndex : packoffset(c2.y);
	uint g_LightCookie3_Texture3DDescriptorIndex : packoffset(c6.y);
	uint g_LightCookie3_TextureCubeDescriptorIndex : packoffset(c10.y);
	uint g_LightCookie3_SamplerDescriptorIndex : packoffset(c14.y);
	uint g_NormalMapTexture_Texture2DDescriptorIndex : packoffset(c0.x);
	uint g_NormalMapTexture_Texture3DDescriptorIndex : packoffset(c4.x);
	uint g_NormalMapTexture_TextureCubeDescriptorIndex : packoffset(c8.x);
	uint g_NormalMapTexture_SamplerDescriptorIndex : packoffset(c12.x);
	uint g_ParallelLightShadowTexture_Texture2DDescriptorIndex : packoffset(c2.z);
	uint g_ParallelLightShadowTexture_Texture3DDescriptorIndex : packoffset(c6.z);
	uint g_ParallelLightShadowTexture_TextureCubeDescriptorIndex : packoffset(c10.z);
	uint g_ParallelLightShadowTexture_SamplerDescriptorIndex : packoffset(c14.z);
	uint g_ShadowMapTextureAtlas_Texture2DDescriptorIndex : packoffset(c3.x);
	uint g_ShadowMapTextureAtlas_Texture3DDescriptorIndex : packoffset(c7.x);
	uint g_ShadowMapTextureAtlas_TextureCubeDescriptorIndex : packoffset(c11.x);
	uint g_ShadowMapTextureAtlas_SamplerDescriptorIndex : packoffset(c15.x);
	uint g_SpecularColorMapTexture_Texture2DDescriptorIndex : packoffset(c0.w);
	uint g_SpecularColorMapTexture_Texture3DDescriptorIndex : packoffset(c4.w);
	uint g_SpecularColorMapTexture_TextureCubeDescriptorIndex : packoffset(c8.w);
	uint g_SpecularColorMapTexture_SamplerDescriptorIndex : packoffset(c12.w);
	DEFINE_SHARED_CONSTANTS();
};

#endif
	#define Use_GlossMap_On_EnvCubeMap BOOL_BIT(128)

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
	float4 c248 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c249 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c250 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c251 = asfloat(uint4(0x40000000, 0x3F800000, 0xBF800000, 0x3E800000));
	float4 c252 = asfloat(uint4(0x3F666666, 0x3DCCCCCD, 0x3FC00000, 0x0));
	float4 c253 = asfloat(uint4(0xB9000000, 0x39400000, 0xB9C00000, 0xB8800000)) * g_ShadowAtlasTexelScale;
	float4 c254 = asfloat(uint4(0x39C00000, 0x38800000, 0x39000000, 0xB9400000)) * g_ShadowAtlasTexelScale;
	float4 c255 = asfloat(uint4(0x40400000, 0x0, 0x0, 0x0));

	[branch] if (g_ShadowSoftness > 0.0)
	{
		float conanAngle = 6.2831853 * frac(52.9829189 * frac(dot(floor(iPos.xy), float2(0.06711056, 0.00583715))));
		float2 conanCS = float2(cos(conanAngle), sin(conanAngle)) * g_ShadowSoftness;
		c253 = float4(c253.x * conanCS.x - c253.y * conanCS.y, c253.x * conanCS.y + c253.y * conanCS.x, c253.z * conanCS.x - c253.w * conanCS.y, c253.z * conanCS.y + c253.w * conanCS.x);
		c254 = float4(c254.x * conanCS.x - c254.y * conanCS.y, c254.x * conanCS.y + c254.y * conanCS.x, c254.z * conanCS.x - c254.w * conanCS.y, c254.z * conanCS.y + c254.w * conanCS.x);
	}

	float4 r0 = iTexCoord0;
	float4 r1 = iTexCoord1;
	float4 r2 = iTexCoord2;
	float4 r3 = iTexCoord3;
	float4 r4 = iTexCoord4;
	float4 r5 = 
#ifdef CONAN_RECOMP
		float4((iPos.xy * g_PixelPosScale - 0.5) * float2(iFace ? 1.0 : -1.0, 1.0), 0.0, 0.0);
#else
		float4((iPos.xy - 0.5) * float2(iFace ? 1.0 : -1.0, 1.0), 0.0, 0.0);
#endif
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

	r2.zw = r2.yx * NormalMapUVScale.yx;
// conan_tfetch slot=0 mag=3 min=3 mip=3 aniso=7
	pixelCoord = getPixelCoord(g_NormalMapTexture_Texture2DDescriptorIndex, r2.wz);
	r6.yzw = tfetch2D(g_NormalMapTexture_Texture2DDescriptorIndex, g_NormalMapTexture_SamplerDescriptorIndex, r2.wz, float2(0, 0)).xyz;
	r7.xy = r2.yx * DiffuseMapUVScale.yx;
	r2.zw = r2.yx * SpecularMapUVScale.yx;
	r7.zw = r2.yx * GlossMapUVScale.yx;
	r1.w = dot(r1.zxy, r1.zxy);
	r3.w = dot(r4.zxy, r4.zxy);
	r4.w = dot(r3.zxy, r3.zxy);
	r8.xyzw = r0.wwww * g_mProjectionToWorld(3).wxyz;
	ps = clamp(rcp(r5.x), FLT_MIN, FLT_MAX);
	r6.x = ps;
	r5.xyzw = r0.zzzz * g_mProjectionToWorld(2).wxyz + r8.xyzw;
	r6.x = r6.x >= c252.w;
	ps = clamp(rsqrt(abs(r4.w)), FLT_MIN, FLT_MAX);
	r4.w = ps;
	r8.xyz = r4.www * r3.xyz;
	ps = clamp(rsqrt(abs(r3.w)), FLT_MIN, FLT_MAX);
	r3.x = ps;
	r10.xyz = r3.xxx * r4.xyz;
	ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r1.xyz = r1.www * r1.xyz;
	r3.xyzw = r0.yyyy * g_mProjectionToWorld(1).wxyz + r5.xyzw;
	r5.xyzw = r0.xxxx * g_mProjectionToWorld(0).wxyz + r3.xyzw;
	r3.xyzw = r6.yzwx * c251.xxxx + c251.zzzz;
	r1.w = dot(r3.zxy, r3.zxy);
	ps = clamp(rcp(r5.x), FLT_MIN, FLT_MAX);
	r4.x = ps;
	r4.xyz = r5.yzw * r4.xxx;
	r6.xyz = -r4.xyz + eyePosition.xyz;
	ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r9.xyz = r3.xyz * r1.www;
	r4.w = dot(r6.zxy, r6.zxy);
	r5.xyz = r9.zzz * r1.xyz;
	r5.xyz = r9.yyy * r10.xyz + r5.xyz;
	r5.xyz = r9.xxx * r8.xyz + r5.xyz;
	r1.w = dot(r5.zxy, r5.zxy);
	ps = clamp(rsqrt(abs(r4.w)), FLT_MIN, FLT_MAX);
	r4.w = ps;
	r9.xyz = r6.xyz * r4.www;
	ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r5.xyz = r5.xyz * r1.www;
	r1.xyz = select(use_bumpmap.xxx > 0.0, r5.xyz, r1.xyz);
	r5.xyz = r3.www * r1.xyz;
	ps = max(r2.y, r2.y);
	r1.x = dot(-r9.zxy, r5.zxy);
	ps = AlphaMapUVScale.y * ps;
	r3.x = ps;
	r1.x = r1.x + r1.x;
	ps = max(r2.x, r2.x);
	r1.xyz = -r5.zyx * r1.xxx + -r9.zyx;
	r1.xyzw = cube(r1.zyxx, cubeMapData);
	ps = AlphaMapUVScale.x * ps;
	r3.y = ps;
	r6.z = max(r1.w, r1.w);
	ps = clamp(rcp(abs(r1.z)), FLT_MIN, FLT_MAX);
	r2.x = ps;
	r6.xy = r1.yx * r2.xx + c252.zz;
// conan_tfetch slot=4 mag=3 min=3 mip=3 aniso=7
	r1.w = tfetch2D(g_AlphaMapTexture_Texture2DDescriptorIndex, g_AlphaMapTexture_SamplerDescriptorIndex, r3.yx, float2(0, 0)).x;
// conan_tfetch slot=2 mag=3 min=3 mip=3 aniso=7
	r2.x = tfetch2D(g_GlossMapTexture_Texture2DDescriptorIndex, g_GlossMapTexture_SamplerDescriptorIndex, r7.wz, float2(0, 0)).x;
// conan_tfetch slot=3 mag=3 min=3 mip=3 aniso=7
	r2.yzw = tfetch2D(g_SpecularColorMapTexture_Texture2DDescriptorIndex, g_SpecularColorMapTexture_SamplerDescriptorIndex, r2.wz, float2(0, 0)).xyz;
// conan_tfetch slot=1 mag=3 min=3 mip=3 aniso=7
	r3.xyz = tfetch2D(g_DiffuseMapTexture_Texture2DDescriptorIndex, g_DiffuseMapTexture_SamplerDescriptorIndex, r7.yx, float2(0, 0)).xyz;
// conan_tfetch slot=5 mag=3 min=3 mip=3 aniso=7
	r1.xyz = tfetchCube(g_EnvCubeMapTexture_TextureCubeDescriptorIndex, g_EnvCubeMapTexture_SamplerDescriptorIndex, r6.xyz, cubeMapData).xyz;
	r11.xyz = -abs(r0.xxx) > c252.www;
	r1.xyz = r1.zxy * Use_EnvCubeMap_Texture.xxx;
	p0 = g_LightingPassCount.x == 0.0;
	ps = p0 ? 0.0 : 1.0;
	r7.xyz = select(Use_DiffuseColor_Texture.xxx > 0.0, r3.xyz, diffuse_color.xyz);
	r10.xyz = select(Use_SpecularColor_Texture.xxx > 0.0, r2.yzw, specular_color.xyz);
	r3.w = select(Use_Gloss_Texture.x > 0.0, r2.x, c251.y);
	r2.w = select(Use_Alpha_Texture.x > 0.0, r1.w, c251.y);
	if (p0)
	{
		r1.w = saturate(dot(r5.zxy, r9.zxy));
		r2.xyz = r7.xyz * g_SceneAmbient.xyz;
		ps = g_SceneAmbient.x * r1.y;
		r1.y = ps;
		r2.xyz = r2.xyz * ambient_factor.xxx;
		ps = g_SceneAmbient.y * r1.z;
		r1.z = ps;
		r1.w = r1.w * c252.x + c252.y;
		r2.xyz = r2.xyz * r1.www;
		ps = g_SceneAmbient.z * r1.x;
		r1.x = ps;
		if (!Use_GlossMap_On_EnvCubeMap)
		{
			r11.xyz = r2.xyz + r1.yzx;
		}
		else
		{
			r11.xyz = r1.yzx * r3.www + r2.xyz;
		}
	}
	ps = -abs(r0.x) > 0.0;
	r1.y = ps;
	int aLSave0 = aL;
	uint loopConst0 = g_LoopConstant(16);
	[loop] for (uint loopIt0 = 0; loopIt0 < LOOP_COUNT(loopConst0); loopIt0++)
	{
		aL = LOOP_START(loopConst0) + int(loopIt0) * LOOP_STEP(loopConst0);
		ps = c255.x * r1.y;
		r0.y = ps;
		ps = max(r0.y, r0.y);
		a0 = (int)clamp(floor(r0.y + 0.5), -256.0, 255.0);
		r2.xyz = -r4.xyz * CONST_REL(66 + a0).www + CONST_REL(66 + a0).xyz;
		r1.x = dot(r2.zxy, r2.zxy);
		r0.y = r1.x * CONST_REL(65 + a0).y;
		ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
		r1.x = ps;
		r1.xzw = r2.xyz * r1.xxx;
		r2.x = saturate(dot(r1.wxz, r5.zxy));
		r3.xyz = r1.xzw + r9.xyz;
		ps = clamp(log2(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r0.y = r0.y * CONST_REL(65 + a0).z;
		r1.x = dot(r3.zxy, r3.zxy);
		ps = saturate(exp2(r0.y));
		r0.y = ps;
		r0.y = -r0.y + c251.y;
		ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
		r1.x = ps;
		r1.xzw = r3.xyz * r1.xxx;
		r3.xyz = r0.yyy * CONST_REL(64 + a0).xyz;
		r0.y = saturate(dot(r1.wxz, r5.zxy));
		r1.xzw = r3.xyz * r2.xxx;
		r1.xzw = r1.xzw * r7.xyz + r11.xyz;
		r1.y = r1.y + c251.y;
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r0.y = ps;
		ps = specular_power.x * r0.y;
		r2.y = ps;
		r3.xyz = r3.xyz * r10.xyz;
		ps = exp2(r2.y);
		r2.y = ps;
		r2.x = r2.x * r2.y;
		r2.xyz = r3.xyz * r2.xxx;
		r11.xyz = r2.xyz * r3.www + r1.xzw;
	}
	aL = aLSave0;
	p0 = g_SpotLightEnabled(0).x > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r6.xyzw = r4.zzzz * g_SpotLights(2).wxyz + g_SpotLights(3).wxyz;
		r1.xyz = -r4.xyz + g_SpotLights(7).xyz;
		r6.xyzw = r4.yyyy * g_SpotLights(1).wxyz + r6.xyzw;
		r6.xyzw = r4.xxxx * g_SpotLights(0).zyxw + r6.wzyx;
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
		r0.x = -r0.x + c251.y;
		p0 = -r6.w > 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = -abs(r0.x) > 0.0;
			r0.x = ps;
		}
		ps = clamp(rcp(r6.w), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r17.xyz = r6.xyz * r0.yyy;
		r2.xy = saturate(max(r17.zy, r17.zy));
		r2.xy = r2.xy * g_SpotLights(9).xy + g_SpotLights(9).zw;
		r8.xyzw = r2.yxyx + c253.xyzw;
		r18.xyzw = r2.yxyx + c254.xyzw;
// conan_tfetch slot=6 mag=3 min=3 mip=3 aniso=7
		r6.yzw = tfetch2D(g_LightCookie0_Texture2DDescriptorIndex, g_LightCookie0_SamplerDescriptorIndex, r17.zy, float2(0, 0)).xyz;
		r13.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0, 0)).xy;
		r13.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0, 0)).xy;
		r14.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0, 0)).xy;
		r14.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0, 0)).xy;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r12.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r12.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r12.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r12.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, 0.5)).x;
		r3.xyz = r1.xyz + r9.xyz;
		r0.y = dot(r3.zxy, r3.zxy);
		r1.w = max(r17.x, c252.w);
		r12.xyzw = r12.xyzw > r1.wwww;
		r8.xyzw = r8.xyzw > r1.wwww;
		r17.xyzw = r16.xyzw > r1.wwww;
		r15.xyzw = r15.xyzw > r1.wwww;
		r16.xyzw = r15.yxwz != c252.wwww;
		r15.xyzw = r8.yxwz != c252.wwww;
		ps = r17.y != 0.0;
		r8.x = ps;
		r12.xyzw = r12.yxwz != c252.wwww;
		ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r3.xyz = r3.xyz * r0.yyy;
		ps = r17.x != 0.0;
		r8.y = ps;
		r0.y = saturate(dot(r3.zxy, r5.zxy));
		ps = r17.w != 0.0;
		r8.z = ps;
		r15.xyzw = r15.yxwz + -r12.yxwz;
		ps = r17.z != 0.0;
		r8.w = ps;
		r16.xyzw = r16.yxwz + -r8.yxwz;
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r8.xyzw = r16.xyzw * r14.zzxx + r8.yxwz;
		r12.xyzw = r15.xyzw * r13.zzxx + r12.yxwz;
		ps = specular_power.x * r0.y;
		r1.w = ps;
		r1.x = saturate(dot(r1.zxy, r5.zxy));
		ps = r12.y - r12.x;
		r1.y = ps;
		r3.xy = r8.yw + -r8.xz;
		ps = r12.w - r12.z;
		r1.z = ps;
		r8.xy = r3.xy * r14.wy + r8.xz;
		r8.zw = r1.yz * r13.wy + r12.xz;
		r1.y = dot(r8.xywz, c251.wwww);
		ps = exp2(r1.w);
		r6.x = ps;
		r1.y = select(-r2.x > 0.0, c251.y, r1.y);
		r1.y = select(-abs(g_SpotLights(6).x) >= 0.0, abs(c251.y), r1.y);
		r6.xyzw = r1.xyyy * r6.xyzw;
		r2.xyz = r6.yzw * g_SpotLights(4).xyz;
		r3.xyz = r2.xyz * r0.xxx;
		r2.xyz = r3.xyz * r10.xyz;
		r1.xyz = r3.xyz * r1.xxx;
		r1.xyz = r1.xyz * r7.xyz + r11.xyz;
		r2.xyz = r2.xyz * r6.xxx;
		p0 = g_SpotLightEnabled(1).x > 0.0;
		ps = p0 ? 0.0 : 1.0;
		r11.xyz = r2.xyz * r3.www + r1.xyz;
		if (p0)
		{
			r1.xyzw = r4.zzzz * g_SpotLights(12).wxyz + g_SpotLights(13).wxyz;
			r2.xyz = -r4.xyz + g_SpotLights(17).xyz;
			r1.xyzw = r4.yyyy * g_SpotLights(11).wxyz + r1.xyzw;
			r1.xyzw = r4.xxxx * g_SpotLights(10).zyxw + r1.wzyx;
			r0.x = dot(r2.zxy, r2.zxy);
			ps = g_SpotLights(15).z * r0.x;
			r3.x = ps;
			ps = clamp(log2(abs(r3.x)), FLT_MIN, FLT_MAX);
			r3.x = ps;
			r3.x = r3.x * g_SpotLights(15).w;
			ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
			r0.x = ps;
			r2.xyz = r2.xyz * r0.xxx;
			ps = saturate(exp2(r3.x));
			r0.x = ps;
			r0.x = -r0.x + c251.y;
			p0 = -r1.w > 0.0;
			ps = p0 ? 0.0 : 1.0;
			if (p0)
			{
				ps = -abs(r0.x) > 0.0;
				r0.x = ps;
			}
			ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r17.xyz = r1.xyz * r0.yyy;
			r1.xy = saturate(max(r17.zy, r17.zy));
			r1.zw = r1.xy * g_SpotLights(19).xy + g_SpotLights(19).zw;
			r8.xyzw = r1.wzwz + c253.xyzw;
			r18.xyzw = r1.wzwz + c254.xyzw;
// conan_tfetch slot=7 mag=3 min=3 mip=3 aniso=7
			r6.yzw = tfetch2D(g_LightCookie1_Texture2DDescriptorIndex, g_LightCookie1_SamplerDescriptorIndex, r17.zy, float2(0, 0)).xyz;
			r13.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0, 0)).xy;
			r13.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0, 0)).xy;
			r14.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0, 0)).xy;
			r14.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0, 0)).xy;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r15.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r15.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r15.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r15.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r8.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r8.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r8.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r8.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r12.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r12.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r12.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
			r12.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, 0.5)).x;
			r3.xyz = r2.xyz + r9.xyz;
			r0.y = dot(r3.zxy, r3.zxy);
			r1.x = max(r17.x, c252.w);
			r12.xyzw = r12.xyzw > r1.xxxx;
			r8.xyzw = r8.xyzw > r1.xxxx;
			r17.xyzw = r16.xyzw > r1.xxxx;
			r15.xyzw = r15.xyzw > r1.xxxx;
			r16.xyzw = r15.yxwz != c252.wwww;
			r15.xyzw = r8.yxwz != c252.wwww;
			ps = r17.y != 0.0;
			r8.x = ps;
			r12.xyzw = r12.yxwz != c252.wwww;
			ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r3.xyz = r3.xyz * r0.yyy;
			ps = r17.x != 0.0;
			r8.y = ps;
			r0.y = saturate(dot(r3.zxy, r5.zxy));
			ps = r17.w != 0.0;
			r8.z = ps;
			r15.xyzw = r15.yxwz + -r12.yxwz;
			ps = r17.z != 0.0;
			r8.w = ps;
			r16.xyzw = r16.yxwz + -r8.yxwz;
			ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r8.xyzw = r16.xyzw * r14.zzxx + r8.yxwz;
			r12.xyzw = r15.xyzw * r13.zzxx + r12.yxwz;
			ps = specular_power.x * r0.y;
			r3.x = ps;
			r1.x = saturate(dot(r2.zxy, r5.zxy));
			ps = r12.y - r12.x;
			r2.x = ps;
			r3.yz = r8.yw + -r8.xz;
			ps = r12.w - r12.z;
			r2.y = ps;
			r8.xy = r3.yz * r14.wy + r8.xz;
			r8.zw = r2.xy * r13.wy + r12.xz;
			r1.y = dot(r8.xywz, c251.wwww);
			ps = exp2(r3.x);
			r6.x = ps;
			r1.y = select(-r1.z > 0.0, c251.y, r1.y);
			r1.y = select(-abs(g_SpotLights(16).x) >= 0.0, abs(c251.y), r1.y);
			r6.xyzw = r1.xyyy * r6.xyzw;
			r2.xyz = r6.yzw * g_SpotLights(14).xyz;
			r3.xyz = r2.xyz * r0.xxx;
			r2.xyz = r3.xyz * r10.xyz;
			r1.xyz = r3.xyz * r1.xxx;
			r1.xyz = r1.xyz * r7.xyz + r11.xyz;
			r2.xyz = r2.xyz * r6.xxx;
			p0 = g_SpotLightEnabled(2).x > 0.0;
			ps = p0 ? 0.0 : 1.0;
			r11.xyz = r2.xyz * r3.www + r1.xyz;
			if (p0)
			{
				r1.xyzw = r4.zzzz * g_SpotLights(22).wxyz + g_SpotLights(23).wxyz;
				r2.xyz = -r4.xyz + g_SpotLights(27).xyz;
				r1.xyzw = r4.yyyy * g_SpotLights(21).wxyz + r1.xyzw;
				r1.xyzw = r4.xxxx * g_SpotLights(20).zyxw + r1.wzyx;
				r0.x = dot(r2.zxy, r2.zxy);
				ps = g_SpotLights(25).z * r0.x;
				r3.x = ps;
				ps = clamp(log2(abs(r3.x)), FLT_MIN, FLT_MAX);
				r3.x = ps;
				r3.x = r3.x * g_SpotLights(25).w;
				ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
				r0.x = ps;
				r2.xyz = r2.xyz * r0.xxx;
				ps = saturate(exp2(r3.x));
				r0.x = ps;
				r0.x = -r0.x + c251.y;
				p0 = -r1.w > 0.0;
				ps = p0 ? 0.0 : 1.0;
				if (p0)
				{
					ps = -abs(r0.x) > 0.0;
					r0.x = ps;
				}
				ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r17.xyz = r1.xyz * r0.yyy;
				r1.xy = saturate(max(r17.zy, r17.zy));
				r1.zw = r1.xy * g_SpotLights(29).xy + g_SpotLights(29).zw;
				r8.xyzw = r1.wzwz + c253.xyzw;
				r18.xyzw = r1.wzwz + c254.xyzw;
// conan_tfetch slot=8 mag=3 min=3 mip=3 aniso=7
				r6.yzw = tfetch2D(g_LightCookie2_Texture2DDescriptorIndex, g_LightCookie2_SamplerDescriptorIndex, r17.zy, float2(0, 0)).xyz;
				r13.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0, 0)).xy;
				r13.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0, 0)).xy;
				r14.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0, 0)).xy;
				r14.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0, 0)).xy;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r15.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r15.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r15.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r15.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r8.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r8.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r8.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r8.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r12.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r12.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r12.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
				r12.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, 0.5)).x;
				r3.xyz = r2.xyz + r9.xyz;
				r0.y = dot(r3.zxy, r3.zxy);
				r1.x = max(r17.x, c252.w);
				r12.xyzw = r12.xyzw > r1.xxxx;
				r8.xyzw = r8.xyzw > r1.xxxx;
				r17.xyzw = r16.xyzw > r1.xxxx;
				r15.xyzw = r15.xyzw > r1.xxxx;
				r16.xyzw = r15.yxwz != c252.wwww;
				r15.xyzw = r8.yxwz != c252.wwww;
				ps = r17.y != 0.0;
				r8.x = ps;
				r12.xyzw = r12.yxwz != c252.wwww;
				ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r3.xyz = r3.xyz * r0.yyy;
				ps = r17.x != 0.0;
				r8.y = ps;
				r0.y = saturate(dot(r3.zxy, r5.zxy));
				ps = r17.w != 0.0;
				r8.z = ps;
				r15.xyzw = r15.yxwz + -r12.yxwz;
				ps = r17.z != 0.0;
				r8.w = ps;
				r16.xyzw = r16.yxwz + -r8.yxwz;
				ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r8.xyzw = r16.xyzw * r14.zzxx + r8.yxwz;
				r12.xyzw = r15.xyzw * r13.zzxx + r12.yxwz;
				ps = specular_power.x * r0.y;
				r3.x = ps;
				r1.x = saturate(dot(r2.zxy, r5.zxy));
				ps = r12.y - r12.x;
				r2.x = ps;
				r3.yz = r8.yw + -r8.xz;
				ps = r12.w - r12.z;
				r2.y = ps;
				r8.xy = r3.yz * r14.wy + r8.xz;
				r8.zw = r2.xy * r13.wy + r12.xz;
				r1.y = dot(r8.xywz, c251.wwww);
				ps = exp2(r3.x);
				r6.x = ps;
				r1.y = select(-r1.z > 0.0, c251.y, r1.y);
				r1.y = select(-abs(g_SpotLights(26).x) >= 0.0, abs(c251.y), r1.y);
				r6.xyzw = r1.xyyy * r6.xyzw;
				r2.xyz = r6.yzw * g_SpotLights(24).xyz;
				r3.xyz = r2.xyz * r0.xxx;
				r2.xyz = r3.xyz * r10.xyz;
				r1.xyz = r3.xyz * r1.xxx;
				r1.xyz = r1.xyz * r7.xyz + r11.xyz;
				r2.xyz = r2.xyz * r6.xxx;
				p0 = g_SpotLightEnabled(3).x > 0.0;
				ps = p0 ? 0.0 : 1.0;
				r11.xyz = r2.xyz * r3.www + r1.xyz;
				if (p0)
				{
					r1.xyzw = r4.zzzz * g_SpotLights(32).wxyz + g_SpotLights(33).wxyz;
					r2.xyz = -r4.xyz + g_SpotLights(37).xyz;
					r1.xyzw = r4.yyyy * g_SpotLights(31).wxyz + r1.xyzw;
					r1.xyzw = r4.xxxx * g_SpotLights(30).zyxw + r1.wzyx;
					r0.x = dot(r2.zxy, r2.zxy);
					ps = g_SpotLights(35).z * r0.x;
					r3.x = ps;
					ps = clamp(log2(abs(r3.x)), FLT_MIN, FLT_MAX);
					r3.x = ps;
					r3.x = r3.x * g_SpotLights(35).w;
					ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
					r0.x = ps;
					r2.xyz = r2.xyz * r0.xxx;
					ps = saturate(exp2(r3.x));
					r0.x = ps;
					r0.x = -r0.x + c251.y;
					p0 = -r1.w > 0.0;
					ps = p0 ? 0.0 : 1.0;
					if (p0)
					{
						ps = -abs(r0.x) > 0.0;
						r0.x = ps;
					}
					ps = clamp(rcp(r1.w), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r17.xyz = r1.xyz * r0.yyy;
					r1.xy = saturate(max(r17.zy, r17.zy));
					r1.zw = r1.xy * g_SpotLights(39).xy + g_SpotLights(39).zw;
					r8.xyzw = r1.wzwz + c253.xyzw;
					r18.xyzw = r1.wzwz + c254.xyzw;
// conan_tfetch slot=9 mag=3 min=3 mip=3 aniso=7
					r6.yzw = tfetch2D(g_LightCookie3_Texture2DDescriptorIndex, g_LightCookie3_SamplerDescriptorIndex, r17.zy, float2(0, 0)).xyz;
					r13.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0, 0)).xy;
					r13.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0, 0)).xy;
					r14.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0, 0)).xy;
					r14.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0, 0)).xy;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r15.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r15.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r15.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r15.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r16.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r16.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r16.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r16.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r8.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r8.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r8.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r8.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r12.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r12.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r12.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
					r12.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r18.yx, float2(-0.5, 0.5)).x;
					r3.xyz = r2.xyz + r9.xyz;
					r0.y = dot(r3.zxy, r3.zxy);
					r1.x = max(r17.x, c252.w);
					r12.xyzw = r12.xyzw > r1.xxxx;
					r8.xyzw = r8.xyzw > r1.xxxx;
					r17.xyzw = r16.xyzw > r1.xxxx;
					r15.xyzw = r15.xyzw > r1.xxxx;
					r16.xyzw = r15.yxwz != c252.wwww;
					r15.xyzw = r8.yxwz != c252.wwww;
					ps = r17.y != 0.0;
					r8.x = ps;
					r12.xyzw = r12.yxwz != c252.wwww;
					ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r3.xyz = r3.xyz * r0.yyy;
					ps = r17.x != 0.0;
					r8.y = ps;
					r0.y = saturate(dot(r3.zxy, r5.zxy));
					ps = r17.w != 0.0;
					r8.z = ps;
					r15.xyzw = r15.yxwz + -r12.yxwz;
					ps = r17.z != 0.0;
					r8.w = ps;
					r16.xyzw = r16.yxwz + -r8.yxwz;
					ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r8.xyzw = r16.xyzw * r14.zzxx + r8.yxwz;
					r12.xyzw = r15.xyzw * r13.zzxx + r12.yxwz;
					ps = specular_power.x * r0.y;
					r3.x = ps;
					r1.x = saturate(dot(r2.zxy, r5.zxy));
					ps = r12.y - r12.x;
					r2.x = ps;
					r3.yz = r8.yw + -r8.xz;
					ps = r12.w - r12.z;
					r2.y = ps;
					r8.xy = r3.yz * r14.wy + r8.xz;
					r8.zw = r2.xy * r13.wy + r12.xz;
					r1.y = dot(r8.xywz, c251.wwww);
					ps = exp2(r3.x);
					r6.x = ps;
					r1.y = select(-r1.z > 0.0, c251.y, r1.y);
					r1.y = select(-abs(g_SpotLights(36).x) >= 0.0, abs(c251.y), r1.y);
					r6.xyzw = r1.xyyy * r6.xyzw;
					r2.xyz = r6.yzw * g_SpotLights(34).xyz;
					r3.xyz = r2.xyz * r0.xxx;
					r2.xyz = r3.xyz * r10.xyz;
					r1.xyz = r3.xyz * r1.xxx;
					r1.xyz = r1.xyz * r7.xyz + r11.xyz;
					r2.xyz = r2.xyz * r6.xxx;
					r11.xyz = r2.xyz * r3.www + r1.xyz;
				}
			}
		}
	}
	p0 = g_ParallelLightEnabled.x > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r12.z = max(g_ParallelLights(14).w, g_ParallelLights(14).w);
		ps = max(g_ParallelLights(15).z, g_ParallelLights(15).z);
		r1.z = ps;
		r12.y = max(g_ParallelLights(13).w, g_ParallelLights(13).w);
		ps = max(g_ParallelLights(14).z, g_ParallelLights(14).z);
		r2.z = ps;
		r12.x = max(g_ParallelLights(12).w, g_ParallelLights(12).w);
		ps = max(g_ParallelLights(13).z, g_ParallelLights(13).z);
		r2.y = ps;
		r1.xy = max(g_ParallelLights(23).zw, g_ParallelLights(23).zw);
		ps = max(g_ParallelLights(12).z, g_ParallelLights(12).z);
		r2.x = ps;
		r8.xy = max(g_ParallelLights(14).xy, g_ParallelLights(14).xy);
		ps = max(g_ParallelLights(23).y, g_ParallelLights(23).y);
		r6.y = ps;
		r8.zw = max(g_ParallelLights(13).xy, g_ParallelLights(13).xy);
		ps = max(g_ParallelLights(23).x, g_ParallelLights(23).x);
		r6.x = ps;
		r3.xyz = max(g_ParallelLights(15).wxy, g_ParallelLights(15).wxy);
		ps = max(g_ParallelLights(12).y, g_ParallelLights(12).y);
		r6.w = ps;
		r0.y = dot(g_ParallelLights(19).zxy, g_ParallelLights(19).zxy);
		ps = clamp(rcp(r0.w), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r0.x = r0.x * r0.z;
		ps = max(g_ParallelLights(12).x, g_ParallelLights(12).x);
		r6.z = ps;
		r1.w = g_ParallelLights(16).z > r0.x;
		ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r0.yzw = r0.yyy * g_ParallelLights(19).xyz;
		p0 = r1.w != 0.0;
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
			r12.z = ps;
		}
		if (p0)
		{
			r2.y = max(g_ParallelLights(9).z, g_ParallelLights(9).z);
			ps = max(g_ParallelLights(9).w, g_ParallelLights(9).w);
			r12.y = ps;
		}
		if (p0)
		{
			r2.x = max(g_ParallelLights(8).z, g_ParallelLights(8).z);
			ps = max(g_ParallelLights(8).w, g_ParallelLights(8).w);
			r12.x = ps;
		}
		if (p0)
		{
			r6.xy = max(g_ParallelLights(22).xy, g_ParallelLights(22).xy);
			ps = max(g_ParallelLights(22).w, g_ParallelLights(22).w);
			r1.y = ps;
		}
		if (p0)
		{
			r8.xy = max(g_ParallelLights(10).xy, g_ParallelLights(10).xy);
			ps = max(g_ParallelLights(22).z, g_ParallelLights(22).z);
			r1.x = ps;
		}
		if (p0)
		{
			r6.zw = max(g_ParallelLights(8).xy, g_ParallelLights(8).xy);
			ps = max(g_ParallelLights(9).y, g_ParallelLights(9).y);
			r8.w = ps;
		}
		if (p0)
		{
			r3.xyz = max(g_ParallelLights(11).wxy, g_ParallelLights(11).wxy);
			ps = max(g_ParallelLights(9).x, g_ParallelLights(9).x);
			r8.z = ps;
		}
		r1.w = g_ParallelLights(16).y > r0.x;
		p0 = r1.w != 0.0;
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
			r12.z = ps;
		}
		if (p0)
		{
			r2.y = max(g_ParallelLights(5).z, g_ParallelLights(5).z);
			ps = max(g_ParallelLights(5).w, g_ParallelLights(5).w);
			r12.y = ps;
		}
		if (p0)
		{
			r2.x = max(g_ParallelLights(4).z, g_ParallelLights(4).z);
			ps = max(g_ParallelLights(4).w, g_ParallelLights(4).w);
			r12.x = ps;
		}
		if (p0)
		{
			r6.xy = max(g_ParallelLights(21).xy, g_ParallelLights(21).xy);
			ps = max(g_ParallelLights(21).w, g_ParallelLights(21).w);
			r1.y = ps;
		}
		if (p0)
		{
			r8.xy = max(g_ParallelLights(6).xy, g_ParallelLights(6).xy);
			ps = max(g_ParallelLights(21).z, g_ParallelLights(21).z);
			r1.x = ps;
		}
		if (p0)
		{
			r6.zw = max(g_ParallelLights(4).xy, g_ParallelLights(4).xy);
			ps = max(g_ParallelLights(5).y, g_ParallelLights(5).y);
			r8.w = ps;
		}
		if (p0)
		{
			r3.xyz = max(g_ParallelLights(7).wxy, g_ParallelLights(7).wxy);
			ps = max(g_ParallelLights(5).x, g_ParallelLights(5).x);
			r8.z = ps;
		}
		r0.x = g_ParallelLights(16).x > r0.x;
		p0 = r0.x != 0.0;
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
			r12.z = ps;
		}
		if (p0)
		{
			r2.y = max(g_ParallelLights(1).z, g_ParallelLights(1).z);
			ps = max(g_ParallelLights(1).w, g_ParallelLights(1).w);
			r12.y = ps;
		}
		if (p0)
		{
			r2.x = max(g_ParallelLights(0).z, g_ParallelLights(0).z);
			ps = max(g_ParallelLights(0).w, g_ParallelLights(0).w);
			r12.x = ps;
		}
		if (p0)
		{
			r6.xy = max(g_ParallelLights(20).xy, g_ParallelLights(20).xy);
			ps = max(g_ParallelLights(20).w, g_ParallelLights(20).w);
			r1.y = ps;
		}
		if (p0)
		{
			r8.xy = max(g_ParallelLights(2).xy, g_ParallelLights(2).xy);
			ps = max(g_ParallelLights(20).z, g_ParallelLights(20).z);
			r1.x = ps;
		}
		if (p0)
		{
			r6.zw = max(g_ParallelLights(0).xy, g_ParallelLights(0).xy);
			ps = max(g_ParallelLights(1).y, g_ParallelLights(1).y);
			r8.w = ps;
		}
		if (p0)
		{
			r3.xyz = max(g_ParallelLights(3).wxy, g_ParallelLights(3).wxy);
			ps = max(g_ParallelLights(1).x, g_ParallelLights(1).x);
			r8.z = ps;
		}
		r12.x = dot(r4.zxy, r12.zxy);
		r12.y = dot(r4.zy, r8.xz) + c252.w;
		r12.z = dot(r4.zy, r8.yw) + c252.w;
		r12.yz = r4.xx * r6.zw + r12.yz;
		r3.xyz = r12.xyz + r3.xyz;
		r2.z = dot(r4.zxy, r2.zxy);
		ps = clamp(rcp(r3.x), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r2.xy = saturate(r3.yz * r0.xx);
		r2.xy = r2.xy * r6.xy;
		r1.yzw = r2.xyz + r1.xyz;
		r8.xyzw = r1.zyzy + c253.xyzw;
		r16.xyzw = r1.zyzy + c254.xyzw;
		r12.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.yx, float2(0, 0)).xy;
		r12.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.wz, float2(0, 0)).xy;
		r13.xy = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0, 0)).xy;
		r13.zw = getWeights2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0, 0)).xy;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r15.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r6.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r6.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r6.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r6.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r8.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r14.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.wz, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r14.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.wz, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r14.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.yx, float2(0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r14.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.yx, float2(0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.x = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.wz, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.wz, float2(-0.5, 0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.z = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.yx, float2(-0.5, -0.5)).x;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
		r8.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r16.yx, float2(-0.5, 0.5)).x;
		r0.x = r1.w * r0.x;
		r0.x = max(r0.x, c252.w);
		r8.xyzw = r8.xyzw > r0.xxxx;
		r14.xyzw = r14.xyzw > r0.xxxx;
		r6.xyzw = r6.xyzw > r0.xxxx;
		r16.xyzw = r15.xyzw > r0.xxxx;
		r15.xyzw = r6.yxwz != c252.wwww;
		ps = r16.y != 0.0;
		r6.x = ps;
		r14.xyzw = r14.yxwz != c252.wwww;
		ps = r16.x != 0.0;
		r6.y = ps;
		r8.xyzw = r8.yxwz != c252.wwww;
		ps = r16.w != 0.0;
		r6.z = ps;
		r14.xyzw = r14.yxwz + -r8.yxwz;
		ps = r16.z != 0.0;
		r6.w = ps;
		r15.xyzw = r15.yxwz + -r6.yxwz;
		r6.xyzw = r15.xyzw * r13.zzxx + r6.yxwz;
		r8.xyzw = r14.xyzw * r12.zzxx + r8.yxwz;
		r2.xy = r8.yw + -r8.xz;
		r3.xy = r6.yw + -r6.xz;
		p0 = abs(g_ParallelLights(18).z) > 0.0;
		ps = p0 ? 0.0 : 1.0;
		r6.xy = r3.xy * r13.wy + r6.xz;
		r6.zw = r2.xy * r12.wy + r8.xz;
		r0.x = dot(r6.xywz, c251.wwww);
		ps = max(c251.y, c251.y);
		r1.x = ps;
		r0.x = select(-r1.y > 0.0, c251.y, r0.x);
		if (p0)
		{
			r1.xy = r4.yx * g_CloudInfo.xx + g_CloudInfo.yy;
// conan_tfetch slot=10 mag=3 min=3 mip=3 aniso=7
			r1.xyz = tfetch2D(g_ParallelLightShadowTexture_Texture2DDescriptorIndex, g_ParallelLightShadowTexture_SamplerDescriptorIndex, r1.yx, float2(0, 0)).xyz;
		}
		else
		{
			r1.yz = max(c251.yy, c251.yy);
		}
		r1.w = saturate(dot(r0.wyz, r5.zxy));
		r2.xyz = r0.yzw + r9.xyz;
		r0.xyz = r1.xyz * r0.xxx;
		r1.xyz = r0.xyz * g_ParallelLights(17).xyz;
		r0.y = dot(r2.zxy, r2.zxy);
		r0.xzw = r1.xyz * r1.www;
		ps = clamp(rsqrt(abs(r0.y)), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r0.xzw = r0.xzw * r7.xyz + r11.xyz;
		r2.xyz = r2.xyz * r0.yyy;
		r0.y = saturate(dot(r2.zxy, r5.zxy));
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r0.y = ps;
		ps = specular_power.x * r0.y;
		r0.y = ps;
		r1.xyz = r1.xyz * r10.xyz;
		ps = exp2(r0.y);
		r0.y = ps;
		r0.y = r1.w * r0.y;
		r1.xyz = r1.xyz * r0.yyy;
		r11.xyz = r1.xyz * r3.www + r0.xzw;
	}
	r0.xyz = r4.xyz + -eyePosition.xyz;
	r0.y = dot(r0.zxy, viewVector.zxy);
	ps = cameraNearFar.y - cameraNearFar.x;
	r0.x = ps;
	r0.y = r0.y + -cameraNearFar.x;
	ps = clamp(rcp(r0.x), FLT_MIN, FLT_MAX);
	r0.x = ps;
	r0.x = saturate(r0.y * r0.x);
	ps = -abs(r0.x) > 0.0;
	r0.y = ps;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
	r0.xyzw = tfetch2D(g_FogTable_Texture2DDescriptorIndex, g_FogTable_SamplerDescriptorIndex, r0.xy, float2(0, 0)).xyzw;
	ps = c251.y - r0.w;
	r1.x = ps;
	r2.xyz = r1.xxx * r11.xyz;
	p0 = g_LightingPassCount.x != 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
	}
	else
	{
		r2.xyz = r0.xyz * r0.www + r2.xyz;
	}
	oC0.xyzw = max(r2.xyzw, r2.xyzw);
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
