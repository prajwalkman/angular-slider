MODULE        = 'ngSlider'
SLIDER        = 'slider'
SLIDER_BUTTON = 'sliderButton'
BUTTON_EL     = 'slider-button'

sliderDirective = ->
  restrict: 'E'
  template: "<#{SLIDER_BUTTON}></#{SLIDER_BUTTON}>"
  link: (scope, slider, attr) ->
    slider
    .find(SLIDER_BUTTON)
    .attr 'ng-model', attr.ngModel

sliderButtonDirective = ->
  restrict: 'E'
  link: (scope, button, attr) ->
    body = bar = button.parent()
    body = body.parent() until body.tagName is 'BODY'

    model       = attr.ngModel
    minVal      = parseInt bar.attr 'min'
    maxVal      = parseInt bar.attr 'max'
    valRange    = maxVal - minVal
    step        = parseInt bar.attr 'step'
    fallbackVal = parseInt bar.attr 'value-if-null'

    buttonWidth    = button[0].clientWidth
    offsetSubtract = bar[0].offsetLeft# + bar[0].clientLeft
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
      return Math.round val

    fitToStep = (val) ->
      rem = val % step
      newVal = if rem > s/2 then val + (r - s) else val - r
      return newVal

    moveSliderButton = (newXVal) ->
      newXVal = Math.max newXVal, minX
      newXVal = Math.min newXVal, maxX
      button.css left: "#{newXVal}px"
      scope.$apply ->
        scope[model] = fitToStep translateXToVal newXVal

    mouseEventHandler = (mouseEvent) ->
      XVal = mouseEvent.clientX - offsetSubtract
      moveSliderButton XVal

    bar.bind 'click', mouseEventHandler
    bar.bind 'mousedown', ->
      body.bind 'mousemove', mouseEventHandler
      body.bind 'mouseup', ->
        body.unbind 'mousemove mouseup'

    scope.$watch model, (newVal, oldVal) ->
      moveSliderButton translateValToX parseInt newVal

module = (window, angular) ->
  angular
  .module(MODULE, ['ng'])
  .directive(SLIDER, sliderDirective)
  .directive(SLIDER_BUTTON, sliderButtonDirective)

module(window, window.angular)


