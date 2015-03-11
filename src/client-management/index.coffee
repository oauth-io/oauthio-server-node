request = require 'request'
Q = require 'q'

module.exports = (env) ->
		# Retrieves all clients, and filters by userId if given
		getAll: (userId) ->
			defer = Q.defer()
			options = {
				rejectUnauthorized: not env.config.debug
				url: env.config.oauthd_url + '/oauth2/clients/all/' + userId,
				headers: {
					authorizationp: env.auth_header
				}
			}
			request options, (err, resp, body) ->
				env.log err if err
				if typeof body == 'string'
					try
						body = JSON.parse body
					catch e
						defer.reject e
				if resp.statusCode == 200 and not err?
					defer.resolve body.data
				else
					env.log 'Tried to retrieve all clients, got ', resp.statusCode, body
					defer.reject new Error 'Could not retrieve the clients'
			defer.promise

		# Retrieves a client by its clientId
		get: (client_id) ->
			defer = Q.defer()
			options = {
				rejectUnauthorized: not env.config.debug
				url: env.config.oauthd_url + '/oauth2/clients/' + client_id,
				headers: {
					authorizationp: env.auth_header
				}
			}
			request options, (err, resp, body) ->
				env.log err if err
				if typeof body == 'string'
					try
						body = JSON.parse body
					catch e
						defer.reject e
				if resp.statusCode == 200 and not err?
					defer.resolve body.data
				else
					defer.reject new Error 'Could not retrieve the client ' + client_id
			defer.promise

		# Creates a client
		# client.name
		# client.description
		# client.userId
		# client.redirectUri
		create: (client) ->
			defer = Q.defer()
			options = {
				rejectUnauthorized: not env.config.debug
				url: env.config.oauthd_url + '/oauth2/clients',
				method: 'POST',
				headers: {
					authorizationp: env.auth_header
				},
				json: client
			}
			request options, (err, resp, body) ->
				env.log err if err
				if typeof body == 'string'
					try
						body = JSON.parse body
					catch e
						defer.reject e
				if resp.statusCode == 200 and not err?
					defer.resolve body.data
				else
					defer.reject new Error 'Could not create the client'
			defer.promise

		# Updates a client
		# client.id
		# client.name
		# client.description
		# client.userId
		# client.redirectUri
		# client.client_id
		# client.client_secret
		update: (client) ->
			defer = Q.defer()
			options = {
				rejectUnauthorized: not env.config.debug
				url: env.config.oauthd_url + '/oauth2/clients',
				method: 'PUT',
				headers: {
					authorizationp: env.auth_header
				},
				json: client
			}
			request options, (err, resp, body) ->
				env.log err if err
				if typeof body == 'string'
					try
						body = JSON.parse body
					catch e
						defer.reject e
				if resp.statusCode == 200 and not err?
					defer.resolve body.data
				else
					defer.reject new Error 'Could not update the client'
			defer.promise

		# Removes a client
		delete: (client_id) ->
			defer = Q.defer()
			options = {
				rejectUnauthorized: not env.config.debug
				url: env.config.oauthd_url + '/oauth2/clients/' + client_id,
				method: 'DELETE',
				headers: {
					authorizationp: env.auth_header
				}
			}
			request options, (err, resp, body) ->
				env.log err if err
				if typeof body == 'string'
					try
						body = JSON.parse body
					catch e
						defer.reject e
				if resp.statusCode == 200 and not err?
					defer.resolve body.data
				else
					defer.reject new Error 'Could not delete the client'
			defer.promise

		# Regenerates keys for a client
		regenerateKeys: (client_id) ->
			defer = Q.defer()
			options = {
				rejectUnauthorized: not env.config.debug
				url: env.config.oauthd_url + '/oauth2/clients/keygen/' + client_id,
				method: 'POST',
				headers: {
					authorizationp: env.auth_header
				}
			}
			request options, (err, resp, body) ->
				env.log err if err
				if typeof body == 'string'
					try
						body = JSON.parse body

					catch e
						defer.reject e
				if resp.statusCode == 200 and not err?
					defer.resolve body.data
				else
					defer.reject new Error 'Could not regenerate the client\'s keys'
			defer.promise
