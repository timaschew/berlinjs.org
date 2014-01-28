### Solving the callback hell through generators and promises

##### [Andreas Lubbe](http://berlinjs.org/archive.html)

JavaScript has the tendency to produce callback code that is constantly headed for the right edge of the screen and makes error checking & handling anything but fun. The async library doesn't help much with errors, promises are slow and fibers unreliable. So what to do?

ES6 has introduced generators and newer libraries such as bluebird offer the flexibility of promises with the speed of async. This talk will introduce these concepts and show live demos and benchmarks.