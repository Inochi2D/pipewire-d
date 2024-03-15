module pipewire.stream;
import spa.buffer;
import spa.param;
import spa.node;

import core.stdc.stdint;

nothrow @nogc:
extern (C):

/** \defgroup pw_stream Stream
 *
 * \brief PipeWire stream objects
 *
 * The stream object provides a convenient way to send and
 * receive data streams from/to PipeWire.
 *
 * \see \ref page_streams, \ref api_pw_core
 */
struct pw_stream_t;

/** \pw_stream_state_t The state of a stream */
enum pw_stream_state_t {
    PW_STREAM_STATE_ERROR = -1, /**< the stream is in error */
    PW_STREAM_STATE_UNCONNECTED = 0, /**< unconnected */
    PW_STREAM_STATE_CONNECTING = 1, /**< connection is in progress */
    PW_STREAM_STATE_PAUSED = 2, /**< paused */
    PW_STREAM_STATE_STREAMING = 3 /**< streaming */
}

/** a buffer structure obtained from pw_stream_dequeue_buffer(). The size of this
  * structure can grow as more field are added in the future */
struct pw_buffer_t {
    spa_buffer_t* buffer; /**< the spa buffer */
    void* user_data; /**< user data attached to the buffer */
    uint64_t size; /**< This field is set by the user and the sum of
					  *  all queued buffer is returned in the time info.
					  *  For audio, it is advised to use the number of
					  *  samples in the buffer for this field. */
    uint64_t requested; /**< For playback streams, this field contains the
					  *  suggested amount of data to provide. For audio
					  *  streams this will be the amount of samples
					  *  required by the resampler. This field is 0
					  *  when no suggestion is provided. Since 0.3.49 */
}

struct pw_stream_control_t {
    const(char)* name; /**< name of the control */
    uint32_t flags; /**< extra flags (unused) */
    float def; /**< default value */
    float min; /**< min value */
    float max; /**< max value */
    float* values; /**< array of values */
    uint32_t n_values; /**< number of values in array */
    uint32_t max_values; /**< max values that can be set on this control */
}

/** A time structure.
 *
 * Use pw_stream_get_time_n() to get an updated time snapshot of the stream.
 * The time snapshot can give information about the time in the driver of the
 * graph, the delay to the edge of the graph and the internal queuing in the
 * stream.
 *
 * pw_time.ticks gives a monotonic increasing counter of the time in the graph
 * driver. I can be used to generate a timetime to schedule samples as well
 * as detect discontinuities in the timeline caused by xruns.
 *
 * pw_time.delay is expressed as pw_time.rate, the time domain of the graph. This
 * value, and pw_time.ticks, were captured at pw_time.now and can be extrapolated
 * to the current time like this:
 *
 *\code{.c}
 *    uint64_t now = pw_stream_get_nsec(stream);
 *    int64_t diff = now - pw_time.now;
 *    int64_t elapsed = (pw_time.rate.denom * diff) / (pw_time.rate.num * SPA_NSEC_PER_SEC);
 *\endcode
 *
 * pw_time.delay contains the total delay that a signal will travel through the
 * graph. This includes the delay caused by filters in the graph as well as delays
 * caused by the hardware. The delay is usually quite stable and should only change when
 * the topology, quantum or samplerate of the graph changes.
 *
 * pw_time.queued and pw_time.buffered is expressed in the time domain of the stream,
 * or the format that is used for the buffers of this stream.
 *
 * pw_time.queued is the sum of all the pw_buffer.size fields of the buffers that are
 * currently queued in the stream but not yet processed. The application can choose
 * the units of this value, for example, time, samples or bytes (below expressed
 * as app.rate).
 *
 * pw_time.buffered is format dependent, for audio/raw it contains the number of samples
 * that are buffered inside the resampler/converter.
 *
 * The total delay of data in a stream is the sum of the queued and buffered data
 * (not yet processed data) and the delay to the edge of the graph, usually a
 * playback or capture device.
 *
 * For an audio playback stream, if you were to queue a buffer, the total delay
 * in milliseconds for the first sample in the newly queued buffer to be played
 * by the hardware can be calculated as:
 *
 *\code{.unparsed}
 *  (pw_time.buffered * 1000 / stream.samplerate) +
 *    (pw_time.queued * 1000 / app.rate) +
 *     ((pw_time.delay - elapsed) * 1000 * pw_time.rate.num / pw_time.rate.denom)
 *\endcode
 *
 * The current extrapolated time (in ms) in the source or sink can be calculated as:
 *
 *\code{.unparsed}
 *  (pw_time.ticks + elapsed) * 1000 * pw_time.rate.num / pw_time.rate.denom
 *\endcode
 *
 * Below is an overview of the different timing values:
 *
 *\code{.unparsed}
 *           stream time domain           graph time domain
 *         /-----------------------\/-----------------------------\
 *
 * queue     +-+ +-+  +-----------+                 +--------+
 * ---->     | | | |->| converter | ->   graph  ->  | kernel | -> speaker
 * <----     +-+ +-+  +-----------+                 +--------+
 * dequeue   buffers                \-------------------/\--------/
 *                                     graph              internal
 *                                    latency             latency
 *         \--------/\-------------/\-----------------------------/
 *           queued      buffered            delay
 *\endcode
 */
