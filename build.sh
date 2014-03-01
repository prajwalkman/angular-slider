coffee -c slider.coffee

uglifyjs slider.js -mc > slider.min.js

stylus slider.styl -c --use ./node_modules/nib -o ./
mv slider.css slider.min.css
stylus slider.styl --use ./node_modules/nib -o ./
