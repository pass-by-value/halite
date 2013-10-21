# Service to provide global configuration meta data for application 
#  Can also used to avoid circular dependencies

# inject these from config.json

configuration =
    baseUrl: ""
    date: "20130709"
    version: "0.0.1"
    views:
        home: 
            label: "home"
            route: "/app/home"
            url: "/app/home/"
            template: "/static/app/view/home.html"
            controller: "HomeCtlr"
        otherwise: 
            label: "console"
            route: "/app/console"
            url: "/app/console/"
            template: "/static/app/view/console.html"
            controller: "ConsoleCtlr"
        tabs:
            [
                label: "console"
                route: "/app/console"
                url: "/app/console/"
                template: "/static/app/view/console.html"
                controller: "ConsoleCtlr"
            ,
                label: "project"
                route: "/app/project"
                url: "/app/project/"
                template: "/static/app/view/project.html"
                controller: "ProjectCtlr"
            ,
                label: "configuration"
                route: "/app/configuration"
                url: "/app/configuration/"
                template: "/static/app/view/configuration.html"
                controller: "ConfigurationCtrl"

            ]
    preferences:
        debug: false
        verbose: false
        saltApi:
            scheme: ""
            host: ""
            port: 0
            prefix: ""
            eauth: "pam"
            

prefixify = (views, base) ->
    for name, item of views
        if item.label? # item is a view
            item.route = base + item.route
            item.url = base + item.url
            item.template = base + item.template
        else # item is a list of views
            for view in item
                view.route = base + view.route
                view.url = base + view.url
                view.template = base + view.template
    return views

buildMatcher = (route) ->
    chunks = route.split("/")
    for chunk, i in chunks
        if chunk.match("^:\\w+$")?
            chunks[i] = "\\w*"
    matcher = "^" + chunks.join("/") + "$"
    return matcher

matcherify = (views) ->
    for name, item of views
        if item.label? # item is a view
            item.matcher = buildMatcher(item.route)
        else # item is a list of views
            for view in item
                view.matcher = buildMatcher(view.route)
    return views

configuration.views = prefixify(configuration.views, configuration.baseUrl)
configuration.views = matcherify(configuration.views)

appConfigSrvc = angular.module( "appConfigSrvc",[])

appConfigSrvc.constant 'Configuration', configuration



