request = require 'request'
ejs = require 'ejs'
fs = require 'fs'
qs = require 'qs'
Q = require 'q'

env = {
	config: {
		debug: true
	}
	log: () ->
		if env.config.debug
			console.log.apply null, arguments
		else
			return
}


sdk =
	# Initialization the SDK with the provider credentials, and eventual options
	initialize: (provider_id, provider_secret, options) ->
		env.config.provider_id = provider_id
		env.config.provider_secret = provider_secret
		if options?
			for k,v of options
				env.config[k] = v
		env.auth_header = 'Basic ' + new Buffer(env.config.provider_id + ':' + env.config.provider_secret, 'ascii').toString('base64')
		env.config.oauthd_url = 'http://localhost:6284'

	# OAuth2 endpoints & middlewares
	OAuth2: require('./oauth2')(env)

	# Client management for developer portal (accesses the oauthd's Client API)
	clients: require('./client-management')(env)

module.exports = sdk
