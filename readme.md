
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
	$ forever -c coffee [start|stop|restart] app/server.coffee


TODO
----

* Persist games (they should survive server restart)
