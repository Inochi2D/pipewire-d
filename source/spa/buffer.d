/* Simple Plugin API */
/* SPDX-FileCopyrightText: Copyright © 2018 Wim Taymans */
/* SPDX-License-Identifier: MIT */
module spa.buffer;
import spa.utils;

nothrow @nogc:
extern (C):

/** \defgroup spa_buffer Buffers
 *
 * Buffers describe the data and metadata that is exchanged between
 * ports of a node.
 */

/**
 * \addtogroup spa_buffer
 * \{
 */

enum spa_data_type_t {
    SPA_DATA_Invalid,
    SPA_DATA_MemPtr, /**< pointer to memory, the data field in
					  *  struct spa_data is set. */
    SPA_DATA_MemFd, /**< generic fd, mmap to get to memory */
    SPA_DATA_DmaBuf, /**< fd to dmabuf memory */
    SPA_DATA_MemId, /**< memory is identified with an id */

    _SPA_DATA_LAST, /**< not part of ABI */

}

enum SPA_CHUNK_FLAG_NONE = 0;

/** chunk data is corrupted in some way */
enum SPA_CHUNK_FLAG_CORRUPTED = (1u << 0);

/**
* chunk data is empty with media specific neutral data such as silence or black. 
* This could be used to optimize processing.
*/
enum SPA_CHUNK_FLAG_EMPTY = (1u << 1);

/** Chunk of memory, can change for each buffer */
struct spa_chunk_t {
    /**
    * Offset of valid data. 
    * Should be taken modulo the data maxsize to get the offset
    * in the data memory. 
    */
    uint32_t offset;
    uint32_t size; /**< size of valid data. Should be clamped to maxsize. */
    int32_t stride; /** stride of valid data */
    int32_t flags; /** chunk flags */
}

enum SPA_DATA_FLAG_NONE = 0;

/** data is readable */
enum SPA_DATA_FLAG_READABLE = (1u << 0);

/** data is writable */
enum SPA_DATA_FLAG_WRITABLE = (1u << 1);

/** data pointer can be changed */
enum SPA_DATA_FLAG_DYNAMIC = (1u << 2);

enum SPA_DATA_FLAG_READWRITE = (SPA_DATA_FLAG_READABLE | SPA_DATA_FLAG_WRITABLE);

/**
* data is mappable with simple mmap/munmap. Some memory
* types are not simply mappable (DmaBuf) unless explicitly
* specified with this flag. 
*/
enum SPA_DATA_FLAG_MAPPABLE = (1u << 3);

/** Data for a buffer this stays constant for a buffer */
struct spa_data_t {
    uint32_t type; /**< memory type, one of enum spa_data_type, when
					  *  allocating memory, the type contains a bitmask
					  *  of allowed types. SPA_ID_INVALID is a special
					  *  value for the allocator to indicate that the
					  *  other side did not explicitly specify any
					  *  supported data types. It should probably use
					  *  a memory type that does not require special
					  *  handling in addition to simple mmap/munmap. */

    uint32_t flags; /**< data flags */
    int64_t fd; /**< optional fd for data */
    uint32_t mapoffset; /**< offset to map fd at */
    uint32_t maxsize; /**< max size of data */
    void* data; /**< optional data pointer */
    spa_chunk_t* chunk; /**< valid chunk of memory */
};

/** A Buffer */
struct spa_buffer_t {
    uint32_t n_metas; /**< number of metadata */
    uint32_t n_datas; /**< number of data members */
    spa_meta_t* metas; /**< array of metadata */
    spa_data_t* datas; /**< array of data members */
}

/** Find metadata in a buffer */
pragma(inline, true)
static spa_meta_t* spa_buffer_find_meta(const(spa_buffer_t)* b, uint32_t type) {
    uint32_t i;

    for (i = 0; i < b.n_metas; i++)
        if (b.metas[i].type == type)
            return &b.metas[i];

    return null;
}

pragma(inline, true)
static void* spa_buffer_find_meta_data(const(spa_buffer_t)* b, uint32_t type, size_t size) {
    spa_meta_t* m;
    if ((m = spa_buffer_find_meta(b, type)) && m.size >= size)
        return m.data;
    return null;
}


/**
 * \addtogroup spa_buffer
 * \{
 */

enum spa_meta_type_t {
	SPA_META_Invalid,
	SPA_META_Header,		/**< struct spa_meta_header */
	SPA_META_VideoCrop,		/**< struct spa_meta_region with cropping data */
	SPA_META_VideoDamage,		/**< array of struct spa_meta_region with damage, where an invalid entry or end-of-array marks the end. */
	SPA_META_Bitmap,		/**< struct spa_meta_bitmap */
	SPA_META_Cursor,		/**< struct spa_meta_cursor */
	SPA_META_Control,		/**< metadata contains a spa_meta_control
					  *  associated with the data */
	SPA_META_Busy,			/**< don't write to buffer when count > 0 */
	SPA_META_VideoTransform,	/**< struct spa_meta_transform */

	_SPA_META_LAST,			/**< not part of ABI/API */
}

