async = require 'async'
uuid = require 'uuid'
nodemailer = require 'nodemailer'

GitHubApi = require 'github'

fs = require 'fs'
{inspect} = require 'util'
{mail} = require './credentials'

dbName = './db.json'

docpadURL = require('./credentials').docpadAppUrl

mergePath = 'src/documents/talks/'

# github account for the email fallback
botUser = require('./credentials').emailFallback.user
botRepo = require('./credentials').emailFallback.repo
botToken = require('./credentials').emailFallback.token

# github account for the remote origin (berlinjs in production)
berlinJsUser = require('./credentials').production.user
berlinJsRepo = require('./credentials').production.repo
pullRequestBase = require('./credentials').production.pullRequestBase

github = new GitHubApi(
  # required
  version: "3.0.0"
  # optional
  debug: true
  protocol: "https"
  timeout: 5000
)

# create reusable transport method (opens pool of SMTP connections)
smtpTransport = nodemailer.createTransport("SMTP",
  host: mail.host
  secureConnection: mail.secureConnection
  port: mail.port
  auth:
    user: mail.user
    pass: mail.pass
)

getDatabase = -> 
    JSON.parse fs.readFileSync dbName, 'utf8'

saveDatabase = (dbToSave) ->
    serialized = JSON.stringify dbToSave, null, '  '
    fs.writeFileSync dbName, serialized, 'utf8'

auth = ->
    github.authenticate
        type: 'oauth'
        token: botToken

submitTalk = (email, date, title, name, nameLink, description, cb) ->
    entry = 
        title: title
        date: date
        name: name
        nameLink: nameLink
        description: description

    console.log 'saving into db ...'
    console.log entry
    try
        token = save entry # catch here
        sendMail email, token, cb
    catch error
        console.log 'error while save and send mail'
        console.log err
        cb error

save = (object) ->

    # read db
    db = getDatabase()

    id = uuid.v4()
    db[id] = object
    saveDatabase(db)
    
    # check if write was successfull
    db = getDatabase()
    unless db[id]?
        throw new Error "#{id} could not saved into db: #{dbName}"

    return id

sendMail = (email, token, cb) ->
    # send mail with token as link
    link = "#{docpadURL}/confirm/#{token}"
    mailOptions =
        from: mail.sender
        to: email 
        subject: "Your Confirmation Link" 
        text: "Hi, please confirm your token #{token} on this site: #{link}"
        html: "Hi, please confirm your token on this site <strong><a href='#{link}'>#{token}</a></strong>"
    
    # send mail with defined transport object
    smtpTransport.sendMail mailOptions, (error, response) ->
        smtpTransport.close()
        if err?
            console.error err.message
            return cb err
        else
            console.log 'Message sent: '
            console.log response
            cb()


