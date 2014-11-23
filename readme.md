
Setup
-----

	Install redis

	$ npm install [-g] grunt-cli
	$ npm install


Build
-----

	$ grunt build


Deploy
------

	$ npm install -g forever
	$ forever -c coffee app/server.coffee


TODO
----

* Persist games (they should survive server restart)
* Limit username length (DoS with 1 MB long usernames would soon deplete server memory)
