angular-slider (WIP)
====================

Slider directive implementation for AngularJS, without jQuery dependencies.

### Example:

    <ul>
        <li ng-repeat="item in items">
            <p>Name: {{item.name}}</p>
            <p>Cost: {{item.cost}}</p> 
            <slider min="100" max="1000" step="50" value="item.cost"></slider>
        </li>
    </ul>


### Known issues:
  
1. When applying filters or orders within an ng-repeat directive, the element can abruptly change its position when the value attached to the slider causes a filter to activate or the order to change. 
Example: In the above snippet, it would be a very bad idea to order the list by item.cost.