workflow = (token, cb) ->

    auth()
    entry = null
    docpadMarkDownDocument = null

    async.waterfall [
        (cb) ->
            # check token
            console.log "check token: #{token}"

            db = getDatabase()
            result = db[token]
            cb null, result

        (dbEntry, cb) ->
            unless dbEntry?
                return cb new Error "no entry found for this token: #{token}"
            entry = dbEntry

            docpadMarkDownDocument = """
            # #{entry.title}

            ## [#{entry.name}](#{entry.nameLink})

            #{entry.description}
            """
            cb()
        
        (cb) ->
            console.log 'forking ...'
            createFork cb

        (res, cb) ->
            if res.meta.status isnt '202 Accepted'
                return cb new Error 'could not fork'

            # set name of repo, if it already exist under another name
            botRepo = res.name

            # github forking asynchronously without callback
            # so let's check it
            console.log 'check repo existence ...'

            checkInteval = 500 #ms
            timeout = 10000 / checkInteval
            repoNotReady = true
            async.whilst ->
              repoNotReady
            , (callback) ->
              doesRepoExist botUser, botRepo, (err, res) ->
                if err?
                  if err.code is 404
                    # not ready yet
                    if timeout <= 0
                        return callback new Error "repo not found: #{botUser}/#{botRepo}"
                    timeout--
                    return setTimeout callback, checkInteval
                  # other error
                  return callback err

                else if res.meta?.status is '200 OK'
                  repoNotReady = false
                callback()
            , cb

        (cb) ->
            # TODO: can a branch have a newer sha than initial own fork?
            # get latest commit and extract latest sha (from original repo) for new branch
            getCommits botUser, botRepo, cb

        (commits, cb) ->
            console.log 'create branch ...'
            latestCommitSha = commits[0].sha

            # create branch
            # create unique branch name
            branchName = "#{entry.date}_#{entry.title}"
            # replace special characters:
            branchName = branchName.replace(/[^\w]/gi, '-')

            createBranch branchName, latestCommitSha, (err, res) ->
                # check if it was created or already exist (422)
                if res?.meta?.status is '201 Created' or err.code is 422
                    return cb null, branchName

                console.log 'unexpected error'
                return cb err

        (branchName, cb) ->
            console.log 'create file ...'
            # create fie
            path = "#{mergePath}#{branchName}.html.md"
            commitMessage = branchName
            content = docpadMarkDownDocument

            createFile path, branchName, commitMessage, content, (err, res) ->
                if err?.code is 422
                    message = "ERROR: the file already exist: #{path}, use update!"
                    console.log message
                    return cb new Error message

                cb err, res, branchName

        (res, branchName, cb) ->
            console.log 'create pull request ...'
            # send pull request

            title = branchName
            body = """
            Rendered markdown content of the talk
            - - -
            #{docpadMarkDownDocument}
            """

            createPullRequest title, body, branchName, cb

    ], (err, pullrequest) ->
        if err?
            if entry?
                try
                    console.log "save errror to db"
                    db = getDatabase()
                    db[token].error = err.message
                    saveDatabase(db)
                catch error
                    console.log error

            return cb(err)

        console.log 'delete token from db'
        db = getDatabase()
        delete db[token]
        saveDatabase(db)
        cb(null, pullrequest)

createFork = (cb) ->
    # POST /repos/:owner/:repo/forks
    github.repos.fork
        user: berlinJsUser
        repo: berlinJsRepo

    , cb

doesRepoExist = (user, repo, cb) ->
    github.repos.get
        user: user
        repo: repo
    , cb

getCommits = (user, repo, cb) ->
    github.repos.getCommits
        user: user
        repo: repo
    , cb


createBranch = (branchName, sha, cb) ->
    # /repos/:user/:repo/git/refs
    github.gitdata.createReference
        user: botUser
        repo: botRepo
        ref: "refs/heads/#{branchName}"
        sha: sha
    , cb


createFile = (path, branch, message, content, cb) ->
    base64 = new Buffer(content).toString('base64')

    # /repos/:user/:repo/contents/:path
    github.repos.createFile
        user: botUser
        repo: botRepo
        path: path
        branch: branch
        message: message
        content: base64
    , cb

createPullRequest = (title, body, branchName, cb) ->
  github.pullRequests.create
    user: berlinJsUser
    repo: berlinJsRepo
    title: title
    body: body
    head: "#{botUser}:#{branchName}"
    base: pullRequestBase
  , cb


logErrorAndResult = (err, res) ->
    if err?
        console.error 'error'
        console.log err.message
        console.log 'JSON object:'
        console.log JSON.stringify(err)
    else
        console.log res
        console.log 'JSON object:'
        console.log JSON.stringify(res)

logErrorAndMeta = (err, res) ->
    if err?
        console.error 'error'
        console.log err.message
        console.log 'JSON object:'
        console.log JSON.stringify(err)
    else
        console.log res.meta if res.meta?

###
# TESTING
###
if require.main is module
    console.log 'mode: standalone'
    params = process.argv.slice 2

    if params[0] is 'send-mail'
        console.log "send mail to #{params[1]} with token: #{params[2]}"
        sendMail params[1], params[2], (err) ->
            if err?
                process.exit 1

    else if params[0] is 'submit-talk'
        console.log 'submit-talk ...'
        submitTalk('timaschew@gmail.com', '2014-01-02', 'Talk title', 'Anton', 'https://twitter.com/timaschew', 'foobar')

    else if params[0] is 'fork-branch'
        workflow params[1]

    else if params[0] is 'check'
        console.log 'check token'
        db.get params[1], (err, res) ->
            if err?
                console.log err
            else
                console.log res

    else if params[0] is 'pull-request'
        console.log 'pull-request'

    else
        console.log 'no option was choosen'

else 
    module.exports = 
        submitAndSendMail: submitTalk
        sendPullRequest: workflow
        getDatabase: getDatabase
