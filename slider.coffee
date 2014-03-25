# CONSTANTS

MODULE_NAME = 'ui.slider'
SLIDER_TAG  = 'slider'

# HELPER FUNCTIONS

angularize      = (element) -> angular.element element
pixelize        = (position) -> "#{position}px"
hide            = (element) -> element.css opacity: 0
show            = (element) -> element.css opacity: 1
offset          = (element, position) -> element.css left: position
halfWidth       = (element) -> element[0].offsetWidth / 2
offsetLeft      = (element) -> element[0].offsetLeft
width           = (element) -> element[0].offsetWidth
gap             = (element1, element2) -> offsetLeft(element2) - offsetLeft(element1) - width(element1)
roundStep       = (value, precision, step, floor = 0) ->
    step ?= 1 / Math.pow(10, precision)
    remainder = (value - floor) % step
    steppedValue =
        if remainder > (step / 2)
        then value + step - remainder
        else value - remainder
    decimals = Math.pow 10, precision
    roundedValue = steppedValue * decimals / decimals
    roundedValue.toFixed precision
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
        floor:       '@'
        ceiling:     '@'
        step:        '@'
        precision:   '@'
        ngModel:     '=?'
        ngModelLow:  '=?'
        ngModelHigh: '=?'
    template: '
        <span class="bar"></span>
        <span class="bar selection"></span>
        <span class="handle"></span>
        <span class="handle"></span>
        <span class="bubble limit">{{ floor }}</span>
        <span class="bubble limit">{{ ceiling }}</span>
        <span class="bubble low">{{ ngModelLow }}</span>
        <span class="bubble high">{{ ngModelHigh }}</span>'
    compile: (element, attributes) ->

        # Check if it is a range slider
        range = !attributes.ngModel? and attributes.ngModelLow? and attributes.ngModelHigh?

        # Get references to template elements
        [fullBar, selBar, minPtr, maxPtr,
            flrBub, ceilBub, lowBub, highBub] = (angularize(e) for e in element.children())

        # Shorthand references to the 2 model scopes
        low = if range then 'ngModelLow' else 'ngModel'
        high = 'ngModelHigh'

        # Remove range specific elements if not a range slider
        unless range
            element.remove() for element in [selBar, maxPtr, highBub]

        # Scope values to watch for changes
        watchables = [low, 'floor', 'ceiling']
        watchables.push high if range

        post: (scope, element, attributes) ->

            boundToInputs = false
            ngDocument = angularize document
            handleHalfWidth = barWidth = minOffset = maxOffset = minValue = maxValue = valueRange = offsetRange = undefined

            dimensions = ->
                # roundStep the initial score values
                scope.precision ?= 0
                scope.step ?= 1
                scope[value] = roundStep(parseFloat(scope[value]), parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor)) for value in watchables
                scope.diff = roundStep(scope[high] - scope[low], parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor))

                # Commonly used measurements
                handleHalfWidth = halfWidth minPtr
                barWidth = width fullBar

                minOffset = 0
                maxOffset = barWidth - width(minPtr)

                minValue = parseFloat attributes.floor
                maxValue = parseFloat attributes.ceiling

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
                    newLowValue = percentValue scope[low]
                    offset minPtr, percentToOffset newLowValue
                    offset lowBub, pixelize(offsetLeft(minPtr) - (halfWidth lowBub) + handleHalfWidth)
                    if range
                        newHighValue = percentValue scope[high]
                        offset maxPtr, percentToOffset newHighValue
                        offset highBub, pixelize(offsetLeft(maxPtr) - (halfWidth highBub) + handleHalfWidth)
                        offset selBar, pixelize(offsetLeft(minPtr) + handleHalfWidth)
                        selBar.css width: percentToOffset newHighValue - newLowValue

                adjustBubbles = ->
                    fitToBar lowBub
                    bubToAdjust = highBub

                    if range
                        fitToBar highBub

                    if gap(flrBub, lowBub) < 5
                        hide flrBub
                    else
                        if range
                            if gap(flrBub, bubToAdjust) < 5 then hide flrBub else show flrBub
                        else
                            show flrBub
                    if gap(lowBub, ceilBub) < 5
                        hide ceilBub
                    else
                        if range
                            if gap(bubToAdjust, ceilBub) < 5 then hide ceilBub else show ceilBub
                        else
                            show ceilBub


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
                                when low
                                    if newValue > scope[high]
                                        currentRef = high
                                        minPtr.removeClass 'active'
                                        lowBub.removeClass 'active'
                                        maxPtr.addClass 'active'
                                        highBub.addClass 'active'
                                when high
                                    if newValue < scope[low]
                                        currentRef = low
                                        maxPtr.removeClass 'active'
                                        highBub.removeClass 'active'
                                        minPtr.addClass 'active'
                                        lowBub.addClass 'active'
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
                        bindToInputEvents minPtr, lowBub, low, inputEvents[method]
                        bindToInputEvents maxPtr, highBub, high, inputEvents[method]
                    bind(inputMethod) for inputMethod in ['touch', 'mouse']

                setPointers()
                adjustBubbles()
                setBindings() unless boundToInputs

            $timeout updateDOM
            scope.$watch w, updateDOM for w in watchables
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
