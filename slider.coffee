# CONSTANTS

MODULE_NAME = 'ui.slider'
SLIDER_TAG  = 'slider'

# HELPER FUNCTIONS

angularize    = (element) -> angular.element element
pixelize      = (position) -> "#{position}px"
hide          = (element) -> element.css opacity: 0
show          = (element) -> element.css opacity: 1
offset        = (element, position) -> element.css left: position
halfWidth     = (element) -> element[0].offsetWidth / 2
offsetLeft    = (element) -> element[0].offsetLeft
width         = (element) -> element[0].offsetWidth
gap           = (element1, element2) -> offsetLeft(element2) - offsetLeft(element1) - width(element1)
roundStep     = (value, precision, step, floor = 0) ->
  step ?= 1 / Math.pow(10, precision)
  remainder = (value - floor) % step
  steppedValue =
    if remainder > (step / 2)
    then value + step - remainder
    else value - remainder
  decimals = Math.pow 10, precision
  roundedValue = steppedValue * decimals / decimals
  parseFloat(roundedValue.toFixed precision)
inputEvents =
  mouse:
    start: 'mousedown'
    move:  'mousemove'
    end:   'mouseup'
  touch:
    start: 'touchstart'
    move:  'touchmove'
    end:   'touchend'

# DIRECTIVE DEFINITION

