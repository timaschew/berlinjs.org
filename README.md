# BerlinJS - Docpad version
- [x] static site generation with docpad
- [x] deploying into gh-pages branch
- [] provide editable fields 
- [] provide preview
- [] provide pull request functionality

## Dev Setup

Install docpad globally or run via `node_modules/.bin/docpad`

- run `npm install`
- run `docpad run` and open `http://localhost:9778` in your browser
- changes in the **src** will be compiled automatically
- run `docpad deploy-ghpages --env static` to deploy **out** directory to gh-pages branch