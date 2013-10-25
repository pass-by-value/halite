mainApp = angular.module("MainApp")

mainApp.controller 'DocsCtrl', [
    '$scope', '$location', '$route','$q', 'Configuration', 'SaltApiEvtSrvc',
    'SaltApiSrvc', 'SessionStore', 'Jobber', 'Runner', 'Commander', 'Minioner',
    'AppData', 'Itemizer',
        ($scope, $location, $route, $q, Configuration, SaltApiEvtSrvc,
        SaltApiSrvc, SessionStore, Jobber, Runner, Commander,
        Minioner, AppData, Itemizer) ->
            $scope.errorMsg = ""

            if !AppData.get('jobs')?
                AppData.set('jobs', new Itemizer())
            $scope.jobs = AppData.get('jobs')

            if !AppData.get('events')?
                AppData.set('events', new Itemizer())
            $scope.events = AppData.get('events')

            if !AppData.get('commands')?
                AppData.set('commands', new Itemizer())
            $scope.commands = AppData.get('commands')

            if !AppData.get('minions')?
                AppData.set('minions', new Itemizer())
            $scope.minions = AppData.get('minions')

            command =
                fun: 'sys.doc'
                mode: 'async'
                tgt: '*'
                arg: []
                expr_form: 'glob'

            commands = [command]

            $scope.docs_loaded = false

            $scope.searchDocs = () ->
                matching = _.filter($scope.keys, (key) ->
                    return key.indexOf($scope.search_str.toLowerCase()) != -1)
                matching_docs = ($scope.docs[key] for key in matching)
                $scope.to_render = matching_docs.join('')
                return true

            $scope.isSearchable = () ->
               return $scope.docs_loaded

            $scope.humanize = (cmds) ->
                unless angular.isArray(cmds)
                    cmds = [cmds]
                return (((part for part in [cmd.fun, cmd.tgt].concat(cmd.arg)\
                        when part? and part isnt '').join(' ') for cmd in cmds).join(',').trim())

            $scope.startRun = (tag, cmd) ->
                #console.log "Start Run #{$scope.humanize(cmd)}"
                #console.log tag
                parts = tag.split("/")
                jid = parts[2]
                job = $scope.snagRunner(jid, cmd)
                return job

            $scope.snagRunner = (jid, cmd) -> #get or create Runner
                if not $scope.jobs.get(jid)?
                    job = new Runner(jid, cmd)
                    $scope.jobs.set(jid, job)
                return ($scope.jobs.get(jid))

            $scope.startJob = (result, cmd) ->
                #console.log "Start Job #{$scope.humanize(cmd)}"
                jid = result.jid
                job = $scope.snagJob(jid, cmd)
                job.initResults(result.minions)
                return job

            $scope.snagJob = (jid, cmd) -> #get or create a Jobber
                if not $scope.jobs.get(jid)?
                    job = new Jobber(jid, cmd)
                    $scope.jobs.set(jid, job)
                return ($scope.jobs.get(jid))

            $scope.job_done = (donejob, a, b) ->
                results = donejob.results
                minions = results._data
                minion_with_result = _.find(minions, (minion) ->
                    minion.val.retcode == 0)
                if minion_with_result?
                    $scope.docs = minion_with_result.val.return
                    $scope.keys = for key, value of $scope.docs
                        "#{key.toLowerCase()}"
                    $scope.docs_loaded = true
                else
                    $scope.errorMsg = 'All Minions Returned Invalid Data. Please check Minions and retry.'
                return

            $scope.job_fail = () ->
                $scope.errorMsg = 'Job Failed. Please check system and retry.'

            $scope.fetchDocs = () ->
                if SessionStore.get('loggedIn')? == false
                    $scope.errorMsg = 'Please Log In'
                    return false

                command = $scope.snagCommand($scope.humanize(commands), commands)

                SaltApiSrvc.run($scope, commands)
                .success (data, status, headers, config) ->
                       result = data.return?[0] #result is a tag
                       if result

                           job = $scope.startJob(result, commands) #runner result is a tag
                           job.commit($q).then($scope.job_done, $scope.job_fail)
                           return true
                .error (data, status, headers, config) ->
                       return false
                return true

            $scope.snagMinion = (mid) -> # get or create Minion
                if not $scope.minions.get(mid)?
                    $scope.minions.set(mid, new Minioner(mid))
                return ($scope.minions.get(mid))

            $scope.processJobEvent = (jid, kind, edata) ->
                job = $scope.jobs.get(jid)
                job.processEvent(edata)
                data = edata.data
                if kind == 'new'
                    job.processNewEvent(data)
                else if kind == 'ret'
                    minion = $scope.snagMinion(data.id)
                    minion.activize() #since we got a return then minion must be active
                    job.linkMinion(minion)
                    job.processRetEvent(data)
                    job.checkDone()
                return job

            $scope.processSaltEvent = (edata) ->
                #console.log edata
                if not edata.data._stamp?
                    edata.data._stamp = $scope.stamp()
                edata.utag = [edata.tag, edata.data._stamp].join("/")
                $scope.events.set(edata.utag, edata)
                parts = edata.tag.split("/") # split on "/" character
                if parts[0] is 'salt'
                    if parts[1] is 'job'
                        jid = parts[2]
                        if jid != edata.data.jid
                            console.log "Bad job event"
                            $scope.errorMsg = "Bad job event: JID #{jid} not match #{edata.data.jid}"
                            return false
                        $scope.snagJob(jid, edata.data)
                        kind = parts[3]
                        $scope.processJobEvent(jid, kind, edata)

                    else if parts[1] is 'run'
                        jid = parts[2]
                        if jid != edata.data.jid
                            console.log "Bad run event"
                            $scope.errorMsg = "Bad run event: JID #{jid} not match #{edata.data.jid}"
                            return false
                        $scope.snagRunner(jid, edata.data)
                        kind = parts[3]
                        $scope.processRunEvent(jid, kind, edata)

                    else if parts[1] is 'wheel'
                        jid = parts[2]
                        if jid != edata.data.jid
                            console.log "Bad wheel event"
                            $scope.errorMsg = "Bad wheel event: JID #{jid} not match #{edata.data.jid}"
                            return false
                        $scope.snagWheel(jid, edata.data)
                        kind = parts[3]
                        $scope.processWheelEvent(jid, kind, edata)

                    else if parts[1] is 'minion' or parts[1] is 'syndic'
                        mid = parts[2]
                        if mid != edata.data.id
                            console.log "Bad minion event"
                            $scope.errorMsg = "Bad minion event: MID #{mid} not match #{edata.data.id}"
                            return false
                        $scope.processMinionEvent(mid, edata)

                    else if parts[1] is 'key'
                        $scope.processKeyEvent(edata)

                return edata

            $scope.openEventStream = () ->
                $scope.eventing = true
                $scope.eventPromise = SaltApiEvtSrvc.events($scope,
                    $scope.processSaltEvent, "salt/")
                .then (data) ->
                    $scope.$emit('Activate')
                    $scope.eventing = false
                , (data) ->
                    console.log "Error Opening Event Stream"
                    if SessionStore.get('loggedIn') == false
                        $scope.errorMsg = "Cannot open event stream! Must login first!"
                    else
                        $scope.errorMsg = "Cannot open event stream!"
                    $scope.eventing = false
                    return data
                return true

            $scope.closeEventStream = () ->
                #console.log "Closing Event Stream"
                SaltApiEvtSrvc.close()
                return true

            $scope.snagCommand = (name, cmds) -> #get or create Command
                unless $scope.commands.get(name)?
                    $scope.commands.set(name, new Commander(name, cmds))
                return ($scope.commands.get(name))

            $scope.clearSaltData = () ->
                AppData.set('commands', new Itemizer())
                $scope.commands = AppData.get('commands')
                AppData.set('jobs', new Itemizer())
                $scope.jobs = AppData.get('jobs')
                AppData.set('minions', new Itemizer())
                $scope.minions = AppData.get('minions')
                AppData.set('events', new Itemizer())
                $scope.events = AppData.get('events')

            $scope.processKeyEvent = (edata) ->
                data = edata.data
                mid = data.id
                minion = $scope.snagMinion(mid)
                if data.result is true
                    if data.act is 'delete'
                        minion.unlinkJobs()
                        $scope.minions.del(mid)
                    return minion

            $scope.authListener = (event, loggedIn) ->
                if loggedIn
                    $scope.openEventStream()
                else
                    $scope.closeEventStream()
                    $scope.clearSaltData()
                return true

            $scope.$on('ToggleAuth', $scope.authListener)

            if not SaltApiEvtSrvc.active and SessionStore.get('loggedIn') == true
                $scope.openEventStream()

            $scope.fetchDocs()

    ]

