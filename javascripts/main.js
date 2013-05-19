// console.log(window.angular);

app = angular.module('app', ['uiSlider']);

app.controller('ItemCtrl', ['$scope', function($scope){
  $scope.item = {
    name: 'Potato',
    cost: 350
  };
  $scope.currencyFormatting = function(value) { return value.toString() + " $"; };
}]);

app.controller('PositionCtrl', ['$scope', function($scope){
  $scope.position = {
    name: 'Potato Master',
    minAge: 25,
    maxAge: 40
  };
}]);