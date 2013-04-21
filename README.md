angular-slider (WIP)
====================

Slider directive implementation for AngularJS, without jQuery dependencies.

### Example:

    <ul>
        <li ng-repeat="item in items">
            <p>Name: {{item.name}}</p>
            <p>Cost: {{item.cost}}</p> 
            <slider min="100" max="1000" step="50" ng-model="item.cost"></slider>
        </li>
    </ul>

### Styles:

No styles are included at the moment. You must apply your own styles to *slider* and *slider-button*
Example:

    slider,
    slider-button {
        position: relative;
        display: block;
    }
    slider {
        width: 75%;
        height: 20px;
        background-color: #fff;
        border: 1px solid;
        z-index: 0;
    }
    slider slider-button {
        z-index: 1;
        background-color: #00f;
        width: 6%;
        height: 100%;
    }


### Known issues:
  
1. When applying filters or orders within an ng-repeat directive, the element can abruptly change its position when the value attached to the slider causes a filter to activate or the order to change. 
Example: In the above snippet, it would be a very bad idea to order the list by item.cost.

2. Sometimes an additional value is available in the slider at one end. In the above slider snipped, the lowest value could be 99 instead of 100.


### Roadmap:

1. Add range slider support (2 slider-buttons).

2. Add classes to slider and slider-button on certain events (mouseover, mousedown, etc) to help styling.

3. Test suite.
