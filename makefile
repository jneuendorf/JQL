FILES = JQL.coffee Schema.coffee Table.coffee OpChainer.coffee Error.coffee linking.coffee

make:
	cat $(FILES) | coffee --compile --stdio > JQL.js

test:
	cat data_example.json $(FILES) Test.coffee | coffee --compile --stdio > JQL.js

production: make
	uglifyjs JQL.js -o JQL.min.js -c -m drop_console=true -d DEBUG=false
