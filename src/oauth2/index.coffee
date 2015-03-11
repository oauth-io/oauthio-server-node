request = require 'request'
ejs = require 'ejs'
fs = require 'fs'
qs = require 'qs'

module.exports = (env) ->
	oauth2 =
		# This method must be overriden by the provider, and return the user's id from a request object
		getUserId: (req) ->
			null

		sendError: (res, message) ->
			res.status 403
			res.send {
				'success': 'false',
				data: {
					message: message
				}
			}


		# Endpoint that delivers the decision page
		getauthorize: () ->
			# here we should have req.template and req.data
			(req, res, next) ->
				env.log 'Called authorize'
				scope = req.query.scope?.split(' ') || []
				request {
					rejectUnauthorized: not env.config.debug
					url: env.config.oauthd_url + '/oauth2/clients/' + req.query.client_id
					headers: {
						authorizationp: env.auth_header
					}
				}, (err, resp, body) ->
					try
						body = JSON.parse body
						client = body.data
						req.data.client = client
						req.data.scope = scope
						fs.readFile req.template, {encoding:  'UTF-8'}, (err, str) -> #reads the tpl given by the provider
							env.log str
							res.status(200)
							res.send ejs.render(str, req.data) # fills the template with the user's data + the client
					catch e
						return res.status(500)
						res.send('An error occured')

		# Endpoint to be called with decision
		postauthorize: () ->
			(req, res, next) ->
				req.query.userId = oauth2.getUserId(req) #req.session.user?.id
				if not req.query.userId?
					return res.status(403).send('Unauthorized request')
				request {
					rejectUnauthorized: not env.config.debug
					url: env.config.oauthd_url + '/oauth2/authorization?' + qs.stringify(req.query),
					json: req.body
					method: 'POST'
					headers:{
						authorizationp: env.auth_header
					}
				}, (err, resp, body) ->
					if err
						env.log 'Error while authorizing', err
						res.status(500)
						res.send('An error occured')
						return
					res.setHeader 'Location', resp.headers.location
					res.status(resp.statusCode)
					res.send(body)


		# Endpoint to be called for access token retrieval (with code) or refresh (with refresh token)
		token: () ->
			(req, res, next) ->
				start_date = new Date().getTime()
				env.log 'Called token'
				options = {
					rejectUnauthorized: not env.config.debug
					url: env.config.oauthd_url + '/oauth2/token'
					json: req.body
					method: 'POST'
					headers:{
						authorizationp: env.auth_header
					}
				}
				request options, (err, resp, body) ->
					date = new Date().getTime()
					res.status(200)
					res.send(body)

		# Middleware which takes the access token, interrogates oauthd and sets req.OAuth2
		# Available values:
		# - req.OAuth2.scope
		# - req.OAuth2.userId
		# - req.OAuth2.clientId
		check: (options) ->
			scope = options.scope || []
			defaultOptions = {
				errorHandling: true
			}
			for k,v of defaultOptions
				options[k] = v if not options[k]?

			(req, res, next) ->
				access_token = req.query.access_token || req.body.access_token || req.headers.authorization?.split(' ')?[1]
				request {
					rejectUnauthorized: not env.config.debug
					url: env.config.oauthd_url + '/oauth2/check?access_token=' + access_token,
					headers:{
						authorizationp: env.auth_header
					}
				}, (err, resp, body) ->
					try
						body = JSON.parse body
						if resp.statusCode == 200
							req.OAuth2 = body.data
							authorized = true
							for k,v of scope
								if v not in req.OAuth2.scope
									authorized = false
							req.OAuth2.authorized = authorized
							if options.errorHandling and not authorized
								return oauth2.sendError res, 'This client does not have the proper authorization scope'
							next()
						else
							if resp.headers?['Content-Type']
								res.setHeader 'Content-Type', resp.headers?['Content-Type']
							res.status(resp.statusCode)
							res.send body || 'Invalid auth'
					catch e
						res.status(500)
						res.send 'An error occured'
	oauth2
