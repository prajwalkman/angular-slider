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
gap           = (element1, element2) ->
  offsetLeft(element2) - offsetLeft(element1) - width(element1)

contain       = (value) ->
  return value if isNaN value
  Math.min Math.max(0, value), 100

roundStep     = (value, precision, step, floor = 0) ->
  step ?= 1 / Math.pow(10, precision)
  remainder = (value - floor) % step
  steppedValue =
    if remainder > (step / 2)
    then value + step - remainder
    else value - remainder
  decimals = Math.pow 10, precision
  roundedValue = steppedValue * decimals / decimals
  parseFloat roundedValue.toFixed precision

events =
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
    step:         '@'
    highlight:    '@'
    precision:    '@'
    buffer:       '@'
    dragstop:     '@'
    ngModel:      '=?'
    ngModelLow:   '=?'
    ngModelHigh:  '=?'
  template: '''
    <div class="bar"><div class="selection"></div></div>
    <div class="handle low"></div><div class="handle high"></div>
    <div class="bubble limit low">{{ values.length ? values[floor || 0] : floor }}</div>
    <div class="bubble limit high">{{ values.length ? values[ceiling || values.length - 1] : ceiling }}</div>
    <div class="bubble value low">{{ values.length ? values[local.ngModelLow || local.ngModel || 0] : local.ngModelLow || local.ngModel || 0 }}</div>
    <div class="bubble value high">{{ values.length ? values[local.ngModelHigh] : local.ngModelHigh }}</div>'''
  compile: (element, attributes) ->

    # Check if it is a range slider
    range = !attributes.ngModel? and attributes.ngModelLow? and attributes.ngModelHigh?

    low = if range then 'ngModelLow' else 'ngModel'
    high = 'ngModelHigh'

    # Scope values to watch for changes
    watchables = ['floor', 'ceiling', 'values', low]
    watchables.push high if range

    post: (scope, element, attributes) ->
      # Get references to template elements
      [bar, minPtr, maxPtr, flrBub, ceilBub, lowBub, highBub] = (angularize(e) for e in element.children())
      selection = angularize bar.children()[0]

      # Remove range specific elements if not a range slider
      unless range
        upper.remove() for upper in [maxPtr, highBub]
        selection.remove() unless attributes.highlight

      scope.local = {}
      scope.local[low] = scope[low]
      scope.local[high] = scope[high]

      bound = false
      ngDocument = angularize document
      handleHalfWidth = barWidth = minOffset = maxOffset = minValue = maxValue = valueRange = offsetRange = undefined

      dimensions = ->
        # roundStep the initial score values
        scope.step ?= 1
        scope.floor ?= 0
        scope.precision ?= 0
        scope.ngModelLow = scope.ngModel unless range
        scope.ceiling ?= scope.values.length - 1 if scope.values?.length

        scope.local[low] = scope[low]
        scope.local[high] = scope[high]

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
        percentOffset = (offset) -> contain ((offset - minOffset) / offsetRange) * 100
        percentValue = (value) -> contain ((value - minValue) / valueRange) * 100
        pixelsToOffset = (percent) -> pixelize percent * offsetRange / 100

        setPointers = ->
          offset ceilBub, pixelize(barWidth - width(ceilBub))
          newLowValue = percentValue scope.local[low]
          offset minPtr, pixelsToOffset newLowValue
          offset lowBub, pixelize(offsetLeft(minPtr) - (halfWidth lowBub) + handleHalfWidth)
          offset selection, pixelize(offsetLeft(minPtr) + handleHalfWidth)

          switch true
            when range
              newHighValue = percentValue scope.local[high]
              offset maxPtr, pixelsToOffset newHighValue
              offset highBub, pixelize(offsetLeft(maxPtr) - (halfWidth highBub) + handleHalfWidth)
              selection.css width: pixelsToOffset newHighValue - newLowValue
            when attributes.highlight is 'right'
              selection.css width: pixelsToOffset 110 - newLowValue
            when attributes.highlight is 'left'
              selection.css width: pixelsToOffset newLowValue
              offset selection, 0

        bind = (handle, bubble, ref, events) ->
          currentRef = ref
          onEnd = ->
            bubble.removeClass 'active'
            handle.removeClass 'active'
            ngDocument.unbind events.move
            ngDocument.unbind events.end
            if scope.dragstop
              scope[high] = scope.local[high]
              scope[low] = scope.local[low]
            currentRef = ref
            scope.$apply()
          onMove = (event) ->
            eventX = event.clientX or event.touches?[0].clientX or event.originalEvent?.changedTouches?[0].clientX or 0
            newOffset = eventX - element[0].getBoundingClientRect().left - handleHalfWidth
            newOffset = Math.max(Math.min(newOffset, maxOffset), minOffset)
            newPercent = percentOffset newOffset
            newValue = minValue + (valueRange * newPercent / 100.0)
            if range
              switch currentRef
                when low
                  if newValue > scope.local[high]
                    currentRef = high
                    minPtr.removeClass 'active'
                    lowBub.removeClass 'active'
                    maxPtr.addClass 'active'
                    highBub.addClass 'active'
                    setPointers()
                  else if scope.buffer > 0
                    newValue = Math.min newValue,
                      scope.local[high] - scope.buffer
                when high
                  if newValue < scope.local[low]
                    currentRef = low
                    maxPtr.removeClass 'active'
                    highBub.removeClass 'active'
                    minPtr.addClass 'active'
                    lowBub.addClass 'active'
                    setPointers()
                  else if scope.buffer > 0
                    newValue = Math.max newValue,
                      parseInt(scope.local[low]) + parseInt(scope.buffer)
            newValue = roundStep(newValue, parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor))
            scope.local[currentRef] = newValue
            unless scope.dragstop
              scope[currentRef] = newValue
            setPointers()

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
          for method in ['touch', 'mouse']
            bind minPtr, lowBub, low, events[method]
            bind maxPtr, highBub, high, events[method]
          bound = true

        setBindings() unless bound
        setPointers()

      $timeout updateDOM
      scope.$watch w, updateDOM, true for w in watchables
      window.addEventListener 'resize', updateDOM

qualifiedDirectiveDefinition = [
  '$timeout'
  sliderDirective
]

module = (window, angular) ->
  angular
    .module(MODULE_NAME, [])
    .directive(SLIDER_TAG, qualifiedDirectiveDefinition)

module window, window.angular
