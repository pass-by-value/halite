mainApp = angular.module("MainApp")

mainApp.controller 'ConfigurationCtrl', [
    '$scope', '$location', '$route','Configuration', 'SaltApiSrvc',
        ($scope, $location, $route, Configuration, SaltApiSrvc) ->
            $scope.errorMsg = ""

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

            
            console.log SaltApiSrvc
            SaltApiSrvc.run($scope, commands)
            .success (data, status, headers, config) ->
                   console.log('Hello World')
                   console.log(data)
                   $scope.docs_loaded = true
                   result = data.return?[0] #result is a tag
                   if result

                       job = $scope.startJob(result, commands) #runner result is a tag
                       job.commit($q).then (donejob) ->
                           console.log 'Done Job is'
                           console.log donejob
                   return true
            .error (data, status, headers, config) ->
                   return false
]
