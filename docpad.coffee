module.exports = 

    # Out Path
    # Where should we put our generated website files?
    # If it is a relative path, it will have the resolved `rootPath` prepended to it
    outPath: 'out'  # default

    # Src Path
    # Where can we find our source website files?
    # If it is a relative path, it will have the resolved `rootPath` prepended to it
    srcPath: 'src'  # default

    # Documents Paths
    # An array of paths which contents will be treated as documents
    # If it is a relative path, it will have the resolved `srcPath` prepended to it
    documentsPaths: [  # default
        'documents'
    ]

    # Files Paths
    # An array of paths which contents will be treated as files
    # If it is a relative path, it will have the resolved `srcPath` prepended to it
    filesPaths: [  # default
        'static'
    ]

    # Layouts Paths
    # An array of paths which contents will be treated as layouts
    # If it is a relative path, it will have the resolved `srcPath` prepended to it
    layoutsPaths: [  # default
        'layouts'
    ]

    collections:
        '2013-11-21': (database) ->
            database.findAllLive({relativeOutPath: $startsWith: 'talks/2013-11'})

    # Template Data
    # Use to define your own template data and helpers that will be accessible to your templates
    # Complete listing of default values can be found here: http://docpad.org/docs/template-data
    templateData:  # example

        # Specify some site properties
        site:

            # The production url of our website
            url: "http://timaschew.github.io/berlinjs.org" 

            # The default title of our website
            title: "Berlin.JS"

            # The website description (for SEO)
            description: """
                When your website appears in search results in say Google, the text here will be shown underneath your website's title.
                """

            # The website keywords (for SEO) separated by commas
            keywords: """
                place, your, website, keywoards, here, keep, them, related, to, the, content, of, your, website
                """

        schedules: [
                date: '2013-11-21'
                text: 'November 21th'
            ,
                date: '2013-12-19'
                text: 'December 19th'
            ,
                date: '2014-01-16'
                text: 'January 16th'
            ,
                date: '2014-02-20'
                text: 'February 20th'
            ,
                date: '2014-03-20'
                text: 'March 1st'
        ]
        

        getTalksForNextMetup: ->
            nextTalkDate = @getDateForNextTalk()
            opts = 
                relativeOutPath: $startsWith: "talks/#{nextTalkDate.date}"
            console.log opts
            @getDatabase().findAllLive(opts).toJSON()

        getDateForNextTalk: ->
            now = new Date().getTime()
            for item in @schedules
              talkDate = new Date(item.date).getTime();
              # add some (timezone) buffer 
              talkDate -= 1000*60*60*24 # 24 hours
              if talkDate >= now
                console.log "return item: #{JSON.stringify(item)}"
                return item

    enabledPlugins:  
        basicauth: false

    plugins:
        ghpages:
            deployRemote: 'origin'
            deployBranch: 'gh-pages'


    # =================================
    # DocPad Events

    # Here we can define handlers for events that DocPad fires
    # You can find a full listing of events on the DocPad Wiki
    events:

        # Server Extend
        # Used to add our own custom routes to the server before the docpad routes are added
        serverExtend: (opts) ->
            # Extract the server from the options
            {express, server} = opts
            docpad = @docpad

            express.get '/test', (req, res) ->
                res.end 'hello world'

            try
                github = require './out/github'
                # Redirect any requests accessing one of our sites oldUrls to the new site url

                express.get '/check/:token', (req, res) ->
                    token = req.param 'token'
                    console.log typeof token
                    console.log "extract token: '#{token}' from url"

                    db = require './db.json'
                    result = db[token]
                    console.log result
                    res.json result
                    res.end()

                express.get '/confirm/:token', (req, res) ->
                    token = req.param 'token'
                    console.log "extract token: #{token} from url"

                    db = require './db.json'
                    result = db[token]
                    unless result?
                        return res.send "token not found: #{token}"
                        
                    token = result

                    github.sendPullRequest token, (err, pullRequestResult) ->
                        if err?
                            res.send err.message
                        else
                            url = pullRequestResult.html_url
                            res.send """<p>pull request created</p>
                                <p><a href='#{url}'>see pull request</a></p>
                                """

                        res.end()

                express.post '/submit', (req, res) ->
                    console.log req.body.s
                    {email, date, title, name, nameLink, description} = req.body.s
                    github.submitAndSendMail email, date, title, name, nameLink, description, (err) ->
                        if err?
                            res.send err.message
                        else
                            res.send 'Check your mails!'
                        res.end()
                
            catch err
                console.error err.message
            
