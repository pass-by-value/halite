mainApp = angular.module("MainApp")

mainApp.controller 'ConfigurationCtrl', [
            '$scope', '$location', '$route','Configuration', 'SaltApiSrvc',
                ($scope, $location, $route, Configuration, SaltApiSrvc) ->
                                $scope.errorMsg = ""

                                $scope.names = ['Foo', 'Bar', 'Spam']

                                return true
]
