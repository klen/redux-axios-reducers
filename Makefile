$(CURDIR)/node_modules: package.json
	npm install

build: $(CURDIR)/node_modules
	$(CURDIR)/node_modules/.bin/coffee -o lib/ -c src/

publish:
	npm publish

release:
	make build
	bumpversion patch
	make publish
