GitHubApi = require 'github'
{inspect} = require 'util'
{token} = require './token'

user = 'berlinjs-bot'
repo = 'berlinjs-talk-submit'

github = new GitHubApi(
  # required
  version: "3.0.0"
  # optional
  debug: true
  protocol: "https"
  timeout: 5000
)

console.log 'auth ...'

retVal = github.authenticate
    type: 'oauth'
    token: token

# create and update files are not implemented in this github API lib
# http://developer.github.com/v3/repos/contents/#create-a-file
content = 'This file is created via Github API'
base64 = new Buffer(content).toString('base64')

# /repos/:user/:repo/contents/:path
github.repos.createFile
    user: user
    repo: repo
    path: 'testFile2.md'
    branch: 'master'
    message: 'created another file'
    content: base64
, (err, res) ->
  console.log JSON.stringify(res)
  return

# github.issues.create
#     user: user
#     repo: repo
#     title: 'generated via github API - 2'
#     body: 'Test 2'
#     labels: {}
# , (err, res) ->
#   console.log JSON.stringify(res)
#   return
