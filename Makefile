build:
	$(CURDIR)/node_modules/.bin/coffee -o lib/ -c src/

publish:
	npm publish

release:
	make build
	bumpversion patch
	make publish
