# Moan #

Moan is a sound synthesis utility thingy for [LOVE](http://www.love2d.org).
I created three demos so you can see what one can do using moan:

* a piano/keyboard
* 'Circlesynth', kind of a sequencer
* a sequencer

## Demos ##
On startup you are presented with an ugly menu screen.


### Keyboard ###
Use your keyboard to play stuff. The characters on the keys (the virtual ones)
denote which key you will have to press to create a tone.
The first startup will take a little time to create all the samples. Be patient.


### Circlesynth ###
Great for annoying people.
Usage is as following:

#### Left-click ####
A left-click will spawn a new tone presented as a circle. The color of the
circle marks the oscillator used to create the tone, the size represents 
the duration of the sample.
The position on the horizontal axis influences the frequency, whereas the 
vertical axis modifies the loudness of the tone.

If you left-click on a circle, it will change it's oscillator.

#### Right-click ####
Right-clicking on a circle will let you change it's size.

#### Middle-click ####
On a circle, a middle-click will delete it. Click anywhere else to create a 
wave. When a wave hits a circle, the circles tone is played and (maybe) 
another wave is spawned.

#### The 'c' key ####
Tired of your creation? Press 'c'!


### Sequencer ###
Place notes with your left mouse button. Multiple left-clicks will change
the note's oscillator. Right-clicking will delete the note.

Press 'c' to clear the board.
'a'/'s' will increase/decrease the BPM.

## Library ##
Soon... (or never)
