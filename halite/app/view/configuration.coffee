mainApp = angular.module("MainApp")

mainApp.controller 'ConfigurationCtrl', [
    '$scope', '$location', '$route','$q', 'Configuration', 'SaltApiSrvc', 'Jobber', 'AppData', 'Itemizer',
        ($scope, $location, $route, $q, Configuration, SaltApiSrvc, Jobber, AppData, Itemizer) ->
            $scope.errorMsg = ""

            if !AppData.get('jobs')?
                AppData.set('jobs', new Itemizer())
            $scope.jobs = AppData.get('jobs')

            $scope.names = ['Foo', 'Bar', 'Spam']
            command =
                fun: 'sys.doc'
                mode: 'async'
                tgt: '*'
                arg: []
                expr_form: 'glob'

            commands = [command]

            $scope.docs_loaded = false

            $scope.isSearchable = () ->
               return $scope.docs_loaded

            $scope.docs = 'Foo'

            $scope.humanize = (cmds) ->
                unless angular.isArray(cmds)
                    cmds = [cmds]
                return (((part for part in [cmd.fun, cmd.tgt].concat(cmd.arg)\
                        when part? and part isnt '').join(' ') for cmd in cmds).join(',').trim())

            $scope.startJob = (result, cmd) ->
                console.log "Start Job #{$scope.humanize(cmd)}"
                console.log result
                jid = result.jid
                job = $scope.snagJob(jid, cmd)
                job.initResults(result.minions)
                return job

            $scope.snagJob = (jid, cmd) -> #get or create a Jobber
                if not $scope.jobs.get(jid)?
                    job = new Jobber(jid, cmd)
                    $scope.jobs.set(jid, job)
                return ($scope.jobs.get(jid))

            console.log SaltApiSrvc

            $scope.job_done = (donejob) ->
                console.log('Job is Done')
            $scope.job_fail = () ->
                console.log('Job has Failed')

            $scope.fetchDocs = () ->
                SaltApiSrvc.run($scope, commands)
                .success (data, status, headers, config) ->
                       console.log('Hello World')
                       console.log(data)
                       $scope.docs_loaded = true
                       result = data.return?[0] #result is a tag
                       if result

                           job = $scope.startJob(result, commands) #runner result is a tag
                           console.log "Job is"
                           console.log job
                           job.commit($q).then($scope.job_done, $scope.job_fail)
                           return true
                .error (data, status, headers, config) ->
                       console.log('In error')
                       return false
                return true
]
