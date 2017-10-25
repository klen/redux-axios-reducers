const fs = require('fs')
const path = require('path')
const reporter = require('nodeunit').reporters.default;
const CoffeeScript = require('coffeescript')

CoffeeScript.register()

var targets = process.argv.slice[2]

if (!targets || targets.length)
  targets = fs.readdirSync(path.resolve(__dirname)).map(
      (file) => path.join(__dirname, file)
  )

reporter.run(targets);
