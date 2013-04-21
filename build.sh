

coffee -bc src/angular-slider.coffee

mv src/angular-slider.js ./

uglifyjs angular-slider.js -mc > angular-slider.min.js