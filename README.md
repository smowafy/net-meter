# Network Throughput widget for Awesome WM


## Prerequisites
Awesome Window Manager (https://awesomewm.org/)

## Adding to your Window Manager
- Add the file `networkmeter.lua` to the directory `$HOME/.config/awesome`.
- In your `rc.lua` file, near the top, require the widget.
```
local networkmeter = require'networkmeter'
```
- Initialize the widget.
```
mynetworkmeter = networkmeter()
````
- Add it to your `wibar`, you'll find something like this in your `rc.lua`.
```
s.mywibox:setup {
...
mynetworkmeter,
...
}
```

## Contributing
You're welcome to contribute, just create an issue or a pull request with the bug-fix/addition.
