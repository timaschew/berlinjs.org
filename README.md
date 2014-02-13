# BerlinJS - Docpad version
- [x] static site generation with docpad
- [x] deploying into gh-pages branch
- [x] provide editable fields 
- [x] provide preview
- [x] provide pull request functionality
- [x] provide automatically page generation for future talks
- [] set the order of the talks
- [] choose date when submitting a talk
- [] edit a file / update an existing pull request
- [] unique filenames / merge conflicts if upstream isn't pulled
- [] deploy on heroku
- [] auth via GitHub 
- [] GitHub push trigger 
- [] XHR POST cross domain hack for /submit

## Dev Setup

Install docpad globally or run via `node_modules/.bin/docpad`

### Setup
- fork https://github.com/timaschew/berlinjs.org
- run `git clone https://github.com/USERNAME/berlinjs.org.git`
- create an extra github account for email fallback (you cannot fork twice)
- `cd berlinjs`
- run `echo {} > db.json`
- create **credentials.json** from template and replace `timaschew` with `USERNAME`
- `cp credentials.example.json credentials.json`
- run `npm install`
- run `docpad run` and open `http://localhost:9778` in your browser
- changes in the **src** will be compiled automatically

### Usage
- open `http://localhost:9778/submit.html`
- fill in the form and click on `Submit`
- check mails and click on activation link, wait for pull request url
- accept and merge the pull request
- run `git pull`
- run `docpad deploy-ghpages --env static` to deploy **out** directory to gh-pages branch