struct pw_time_t {
    int64_t now; /**< the monotonic time in nanoseconds. This is the time
					  *  when this time report was updated. It is usually
					  *  updated every graph cycle. You can use the current
					  *  monotonic time to calculate the elapsed time between
					  *  this report and the current state and calculate
					  *  updated ticks and delay values. */
    spa_fraction_t rate; /**< the rate of \a ticks and delay. This is usually
					  *  expressed in 1/<samplerate>. */
    uint64_t ticks; /**< the ticks at \a now. This is the current time that
					  *  the remote end is reading/writing. This is monotonicaly
					  *  increasing. */
    int64_t delay; /**< delay to device. This is the time it will take for
					  *  the next output sample of the stream to be presented by
					  *  the playback device or the time a sample traveled
					  *  from the capture device. This delay includes the
					  *  delay introduced by all filters on the path between
					  *  the stream and the device. The delay is normally
					  *  constant in a graph and can change when the topology
					  *  of the graph or the quantum changes. This delay does
					  *  not include the delay caused by queued buffers. */
    uint64_t queued; /**< data queued in the stream, this is the sum
					  *  of the size fields in the pw_buffer that are
					  *  currently queued */
    uint64_t buffered; /**< for audio/raw streams, this contains the extra
					  *  number of samples buffered in the resampler.
					  *  Since 0.3.50. */
    uint32_t queued_buffers; /**< The number of buffers that are queued. Since 0.3.50 */
    uint32_t avail_buffers; /**< The number of buffers that can be dequeued. Since 0.3.50 */
}

/** Events for a stream. These events are always called from the mainloop
 * unless explicitly documented otherwise. */
struct pw_stream_events_t {
    uint32_t version_;

    void function(void*) destroy;
    /** when the stream state changes */
    void function(void* data, pw_stream_state_t old,
        pw_stream_state_t state, const(char)* error) state_changed;

    /** Notify information about a control.  */
    void function(void* data, uint32_t id, const(pw_stream_control_t)* control) control_info;

    /** when io changed on the stream. */
    void function(void* data, uint32_t id, void* area, uint32_t size) io_changed;
    /** when a parameter changed */
    void function(void* data, uint32_t id, const(spa_pod_t)* param) param_changed;

    /** when a new buffer was created for this stream */
    void function(void* data, pw_buffer* buffer) add_buffer;
    /** when a buffer was destroyed for this stream */
    void function(void* data, pw_buffer* buffer) remove_buffer;

    /** when a buffer can be queued (for playback streams) or
    *  dequeued (for capture streams). This is normally called from the
    *  mainloop but can also be called directly from the realtime data
    *  thread if the user is prepared to deal with this. */
    void function(void* data) process;

