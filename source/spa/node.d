module spa.node;
import spa.pod;

nothrow @nogc:
extern (C):

enum spa_node_command_t {
	SPA_NODE_COMMAND_Suspend,	/**< suspend a node, this removes all configured
					  * formats and closes any devices */
	SPA_NODE_COMMAND_Pause,		/**< pause a node. this makes it stop emitting
					  *  scheduling events */
	SPA_NODE_COMMAND_Start,		/**< start a node, this makes it start emitting
					  *  scheduling events */
	SPA_NODE_COMMAND_Enable,
	SPA_NODE_COMMAND_Disable,
	SPA_NODE_COMMAND_Flush,
	SPA_NODE_COMMAND_Drain,
	SPA_NODE_COMMAND_Marker,
	SPA_NODE_COMMAND_ParamBegin,	/**< begin a set of parameter enumerations or
					  *  configuration that require the device to
					  *  remain opened, like query formats and then
					  *  set a format */
	SPA_NODE_COMMAND_ParamEnd,	/**< end a transaction */
	SPA_NODE_COMMAND_RequestProcess,/**< Sent to a driver when some other node emitted
					  *  the RequestProcess event. */
}

struct spa_command_body_t {
	spa_pod_object_body_t body_;
};

struct spa_command {
	spa_pod_t          pod;
	spa_command_body_t body_;
};
