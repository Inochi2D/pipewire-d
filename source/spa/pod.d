module spa.pod;

nothrow @nogc:
extern (C):


struct spa_pod_t {
	uint32_t size;		/* size of the body */
	uint32_t type;		/* a basic id of enum spa_type */
}

struct spa_pod_bool_t {
	spa_pod_t pod;
	int32_t value;
	int32_t _padding;
}

struct spa_pod_id_t {
	spa_pod_t pod;
	uint32_t value;
	int32_t _padding;
}

struct spa_pod_int_t {
	spa_pod_t pod;
	int32_t value;
	int32_t _padding;
}

struct spa_pod_long_t {
	spa_pod_t pod;
	int64_t value;
}

struct spa_pod_float_t {
	spa_pod_t pod;
	float value;
	int32_t _padding;
}

struct spa_pod_double_t {
	spa_pod_t pod;
	double value;
}

struct spa_pod_string_t {
	spa_pod_t pod;
	/* value here */
}

struct spa_pod_bytes_t {
	spa_pod_t pod;
	/* value here */
}

struct spa_pod_rectangle_t {
	spa_pod_t pod;
	spa_rectangle_t value;
}

struct spa_pod_fraction_t {
	spa_pod_t pod;
	spa_fraction_t value;
}

struct spa_pod_bitmap_t {
	spa_pod_t pod;
	/* array of uint8_t follows with the bitmap */
}