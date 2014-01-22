GitHubApi = require 'github'
{inspect} = require 'util'
{token} = require './token'

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

content = 'This file is edited via Github API'
buffer = new Buffer(content).toString('base64')

github.issues.create
    user: 'berlinjs-bot'
    repo: 'berlinjs-talk-submit'
    title: 'generated via github API - 2'
    body: 'Test 2'
    labels: {}
, (err, res) ->
  console.log JSON.stringify(res)
  return
