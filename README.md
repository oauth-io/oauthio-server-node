OAuth.io Providing SDK
======================

This SDK allows you to use the OAuth 2.0 providing features of OAuth.io.

OAuth 2.0 allows you to add an authentication layer to your API, according the the [RFC 6749](https://tools.ietf.org/html/rfc6749).

Pre-requisite
-------------

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
$ node install oauthio-provider
```


Using for the OAuth 2.0 dance
-----------------------------


