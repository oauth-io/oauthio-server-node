OAuth.io Providing SDK
======================

This SDK allows you to use the OAuth 2.0 providing features of OAuth.io.

OAuth 2.0 allows you to add an authentication layer to your API, according the the [RFC 6749](https://tools.ietf.org/html/rfc6749).

Pre-requisite
-------------

> *Express Framework is required*
>
> This SDK has been made to work on top of Express. Other frameworks are not supported during the BETA.

**Create a provider on OAuth.io/oauthd**

First, you need to create a provider on [OAuth.io](https://oauth.io), or in your [oauthd instance](https://github.com/oauth-io/oauthd).

There you will be able to configure the provider with a **name**, and a complete **authorization items** list (with which clients will define their scope).

You'll be able to retrieve the **provider_id** and the **provider_secret**, which will enable you to initialize the SDK on your node.js API server.

**User management**

Your server must have some kind of user management, as client applications will use your API on behalf of your users.


Installation
------------

To install the SDK, just run the following command in your API server application:

```sh
$ node install oauthio-server
```


OAuth 2.0 with oauthd
---------------------

### Introduction

The OAuth 2.0 framework allows you to secure your API endpoints with an authentication layer. This lets apps call the endpoints on behalf of your users, after having asked for a scope of permissions.

The authentication is done thanks to an access token, which is given with any call to the API.

The token is recognized, and the associated user, associated app and the available permissions scope are found so the API is able to decide if it will send resource or not.

To obtain the access token, the following processs is used:

- First, the app (the client) registers on the API provider's developer portal, to obtain a client id and a client secret.
- Then, a user (already subscribed to the API provider's service), launches an action on the client's website, which needs resources from the provider's API.
- The user is redirected on the provider's website (usually on the `/authorize` endpoint) with information about who the client is
- The user logs in to the provider's website, and responds to a **decision form**, in which he can see what permissions the client app wants on his account on the provider's API
- Upon acceptation, the user is redirected to the client's website, on a specific callback URL, with an authentication code
- The client then exchanges the authentication code for an access token by calling the `/token` endpoint on the provider's API.

Implementing all this, be it from the client's point of view, or from the provider's, is quite long and tedious.

> For the client part, check out OAuth.io and oauthd's client services, which will enable you to integrate over 100 APIs in your application in a matter of minutes.

### Initializing the SDK

Once you have created a provider on OAuth.io or oauthd, and installed the SDK via npm, you need to initialize the SDK with your **provider_id** and **provider_secret**:

```javascript
OAuthProvider = require('oauthio-server');

OAuthProvider.initialize('your_provider_id', 'your_provider_secret');
```

Once that's done, you will be able to create the endpoints for the OAuth 2.0 dance, and use the client management methods to create and edit your client apps from your developer portal.

### OAuth 2.0 dance endpoints

#### Recognizing the user

The first thing you need to do is to provide the SDK a way to recognize your currently logged in user from a connect request object, by overriding the `OAuth2.getUserId` method. For example, if the user id is stored in the session , you can do something like this:

```javascript
OAuthProvider.OAuth2.getUserId = (req) => {
    return req.session.user.id
}
```

#### Authorize

Then you'll need to create two endpoints for the `/authorize` URL. You can put another URL if you want, but `/authorize` is recommended by the OAuth 2.0 RFC.

**GET /authorize**

First, you need to create an endpoint for the `GET` method, which will redirect the user to a login page if he is not logged in, and then, show the decision form.

If the user is not logged in, you need to redirect him to the log in page **with the same GET parameters**, and the location of the authorization endpoint. Once the user is logged in, he should be redirected once more to the authorization endpoint with the original get parameters.

Here's an example of how you could do it:


```javascript
// authorization endpoint login middleware
var isLoggedIn = function (req, res, next) {
    if (req.session.user) {
        // if the user is connected, continue to the authorization endpoint
        next();
    } else {
        // otherwise, redirect him to the login endpoint
        
        // the backUrl variable will enable the login endpoint
        // to redirect to the authorization page once the user is logged in
        var backUrl = req.path;
        // appends the backUrl to the GET parameters
        req.query.backUrl = backUrl; 

        // the qs stringify transforms an object in 
        // a url ready parameters string
        var parameters = qs.stringify(req.query); 
        res.redirect('/login?' + parameters);
    }
};


// Log in page
app.get('/login', function (req, res, next) {
    // serve the login page, for example:
    res.sendFile(__dirname + '/templates/login.html');
});

// Login form action
app.post('/login', function (req, res, next) {
    // login the user (of course this is simplified ;) )
    if (req.body.username == 'theuser' and req.body.password == 'thepassword') {
        req.session.user = {
            id: 'theuserid',
            username: 'theuser'
        }
        
        // redirect to backUrl, with the same GET parameters
        var backUrl = req.query.backUrl;
        delete req.query.backUrl;
        var parameters = qs.stringify(req.query);
        res.redirect('/authorize?' + parameters);

    } else {
        res.status(500);
        res.send("Wrond username or password");
    }
});

```

The authorization endpoint uses the `isLoggedIn` middleware. The endpoint must then respond to the user with a decision form.

You can completely customize this form by giving a template path. The template will be parsed using ejs. By default, the template has access to the following variables:

- `client`: An object representing the client, containing the field **name**,
- `scope`: An array containing the different permissions that the provider requests

You can add custom values to the template as well.

To provider the endpoint with the template and custom data, you need to add a middleware, and override the `req.template` field with the template path, and the `req.data` field with an object containing values that will be usable in the template. Finally, you need to pass the result of `OAuthProvider.OAuth2.getauthorize()`, which finishes the endpoint response:

```javascript
app.get('/authorization', isLoggedIn, function (req, res, next) {
    req.template = Path.join(__dirname + '/path/to/decision.html');
    req.data = {
        user: req.session.user
    };
    next();
}, OAuthProvider.OAuth2.getauthorize());
```

The template should contain a form with a field `decision` valued 0 or 1 according to the user's response, for example:

```html
<!DOCTYPE html>
<html>
    <head><title>Decision page</title></head>
    <body>
        <p>
            Hello, <%= user.username %>!
        </p>
        <p>
            <%= client.name %> requests the following permissions to access your account on [Provider Name]:

            <ul>
                <% for (var k in scope) {%>
                    <li><%= scope[k] %></li>
                <% } %>
            </ul>
        </p>
        <!-- The forms should have no 'action' attribute, as it must call the same endpoint '/authorization' with the same GET parameters-->
        <form method="POST">
            <input type="hidden" name="decision" value="1" />
            <input type="submit" value="Authorize" />
        </form>
        <form method="POST">
            <input type="hidden" name="decision" value="0" />
            <input type="submit" value="Cancel" />
        </form>
    </body>
</html>
```

**POST /authorize**

From here, things are a lot easier. You need to create the `POST /authorize` and the `POST /token` endpoints:

```javascript
app.post('/authorize', OAuthProvider.OAuth2.postauthorize());
app.post('/token', OAuthProvider.OAuth2.token());
```

The `POST /authorize` endpoint catches the response of the user to the decision form, and proxies it to OAuth.io's authentication server. This saves a set containing user's, id, the client and the scope, and associates it with an code. It redirects the user to the client's redirect URL with the code.

The client can then call the `/token` endpoint with the code, the client id and client secret to get the access token server side.

And that's it. Now you can secure your API endpoints, filtering the calls thanks to the scope and user id associated with the access token.

### Securing your API endpoints

Here's how you can secure your API endpoints with this SDK's middleware, `OAuthProvider.OAuth2.check()`:

```javascript

// Using the OAuthProvider.OAuth2.check() middleware, you get
// all the information about the access token that was sent 
// alongside the request
app.get('/someendpoint', OAuthProvider.OAuth2.check({
  scope: ['list', 'of', 'required', 'permissions']
}), function (req, res, next) {
    // if the provided access token does not have all the required permissions
    // a 403 error is sent, otherwise, the endpoint is called
    
    // Here you can get
    // the user id
    var user_id = req.OAuth2.userId;
    // the client id
    var client = req.OAuth2.clientId;
    // the scope
    var scope = req.OAuth2.scope;

    response = {
        key: 'value' 
    };
    
    // if you need to check additional permissions
    // you can use the scope variable:
    if (scope.indexOf('additional_permission') !== -1) {
        // add other information to the response
        response.protectedKey = 'protectedValue';
    }

    // Finally send the response
    res.status(200);
    res.send(response);
});

```

### Managing your clients

The SDK gives you methods that simplify the access to the Client Management API that goes along the OAuth 2.0 server.

This way, you can create your own developer portal, so that developers can register their apps and use your platform.

All the client methods are contained in `OAuthProvider.clients`.

#### Creating a client

To create a client, you need to call the `OAuthProvider.clients.create()` method, with a client's information.

**Required fields**

- `name`: The client's name
- `redirectUri`: The callback URI, on the client's domain, that will intercept the code to later exchange it for an access token

**Optional fields**

- `description`: The client's description

**Example**

```javascript
OAuthProvider.clients.create({
    req.body
})
    .then(function (client) {
        // client created
        // here you'll also have client.client_id and client.client_secret
    })
    .fail(function (error) {
        // an error occured
    });
```


#### Retrieving all clients

To retrieve all your clients, you need to call the `OAuthProvider.clients.getAll()` method.

**Example**

```javascript
OAuthProvider.clients.getAll()
    .then(function (clients){
        // 'clients' contains all your clients
    })
    .fail(function (error) {
        // an error occured
    });
```


#### Retrieving a specific client

To retrieve a specific client, you need to call the `OAuthProvider.clients.get()` method with the client id of the requested client.


**Example**

```javascript
OAuthProvider.clients.get(client_id)
    .then(function (client){
        // Here you'll have all the client's information
        // in the 'client' variable
    })
    .fail(function (error) {
        // an error occured
    });
```


#### Updating a client

To update a client, you need to call the `OAuthProvider.clients.update()` with the client's updated data.

**Required fields**

- `client_id`: The id of the client to update

**Optional fields**

- `name`: the client's name
- `description`: the client's description
- 

**Example**

```javascript
OAuthProvider.clients.update(client)
    .then(function (client) {
        // client was updated
    })
    .fail(function (error) {
        // an error occured
    });
```

#### Resetting a client's keys

To reset a client's keys, you need to call the `OAuthProvider.clients.regenerateKeys()` method with the client's `client_id`.

**Example**

```javascript
OAuthProvider.clients.regenerateKeys(client_id)
    .then(function (client) {
        // client keys were updated
    })
    .fail(function (error) {
        // an error occured
    });
```

#### Deleting a client

To delete a client, you need to call the `OAuthProvider.clients.delete()` method with the client's `client_id`.

**Example**

```javascript
OAuthProvider.clients.delete(client_id)
    .then(function (client) {
        // client keys were updated
    })
    .fail(function (error) {
        // an error occured
    });
```

Contributing
------------

To contribute to this SDK, you can:

- open issues on Github to report bugs and make feature requests
- fork the repository and make pull requests

License
-------

This SDK is published under the Apache 2.0 license.