sliderDirective = ($timeout) ->
  restrict: 'E'
  scope:
    floor:        '@'
    ceiling:      '@'
    values:       '=?'
    range:        '@'
    step:         '@'
    highlight:    '@'
    precision:    '@'
    buffer:       '@'
    ngModel:      '=?'
    ngModelLow:   '=?'
    ngModelHigh:  '=?'
  template: '''
    <div class="bar"><div class="selection"></div></div>
    <div class="handle low"></div><div class="handle high"></div>
    <div class="bubble limit low">{{ values.length ? ( values[floor || 0] || floor ) : floor }}</div>
    <div class="bubble limit high">{{ values.length ? ( values[ceiling || values.length - 1] || ceiling ) : ceiling }}</div>
    <div class="bubble value low">{{ values.length ? ( values[ngModelLow] || ngModelLow ) : ngModelLow }}</div>
    <div class="bubble value high">{{ values.length ? ( values[ngModelHigh] || ngModelHigh ) : ngModelHigh }}</div>'''
  compile: (element, attributes) ->

    # Check if it is a range slider
    range = !attributes.ngModel? and attributes.ngModelLow? and attributes.ngModelHigh?

    # Get references to template elements
    [bar, minPtr, maxPtr,
      flrBub, ceilBub, lowBub, highBub] = (angularize(e) for e in element.children())

    selection = angularize bar.children()[0]

    # Remove range specific elements if not a range slider
    unless range
      element.remove() for element in [maxPtr, highBub]
      selection.remove() unless attributes.highlight

    # Scope values to watch for changes
    watchables = ['floor', 'ceiling', 'values', 'ngModelLow']
    watchables.push 'ngModelHigh' if range

    post: (scope, element, attributes) ->

      boundToInputs = false
      ngDocument = angularize document
      handleHalfWidth = barWidth = minOffset = maxOffset = minValue = maxValue = valueRange = offsetRange = undefined

      dimensions = ->
        # roundStep the initial score values
        scope.step ?= 1
        scope.floor ?= 0
        scope.precision ?= 0
        scope.ceiling ?= scope.values.length - 1 if scope.values?.length
        scope.ngModelLow ?= scope.ngModel unless range

        for value in watchables
          scope[value] = roundStep(parseFloat(scope[value]),
            parseInt(scope.precision), parseFloat(scope.step),
            parseFloat(scope.floor)) if typeof value is 'number'

        # Commonly used measurements
        handleHalfWidth = halfWidth minPtr
        barWidth = width bar

        minOffset = 0
        maxOffset = barWidth - width(minPtr)

        minValue = parseFloat scope.floor
        maxValue = parseFloat scope.ceiling

        valueRange = maxValue - minValue
        offsetRange = maxOffset - minOffset

      updateDOM = ->
        dimensions()

        # Translation functions
        percentOffset = (offset) -> ((offset - minOffset) / offsetRange) * 100
        percentValue = (value) -> ((value - minValue) / valueRange) * 100
        percentToOffset = (percent) -> pixelize percent * offsetRange / 100

        # Fit bubble to bar width
        fitToBar = (element) -> offset element, pixelize(Math.min (Math.max 0, offsetLeft(element)), (barWidth - width(element)))

        setPointers = ->
          offset ceilBub, pixelize(barWidth - width(ceilBub))
          newLowValue = percentValue scope.ngModelLow
          offset minPtr, percentToOffset newLowValue
          offset lowBub, pixelize(offsetLeft(minPtr) - (halfWidth lowBub) + handleHalfWidth)
          offset selection, pixelize(offsetLeft(minPtr) + handleHalfWidth)

          switch true
            when range
              newHighValue = percentValue scope.ngModelHigh
              offset maxPtr, percentToOffset newHighValue
              offset highBub, pixelize(offsetLeft(maxPtr) - (halfWidth highBub) + handleHalfWidth)
              selection.css width: percentToOffset newHighValue - newLowValue
            when attributes.highlight is 'right'
              selection.css width: percentToOffset 110 - newLowValue
            when attributes.highlight is 'left'
              selection.css width: percentToOffset newLowValue
              offset selection, 0

        bindToInputEvents = (handle, bubble, ref, events) ->
          currentRef = ref
          onEnd = ->
            bubble.removeClass 'active'
            handle.removeClass 'active'
            ngDocument.unbind events.move
            ngDocument.unbind events.end
            currentRef = ref
          onMove = (event) ->
            eventX = event.clientX || event.touches[0].clientX
            newOffset = eventX - element[0].getBoundingClientRect().left - handleHalfWidth
            newOffset = Math.max(Math.min(newOffset, maxOffset), minOffset)
            newPercent = percentOffset newOffset
            newValue = minValue + (valueRange * newPercent / 100.0)
            if range
              switch currentRef
                when 'ngModelLow'
                  if newValue > scope.ngModelHigh
                    currentRef = 'ngModelHigh'
                    minPtr.removeClass 'active'
                    lowBub.removeClass 'active'
                    maxPtr.addClass 'active'
                    highBub.addClass 'active'
                    setPointers()
                  else if scope.buffer > 0
                    newValue = Math.min newValue,
                      scope.ngModelHigh - scope.buffer
                when 'ngModelHigh'
                  if newValue < scope.ngModelLow
                    currentRef = 'ngModelLow'
                    maxPtr.removeClass 'active'
                    highBub.removeClass 'active'
                    minPtr.addClass 'active'
                    lowBub.addClass 'active'
                    setPointers()
                  else if scope.buffer > 0
                    newValue = Math.max newValue,
                      parseInt(scope.ngModelLow) + parseInt(scope.buffer)
            newValue = roundStep(newValue, parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor))
            scope[currentRef] = newValue
            scope.$apply()
          onStart = (event) ->
            dimensions()
            bubble.addClass 'active'
            handle.addClass 'active'
            setPointers()
            event.stopPropagation()
            event.preventDefault()
            ngDocument.bind events.move, onMove
            ngDocument.bind events.end, onEnd
          handle.bind events.start, onStart

        setBindings = ->
          boundToInputs = true
          bind = (method) ->
            bindToInputEvents minPtr, lowBub, 'ngModelLow', inputEvents[method]
            bindToInputEvents maxPtr, highBub, 'ngModelHigh', inputEvents[method]
          bind(inputMethod) for inputMethod in ['touch', 'mouse']

        setBindings() unless boundToInputs
        setPointers()

      $timeout updateDOM
      scope.$watch w, updateDOM, true for w in watchables
      window.addEventListener "resize", updateDOM

qualifiedDirectiveDefinition = [
  '$timeout'
  sliderDirective
]

module = (window, angular) ->
  angular
    .module(MODULE_NAME, [])
    .directive(SLIDER_TAG, qualifiedDirectiveDefinition)

module window, window.angular