    /** The stream is drained */
    void function(void* data) drained;

    /** A command notify, Since 0.3.39:1 */
    void function(void* data, const(spa_command_t)* command) command;

    /** a trigger_process completed. Since version 0.3.40:2 */
    void function(void* data) trigger_done;
}

/** Convert a stream state to a readable string */
const(char)* pw_stream_state_as_string(pw_stream_state_t state);

/** \pw_stream_flags_t Extra flags that can be used in \ref pw_stream_connect() */
enum pw_stream_flags_t {
    PW_STREAM_FLAG_NONE = 0, /**< no flags */
    PW_STREAM_FLAG_AUTOCONNECT = (1 << 0), /**< try to automatically connect
							  *  this stream */
    PW_STREAM_FLAG_INACTIVE = (1 << 1), /**< start the stream inactive,
							  *  pw_stream_set_active() needs to be
							  *  called explicitly */
    PW_STREAM_FLAG_MAP_BUFFERS = (1 << 2), /**< mmap the buffers except DmaBuf that is not
							  *  explicitly marked as mappable. */
    PW_STREAM_FLAG_DRIVER = (1 << 3), /**< be a driver */
    PW_STREAM_FLAG_RT_PROCESS = (1 << 4), /**< call process from the realtime
							  *  thread. You MUST use RT safe functions
							  *  in the process callback. */
    PW_STREAM_FLAG_NO_CONVERT = (1 << 5), /**< don't convert format */
    PW_STREAM_FLAG_EXCLUSIVE = (1 << 6), /**< require exclusive access to the
							  *  device */
    PW_STREAM_FLAG_DONT_RECONNECT = (1 << 7), /**< don't try to reconnect this stream
							  *  when the sink/source is removed */
    PW_STREAM_FLAG_ALLOC_BUFFERS = (1 << 8), /**< the application will allocate buffer
							  *  memory. In the add_buffer event, the
							  *  data of the buffer should be set */
    PW_STREAM_FLAG_TRIGGER = (1 << 9), /**< the output stream will not be scheduled
							  *  automatically but _trigger_process()
							  *  needs to be called. This can be used
							  *  when the output of the stream depends
							  *  on input from other streams. */
    PW_STREAM_FLAG_ASYNC = (1 << 10), /**< Buffers will not be dequeued/queued from
							  *  the realtime process() function. This is
							  *  assumed when RT_PROCESS is unset but can
							  *  also be the case when the process() function
							  *  does a trigger_process() that will then
							  *  dequeue/queue a buffer from another process()
							  *  function. since 0.3.73 */
    PW_STREAM_FLAG_EARLY_PROCESS = (1 << 11), /**< Call process as soon as there is a buffer
							  *  to dequeue. This is only relevant for
							  *  playback and when not using RT_PROCESS. It
							  *  can be used to keep the maximum number of
							  *  buffers queued. Since 0.3.81 */

}

/** Create a new unconneced \ref pw_stream
 * \return a newly allocated \ref pw_stream */
pw_stream_t* pw_stream_new(pw_core_t* core, /**< a \ref pw_core */
        const(char)* name, /**< a stream media name */
        pw_properties_t* props /**< stream properties, ownership is taken */ );

pw_stream_t* pw_stream_new_simple(pw_loop_t* loop, /**< a \ref pw_loop to use */
        const(char)* name, /**< a stream media name */
        pw_properties_t* props, /**< stream properties, ownership is taken */
        const(pw_stream_events_t)* events, /**< stream events */
        void* data /**< data passed to events */ );

/** Destroy a stream */
void pw_stream_destroy(pw_stream_t* stream);

void pw_stream_add_listener(pw_stream_t* stream,
    spa_hook_t* listener,
    const(pw_stream_events_t)* events,
    void* data);

pw_stream_state_t pw_stream_get_state(pw_stream_t* stream, const(char)** error);

const(char)* pw_stream_get_name(pw_stream_t* stream);

