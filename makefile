make:
	cat JQL.coffee Schema.coffee Table.coffee linking.coffee | coffee --compile --stdio > JQL.js

test:
	cat data_example.json JQL.coffee Schema.coffee Table.coffee linking.coffee Test.coffee | coffee --compile --stdio > JQL.js

production: make
	uglifyjs JQL.js -o JQL.min.js -c drop_console=true -d DEBUG=false
