MODULE        = 'ngSlider'
SLIDER        = 'slider'
SLIDER_BUTTON = 'sliderButton'
BUTTON_EL     = 'slider-button'

sliderDirective = ->
  restrict: 'E'
  scope:
    value: '='
  template: "<#{BUTTON_EL} ng-model=\"value\"></#{BUTTON_EL}>"
  link: (scope, slider, attr) ->

sliderButtonDirective = ->
  restrict: 'E'
  link: (scope, button, attr) ->
    body = bar = button.parent()
    body = body.parent() until body[0].tagName is 'BODY'

    minVal      = parseInt bar.attr 'min'
    maxVal      = parseInt bar.attr 'max'
    valRange    = maxVal - minVal
    step        = parseInt bar.attr 'step'
    fallbackVal = parseInt bar.attr 'value-if-null'

    buttonWidth    = button[0].clientWidth
    offsetSubtract = bar[0].offsetLeft
    minX           = 0
    maxX           = bar[0].clientWidth - button[0].clientWidth
    XRange         = maxX - minX

    translateValToX = (val) ->
      normVal = (val - minVal)/valRange
      XVal = normVal * XRange
      return XVal

    translateXToVal = (XVal) ->
      normX = (XVal - minX)/XRange
      val = normX * valRange
      return Math.round val + minVal

    fitToStep = (val) ->
      rem = val % step
      newVal = if rem > step/2 then val + (step - rem) else val - rem
      return newVal

    setValue = (value) ->
      scope.$apply ->
        scope.value = value

    moveSliderButton = (newXVal) ->
      newXVal = Math.max newXVal, minX
      newXVal = Math.min newXVal, maxX
      button.css left: "#{newXVal}px"
      newVal = fitToStep translateXToVal newXVal
      return newVal

    mouseEventHandler = (mouseEvent) ->
      XVal = mouseEvent.clientX - offsetSubtract
      newVal = moveSliderButton XVal
      setValue newVal

    scope.value = moveSliderButton translateValToX scope.value

    bar.bind 'click', mouseEventHandler
    bar.bind 'mousedown', ->
      body.bind 'mousemove', mouseEventHandler
      body.bind 'mouseup', ->
        body.unbind 'mousemove'
        body.unbind 'mouseup'

module = (window, angular) ->
  angular
  .module(MODULE, ['ng'])
  .directive(SLIDER, sliderDirective)
  .directive(SLIDER_BUTTON, sliderButtonDirective)

module(window, window.angular)

### 
app = angular.module 'app', [MODULE]

app.controller 'Ctrl', ($scope) ->
  $scope.name = 'world'
  $scope.cost = 49

angular.bootstrap document, ['app']

###