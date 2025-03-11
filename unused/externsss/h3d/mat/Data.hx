package h3d.mat;

@:native("h3d.mat.Data") extern enum Face {
	None;
	Back;
	Front;
	Both;
}

@:native("h3d.mat.Data") extern enum Blend {
	One;
	Zero;
	SrcAlpha;
	SrcColor;
	DstAlpha;
	DstColor;
	OneMinusSrcAlpha;
	OneMinusSrcColor;
	OneMinusDstAlpha;
	OneMinusDstColor;
	ConstantColor;
	ConstantAlpha;
	OneMinusConstantColor;
	OneMinusConstantAlpha;
	SrcAlphaSaturate;
}

@:native("h3d.mat.Data") extern enum Compare {
	Always;
	Never;
	Equal;
	NotEqual;
	Greater;
	GreaterEqual;
	Less;
	LessEqual;
}

@:native("h3d.mat.Data") extern enum StencilOp {
	Keep;
	Zero;
	Replace;
	Increment;
	IncrementWrap;
	Decrement;
	DecrementWrap;
	Invert;
}

@:native("h3d.mat.Data") extern enum MipMap {
	None;
	Nearest;
	Linear;
}

@:native("h3d.mat.Data") extern enum Filter {
	Nearest;
	Linear;
}

@:native("h3d.mat.Data") extern enum Wrap {
	Clamp;
	Repeat;
}

@:native("h3d.mat.Data") extern enum Operation {
	Add;
	Sub;
	ReverseSub;
	Min;
	Max;
}

@:native("h3d.mat.Data") extern enum TextureFlags {
	/**
		
				Allocate a texture that will be used as render target.
			
	**/
	Target;
	/**
		
				Allocate a cube texture. Might be restricted to power of two textures only.
			
	**/
	Cube;
	/**
		
				Activates Mip Mapping for this texture. Might not be available for target textures.
			
	**/
	MipMapped;
	/**
		
				By default, textures created with MipMapped will have their mipmaps generated when you upload the mipmap level 0. This flag disables this and manually upload mipmaps instead.
			
	**/
	ManualMipMapGen;
	/**
		
				This is a not power of two texture. Automatically set when having width or height being not power of two.
			
	**/
	IsNPOT;
	/**
		
				Don't initialy allocate the texture memory.
			
	**/
	NoAlloc;
	/**
		
				Inform that we will often perform upload operations on this texture
			
	**/
	Dynamic;
	/**
		
				Assumes that the color value of the texture is premultiplied by the alpha component.
			
	**/
	AlphaPremultiplied;
	/**
		
				Tells if the target texture has been cleared (reserved for internal engine usage).
			
	**/
	WasCleared;
	/**
		
				The texture is being currently loaded. Set onLoaded to get event when loading is complete.
			
	**/
	Loading;
	/**
		
				Allow texture data serialization when found in a scene (for user generated textures)
			
	**/
	Serialize;
	/**
		
				Tells if it's a texture array
			
	**/
	IsArray;
	/**
		
				Allows the texture to be loaded asynchronously (requires initializating hxd.res.Image.ASYNC_LOADER)
			
	**/
	AsyncLoading;
	/**
		
				By default, the texture are loaded from images when created. If this flag is enabled, the texture will be loaded from disk when first used.
			
	**/
	LazyLoading;
	/**
		
				Texture can be written in shaders using RWTexture
			
	**/
	Writable;
	/**
		
				Tells if it's a 3D texture
			
	**/
	Is3D;
}

typedef TextureFormat = Dynamic;