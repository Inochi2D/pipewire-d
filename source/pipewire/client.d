module pipewire.client;

struct pw_client_t;

/* default ID of the current client after connect */
enum PW_ID_CLIENT =			1;

enum PW_CLIENT_CHANGE_MASK_PROPS =	(1 << 0);
enum PW_CLIENT_CHANGE_MASK_ALL =	((1 << 1)-1);

struct pw_client_info_t {
	uint32_t id;			/**< id of the global */
	uint64_t change_mask;		/**< bitfield of changed fields since last call */
	spa_dict_t* props;		/**< extra properties */
}

/** Update an existing \ref pw_client_info with \a update with reset */
pw_client_info_t *
pw_client_info_update(pw_client_info_t *info,
		const(pw_client_info_t) *update);

/** Merge an existing \ref pw_client_info with \a update */
pw_client_info_t *
pw_client_info_merge(pw_client_info_t *info,
		const(pw_client_info_t) *update, bool reset);
        
/** Free a \ref pw_client_info */
void pw_client_info_free(pw_client_info_t *info);

/** Client events */
struct pw_client_events_t {
	uint32_t version_;
	/**
	 * Notify client info
	 *
	 * \param info info about the client
	 */
	void function(void *data, const(pw_client_info_t) *info) info;
	/**
	 * Notify a client permission
	 *
	 * Event emitted as a result of the get_permissions method.
	 *
	 * \param default_permissions the default permissions
	 * \param index the index of the first permission entry
	 * \param n_permissions the number of permissions
	 * \param permissions the permissions
	 */
	void function(void *data,
			     uint32_t index,
			     uint32_t n_permissions,
			     const(pw_permission_t)* permissions) permissions;
}

/** Client methods */
struct pw_client_methods {
	uint32_t version_;

	int function(void *object,
			spa_hook_t* listener,
			const(pw_client_events_t) *events,
			void *data) add_listener;
	/**
	 * Send an error to a client
	 *
	 * \param id the global id to report the error on
	 * \param res an errno style error code
	 * \param message an error string
	 *
	 * This requires W and X permissions on the client.
	 */
	int function(void *object, uint32_t id, int res, const char *message) error;
	/**
	 * Update client properties
	 *
	 * \param props new properties
	 *
	 * This requires W and X permissions on the client.
	 */
	int function(void *object, const(spa_dict_t) *props) update_properties;

	/**
	 * Get client permissions
	 *
	 * A permissions event will be emitted with the permissions.
	 *
	 * \param index the first index to query, 0 for first
	 * \param num the maximum number of items to get
	 *
	 * This requires W and X permissions on the client.
	 */
	int function(void *object, uint32_t index, uint32_t num) get_permissions;
	/**
	 * Manage the permissions of the global objects for this
	 * client
	 *
	 * Update the permissions of the global objects using the
	 * provided array with permissions
	 *
	 * Globals can use the default permissions or can have specific
	 * permissions assigned to them.
	 *
	 * \param n_permissions number of permissions
	 * \param permissions array of permissions
	 *
	 * This requires W and X permissions on the client.
	 */
	int function(void *object, uint32_t n_permissions,
			const(pw_permission_t)* permissions) update_permissions;
}