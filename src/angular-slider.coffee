# CONSTANTS

MODULE_NAME = 'uiSlider'
SLIDER_TAG  = 'slider'

# HELPER FUNCTIONS

angularize      = (element) -> angular.element element
pixelize        = (position) -> "#{position}px"
percentize      = (position) -> "#{position}%"
addAnimation    = (elements) -> element.addClass 'animated' for element in elements
removeAnimation = (elements) -> element.removeClass 'animated' for element in elements
hide            = (element) -> element.css opacity: 0
show            = (element) -> element.css opacity: 1
offset          = (element, position) -> element.css left: position
halfWidth       = (element) -> element[0].offsetWidth / 2
offsetLeft      = (element) -> element[0].offsetLeft
width           = (element) -> element[0].offsetWidth
gap             = (element1, element2) -> offsetLeft(element2) - offsetLeft(element1) - width(element1)
bindHtml        = (element, html) -> element.attr 'ng-bind-html-unsafe', html
roundStep       = (value, precision, step) ->
    step ?= 1 / Math.pow(10, precision)
    remainder = value % step
    steppedValue =
        if remainder > (step / 2)
        then value + step - remainder
        else value - remainder
    decimals = Math.pow 10, precision
    roundedValue = steppedValue * decimals / decimals
    roundedValue.toFixed precision

# DIRECTIVE DEFINITION

sliderDirective = ($timeout) ->
    restrict: 'EA'
    scope:
        floor:       '@'
        ceiling:     '@'
        step:        '@'
        precision:   '@'
        ngModel:     '=?'
        ngModelLow:  '=?'
        ngModelHigh: '=?'
        translate:   '&'
    templateUrl: '/partials/slider_template.html'
    compile: (element, attributes) ->

        # Expand the translation function abbreviation
        attributes.$set 'translate', "#{attributes.translate}(value)" if attributes.translate

        # Check if it is a range slider
        range = !attributes.ngModel? and (attributes.ngModelLow? and attributes.ngModelHigh?)

        # Get references to template elements
        [fullBar, selBar, minPtr, maxPtr, selBub,
            flrBub, ceilBub, lowBub, highBub, cmbBub] = (angularize(e) for e in element.children())
        
        # Shorthand references to the 2 model scopes
        refLow = if range then 'ngModelLow' else 'ngModel'
        refHigh = 'ngModelHigh'

        bindHtml selBub, "'Range: ' + translate({value: diff})"
        bindHtml lowBub, "translate({value: #{refLow}})"
        bindHtml highBub, "translate({value: #{refHigh}})"
        bindHtml cmbBub, "translate({value: #{refLow}}) + ' - ' + translate({value: #{refHigh}})"

        # Remove range specific elements if not a range slider
        unless range
            element.remove() for element in [selBar, maxPtr, selBub, highBub, cmbBub]

        # Scope values to watch for changes
        watchables = [refLow, 'floor', 'ceiling']
        watchables.push refHigh if range

        post: (scope, element, attributes) ->

            bindMouse = false
            ngDocument = angularize document
            unless attributes.translate
                scope.translate = (value) -> value.value

            pointerHalfWidth = barWidth = minOffset = maxOffset = minValue = maxValue = valueRange = offsetRange = undefined

            dimensions = ->
                # roundStep the initial score values
                scope[value] = roundStep(parseFloat(scope[value]), parseInt(scope.precision), parseFloat(scope.step)) for value in watchables
                scope.diff = roundStep(scope[refHigh] - scope[refLow], parseInt(scope.precision), parseFloat(scope.step))
                
                # Commonly used measurements
                pointerHalfWidth = halfWidth minPtr
                barWidth = width fullBar

                minOffset = 0 - pointerHalfWidth
                maxOffset = barWidth - pointerHalfWidth

                minValue = parseFloat attributes.floor
                maxValue = parseFloat attributes.ceiling

                valueRange = maxValue - minValue
                offsetRange = maxOffset - minOffset                

            updateDOM = ->
                dimensions()

                # Translation functions
                percentOffset = (offset) -> ((offset - minOffset) / offsetRange) * 100
                percentValue = (value) -> ((value - minValue) / valueRange) * 100

                # Fit bubble to bar width
                fitToBar = (element) -> offset element, pixelize(Math.min (Math.max 0, offsetLeft(element)), (barWidth - width(element)))

                setPointers = ->
                    offset ceilBub, pixelize(barWidth - width(ceilBub))
                    newLowValue = percentValue scope[refLow]
                    offset minPtr, percentize(newLowValue)
                    offset lowBub, pixelize(offsetLeft(minPtr) - (halfWidth lowBub) + pointerHalfWidth)
                    if range
                        newHighValue = percentValue scope[refHigh]
                        offset maxPtr, percentize(newHighValue)
                        offset highBub, pixelize(offsetLeft(maxPtr) - (halfWidth highBub) + pointerHalfWidth)
                        offset selBar, pixelize(offsetLeft(minPtr) + pointerHalfWidth)
                        selBar.css width: percentize(newHighValue - newLowValue)
                        offset selBub, pixelize(offsetLeft(selBar) + halfWidth(selBar) - halfWidth(selBub))
                        offset cmbBub, pixelize(offsetLeft(selBar) + halfWidth(selBar) - halfWidth(cmbBub))

                adjustBubbles = ->
                    fitToBar lowBub
                    bubToAdjust = highBub

                    if range
                        fitToBar highBub
                        fitToBar selBub

                        if gap(lowBub, highBub) < 10
                            hide lowBub
                            hide highBub
                            fitToBar cmbBub
                            show cmbBub
                            bubToAdjust = cmbBub
                        else
                            show lowBub
                            show highBub
                            hide cmbBub
                            bubToAdjust = highBub

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


                bindMouseToPointer = (pointer, ref) ->
                    pointer.bind 'mousedown', (event) ->
                        dimensions()
                        event.stopPropagation()
                        event.preventDefault()
                        ngDocument.bind 'mousemove', (event) ->
                            newOffset = event.clientX - offsetLeft(element) - width(pointer)
                            newOffset = Math.max(Math.min(newOffset, maxOffset), minOffset)
                            newPercent = percentOffset newOffset
                            newValue = minValue + (valueRange * newPercent / 100.0)
                            if range
                                if ref is refLow
                                    ref = refHigh if newValue > scope[refHigh]
                                else
                                    ref = refLow if newValue < scope[refLow]
                            newValue = roundStep(newValue, parseInt(scope.precision), parseFloat(scope.step))
                            scope[ref] = newValue
                            scope.$apply()
                        ngDocument.bind 'mouseup', ->
                            ngDocument.unbind 'mousemove'
                            ngDocument.unbind 'mouseup'

                setBindings = ->
                    bindMouse = true
                    bindMouseToPointer minPtr, refLow
                    bindMouseToPointer maxPtr, refHigh

                setPointers()
                adjustBubbles()
                setBindings() unless bindMouse

            $timeout updateDOM
            scope.$watch w, updateDOM for w in watchables
            window.addEventListener "resize", updateDOM

module = (window, angular) ->
    angular
        .module(MODULE_NAME, [])
        .directive(SLIDER_TAG, sliderDirective)

module window, window.angular