/**
 * A metadata element.
 *
 * This structure is available on the buffer structure and contains
 * the type of the metadata and a pointer/size to the actual metadata
 * itself.
 */
struct spa_meta_t {
	uint32_t type;		/**< metadata type, one of enum spa_meta_type */
	uint32_t size;		/**< size of metadata */
	void* data;		/**< pointer to metadata */
}

pragma(inline, true)
__gshared void* spa_meta_first(const(spa_meta)* m) {
	return m.data;
}

pragma(inline, true)
__gshared void* spa_meta_end(const(spa_meta)* m) {
	return SPA_PTROFF!(m.data, m.size, void);
}

enum SPA_META_HEADER_FLAG_DISCONT    =	(1 << 0);	/**< data is not continuous with previous buffer */
enum SPA_META_HEADER_FLAG_CORRUPTED  =	(1 << 1);	/**< data might be corrupted */
enum SPA_META_HEADER_FLAG_MARKER     =	(1 << 2);	/**< media specific marker */
enum SPA_META_HEADER_FLAG_HEADER     =	(1 << 3);	/**< data contains a codec specific header */
enum SPA_META_HEADER_FLAG_GAP        =	(1 << 4);	/**< data contains media neutral data */
enum SPA_META_HEADER_FLAG_DELTA_UNIT =	(1 << 5);	/**< cannot be decoded independently */

/**
 * Describes essential buffer header metadata such as flags and
 * timestamps.
 */
struct spa_meta_header {
	uint32_t flags;				/**< flags */
	uint32_t offset;			/**< offset in current cycle */
	int64_t pts;				/**< presentation timestamp in nanoseconds */
	int64_t dts_offset;			/**< decoding timestamp as a difference with pts */
	uint64_t seq;				/**< sequence number, increments with a
						  *  media specific frequency */
};

/** metadata structure for Region or an array of these for RegionArray */
struct spa_meta_region_t {
	spa_region_t region;
}

pragma(inline, true)
__gshared bool spa_meta_region_is_valid(const(spa_meta_region_t)* m) {
	return m.region.size.width != 0 && m.region.size.height != 0;
}

/**
 * Bitmap information
 *
 * This metadata contains a bitmap image in the given format and size.
 * It is typically used for cursor images or other small images that are
 * better transferred inline.
 */
struct spa_meta_bitmap_t {
	uint32_t format;		/**< bitmap video format, one of enum spa_video_format. 0 is
					  *  and invalid format and should be handled as if there is
					  *  no new bitmap information. */
	spa_rectangle_t size;	/**< width and height of bitmap */
	int32_t stride;			/**< stride of bitmap data */
	uint32_t offset;		/**< offset of bitmap data in this structure. An offset of
					  *  0 means no image data (invisible), an offset >=
					  *  sizeof(struct spa_meta_bitmap) contains valid bitmap
					  *  info. */
}

/**
 * Cursor information
 *
 * Metadata to describe the position and appearance of a pointing device.
 */
struct spa_meta_cursor_t {
	uint32_t id;			/**< cursor id. an id of 0 is an invalid id and means that
					  *  there is no new cursor data */
	uint32_t flags;			/**< extra flags */
	spa_point_t position;	/**< position on screen */
	spa_point_t hotspot;	/**< offsets for hotspot in bitmap, this field has no meaning
					  *  when there is no valid bitmap (see below) */
	uint32_t bitmap_offset;		/**< offset of bitmap meta in this structure. When the offset
					  *  is 0, there is no new bitmap information. When the offset is
					  *  >= sizeof(struct spa_meta_cursor) there is a
					  *  struct spa_meta_bitmap at the offset. */
};

/** a timed set of events associated with the buffer */
struct spa_meta_control_t {
	spa_pod_sequence_t sequence;
}

/** a busy counter for the buffer */
struct spa_meta_busy_t {
	uint32_t flags;
	uint32_t count;			/**< number of users busy with the buffer */
}

enum spa_meta_videotransform_value_t {
	SPA_META_TRANSFORMATION_None = 0,	/**< no transform */
	SPA_META_TRANSFORMATION_90,		/**< 90 degree counter-clockwise */
	SPA_META_TRANSFORMATION_180,		/**< 180 degree counter-clockwise */
	SPA_META_TRANSFORMATION_270,		/**< 270 degree counter-clockwise */
	SPA_META_TRANSFORMATION_Flipped,	/**< 180 degree flipped around the vertical axis. Equivalent
						  * to a reflexion through the vertical line splitting the
						  * bufffer in two equal sized parts */
	SPA_META_TRANSFORMATION_Flipped90,	/**< flip then rotate around 90 degree counter-clockwise */
	SPA_META_TRANSFORMATION_Flipped180,	/**< flip then rotate around 180 degree counter-clockwise */
	SPA_META_TRANSFORMATION_Flipped270,	/**< flip then rotate around 270 degree counter-clockwise */
}

/** a transformation of the buffer */
struct spa_meta_videotransform_t {
	uint32_t transform;			/**< orientation transformation that was applied to the buffer,
						  *  one of enum spa_meta_videotransform_value */
}