pw_core_t* pw_stream_get_core(pw_stream_t * stream);

const(pw_properties_t)* pw_stream_get_properties(pw_stream_t * stream);

int pw_stream_update_properties(pw_stream_t* stream, const(spa_dict_t)** dict);

/** Connect a stream for input or output on \a port_path.
 * \return 0 on success < 0 on error.
 *
 * You should connect to the process event and use pw_stream_dequeue_buffer()
 * to get the latest metadata and data. */
int pw_stream_connect(pw_stream_t* stream, /**< a \ref pw_stream */
    pw_direction_t direction, /**< the stream direction */
    uint32_t target_id, /**< should have the value PW_ID_ANY.
							  * To select a specific target
							  * node, specify the
							  * PW_KEY_OBJECT_SERIAL or the
							  * PW_KEY_NODE_NAME value of the target
							  * node in the PW_KEY_TARGET_OBJECT
							  * property of the stream.
							  * Specifying target nodes by
							  * their id is deprecated.
							  */
    pw_stream_flags_t flags, /**< stream flags */
    const(spa_pod_t)** params, /**< an array with params. The params
							  *  should ideally contain supported
							  *  formats. */
    uint32_t n_params /**< number of items in \a params */ );

/** Get the node ID of the stream.
 * \return node ID. */
uint32_t pw_stream_get_node_id(pw_stream_t* stream);

/** Disconnect \a stream  */
int pw_stream_disconnect(pw_stream_t* stream);

/** Set the stream in error state */
int pw_stream_set_error(pw_stream_t * stream, /**< a \ref pw_stream */
    int res, /**< a result code */
    const(char)* error, /**< an error message */
    ...);

/** Update the param exposed on the stream. */
int pw_stream_update_params(pw_stream_t * stream, /**< a \ref pw_stream */
    const(spa_pod_t)** params, /**< an array of params. */
    uint32_t n_params /**< number of elements in \a params */ );

/**
 * Set a parameter on the stream. This is like pw_stream_set_control() but with
 * a complete spa_pod param. It can also be called from the param_changed event handler
 * to intercept and modify the param for the adapter. Since 0.3.70 */
int pw_stream_set_param(pw_stream_t * stream, /**< a \ref pw_stream */
    uint32_t id, /**< the id of the param */
    const(spa_pod)* param /**< the params to set */ );

/** Get control values */
const(pw_stream_control_t) * pw_stream_get_control(pw_stream_t * stream, uint32_t id);

/** Set control values */
int pw_stream_set_control(pw_stream_t* stream, uint32_t id, uint32_t n_values, float* values, ...);

/** Query the time on the stream */
int pw_stream_get_time_n(pw_stream_t * stream, pw_time_t* time, size_t size);

/** Get the current time in nanoseconds. This value can be compared with
 * the pw_time_now value. Since 1.0.4 */
uint64_t pw_stream_get_nsec(pw_stream_t* stream);

/** Get a buffer that can be filled for playback streams or consumed
 * for capture streams. */
pw_buffer_t* pw_stream_dequeue_buffer(pw_stream_t * stream);

/** Submit a buffer for playback or recycle a buffer for capture. */
int pw_stream_queue_buffer(pw_stream_t * stream, pw_buffer_t* buffer);

/** Activate or deactivate the stream */
int pw_stream_set_active(pw_stream_t* stream, bool active);

/** Flush a stream. When \a drain is true, the drained callback will
 * be called when all data is played or recorded */
int pw_stream_flush(pw_stream_t* stream, bool drain);

/** Check if the stream is driving. The stream needs to have the
 * PW_STREAM_FLAG_DRIVER set. When the stream is driving,
 * pw_stream_trigger_process() needs to be called when data is
 * available (output) or needed (input). Since 0.3.34 */
bool pw_stream_is_driving(pw_stream_t* stream);

/** Trigger a push/pull on the stream. One iteration of the graph will
 * scheduled and process() will be called. Since 0.3.34 */
int pw_stream_trigger_process(pw_stream_t* stream);
