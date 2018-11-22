# Nologue!
Nologue is an RPG-style text display system with advanced animations.

This is a fork of a Godot 2.x plugin called 
[Sologue](https://github.com/ArcOfDream/sologue).

## New Features
In addition to porting the old code to Godot 3, Nologue adds a few extra things.

* Word wrapping

    Sologue never had word wrapping, meaning that words would get cut in half 
    when they reach the end of the space available. Because of this, it was 
    inconvenient to use as an actual dialogue box. 

* Text skipping

    When playing a game with a lot of dialogue, waiting for all the text to 
    scroll can take a while. Because of this, many games allow you to skip the 
    scrolling and just show all the text. You, too, can utilize this power. Just 
    call `next_line()` while the text is still scrolling. (you can disable this 
    by setting the `skippable` var to false.)

Sologue's animated text effects are fantastic, and I haven't seen any other 
plugin like it. Unfortunately, without the above features, it isn't very useful 
on its own. That's why I forked it. 

## Installation
To use this plugin, you should make an "addons" folder in the root of your 
project, and then move the `nologue` folder from this repo's addons folder 
to your own. After that, it's as simple as switching the plugin to "Active" in 
the Plugins tab of your Project Settings menu. After that, Nologue should be 
available in your node list.

## Usage
Sologue was designed as a single-node dialogue system, and Nologue continues 
this tradition. All you need to do is add the node to your scene, add the 
dialogue to the array in the script variables, and then call `run()` when you 
want the box to appear and start reading.

### Text Effects
You can use short codes in your text to make it move around when shown by 
Nologue. See the list below.

| Name   | Code | Description |
| ------ | ---- | ----------- |
| Shake  | /s   | Makes text so angry that it shakes |
| Wave   | /w   | Makes text wave around mysteriously |
| Bounce | /b   | Makes text that excitedly bounces up and down |
| Twitch | /t   | Makes text that twitches around nervously |
| Reset  | /r   | Makes the text normal again |

You can also use /dxxx with a 3-digit number where the x's are to set the speed
the text scrolls at. For example, /d200 would reveal a new character every 2 
seconds. The default is /d005

#### Effect changes
* In Sologue, the "Wave" effect was very similar to "Bounce". In Nologue, it 
now makes all the letters flow around together, making it unique.
* The "Bounce" effect was upside-down in Sologue. That was fixed by adding a 
missing negative sign.
* The "Twitch" effect is new in Nologue. It is inspired by the subtle twitching 
effect that Undertale has for some of its text.

## Credits

* Thanks to NavyFish for coming up with the word_wrap() function used here.
* And of course, thanks to ArcOfDream for creating Sologue.
