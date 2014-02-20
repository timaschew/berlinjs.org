github = require './github'
websiteURL = require('./credentials').production.website
submitURL = require('./credentials').docpadAppUrl + '/submit.html'

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

        'nextMeetup': (database) ->
            cfg = docpad.getConfig()
            nextTalkDate = cfg.templateData.getDateForNextTalk()
            opts = relativeOutPath: $startsWith: "talks/#{nextTalkDate.date}"
            @getDatabase().findAllLive(opts)

    # Template Data
    # Use to define your own template data and helpers that will be accessible to your templates
    # Complete listing of default values can be found here: http://docpad.org/docs/template-data
    templateData:  # example

        getDateForNextTalk: ->
            now = new Date().getTime()
            for item in @schedules
              talkDate = new Date(item.date).getTime();
              # add one day buffer
              talkDate += 1000*60*60*24 # 24 hours
              if talkDate >= now
                return item

        schedules: [
                date: '2014-01-16'
                text: 'January 16th'
            ,
                date: '2014-02-20'
                text: 'February 20th'
            ,
                date: '2014-03-20'
                text: 'March 20th'
            ,
                date: '2014-04-15'
                text: 'April 20th'
        ]

        # Specify some site properties
        site:
            # available slots
            slots: 4

            # url to the submit page with the XHR to this app
            submitUrl: submitURL

            # The production url of our website
            url: websiteURL

            # The default title of our website
            title: "BerlinJS — Berlin's finest JavaScript Usergroup"

            # The website description (for SEO)
            description: """
                Berlin.JS is a usergroup focused on JavaScript and related topics. 
                We meet regularly on the 3rd Thursday each month at 7p.m. 
                at co.up Offices, Adalbertstraße 7-8 in Berlin-Kreuzberg.
                """

            # The website keywords (for SEO) separated by commas
            keywords: """
                JavaScript, Usergroup, Berlin, Programming, JS
                """

            headerDescription: """
                Berlin.JS is a usergroup focused on JavaScript and related topics. 
                We meet regularly on the 3rd Thursday each month at 7p.m. at 
                <a href='http://co-up.de' title='co.up Coworking'>co.up Offices</a>, 
                Adalbertstraße 7-8 in Berlin-Kreuzberg.
                """


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

            express.get '/check/:token', (req, res) ->
                token = req.param 'token'

                result = github.getDatabase()[token]
                console.log result
                res.json result
                res.end()

            express.get '/confirm/:token', (req, res) ->
                token = req.param 'token'

                github.sendPullRequest token, (err, pullRequestResult) ->
                    console.log 'return from sendPullRequest cb'
                    if err?
                        res.send err.message
                    else
                        url = pullRequestResult.html_url
                        res.send """<p>pull request created</p>
                            <p><a href='#{url}'>see your pull request here</a></p>
                            """
                    res.end()

            express.post '/submit', (req, res) ->
                {email, date, title, name, nameLink, description} = req.body.s
                github.submitAndSendMail email, date, title, name, nameLink, description, (err) ->
                    if err?
                        res.send 500, err.message
                    else
                        res.send 201, 'Check your mails!'
                    res.end()
