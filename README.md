# ACT-R

This is a partial implementation of the ACT-R cognitive architecture (see act-r.psy.cmu.edu) in Swift for use in XCode.
The repository implements an iOS App that can play the Prisoner's Dilemma model, both the original Wallach & Lebiere (2000)
model, and the newer Stevens & Taatgen (2015) model.

The ACT-R core files can be used for your own models and your own application.

<h3>What is implemented?</h3>
The implementation is limited to a subset of the buffers. It implements =goal>, =imaginal>, =retrieval>, =temporal> as you might expect it. It implements =visual-location> and =visual>, but instead of defining a visicon in your code, you have to create a part of the UI that ACT-R is allowed to see (see subitizing example for details). It has a =partial> buffer for partial matching separate from regular retrieval.

In addition to the buffers above, an =action> buffer is implemented that can be used to pass information between the model and the App. Typically you run the model until it reaches an +action> action, after which control is passed back to the App (i.e., swift). The Swift code can read out the action, take appropriate actions, may put information back into the action buffer, after which model execution proceeds (or waits until an external event, for example user input).

The following ACT-R parameters are implemented: :ga, :rt, :ans,  :lf, :mp, :mas, :egs, :bll and :ol.

Baselevel learning is always on, you can change the decay with :bll, but you cannot switch it off. 

The following ACT-R commands are implemented: add-dm, spp, sgp, p, goal-focus, set-all-baselevels, and set-fixed-baselevels. set-fixed-baselevels can gives chunks a baselevel activation that does not decay, which can be useful to represent long-term knowledge.

The current implementation supports declarative learning (adding new chunks, and baselevel learning), but not procedural learning (utility learning and production compilation).

<h3>The Model class</h3>
The Model class is the main class to use to build a model. You can either subclass it and add some model-specific functions in the subclass, or just use it as it is. Typically you create an instance of Model or its subclass, load in an ACT-R model from a textfile, and then run the model until it takes an action.

For some models that will be enough (including the example Prisoner's dilemma). In other cases you migh want to manipulate other classes directly.

<h4> Relevant methods and instance variables in Model </h4>

loadModel(filename: String) : load in an ACT-R model with the supplied filename. The assumption is that the file is part of the "Bundle", so the name is a simple string (e.g. "prisoner'). The assumption is that the extension of the file is ".actr".

run(): Run the model until it ends or encounters a +action> 

reset(): Reset the model: set time back to 0, clear all buffers, reparse the model code.

waitingForAction: a boolean that is true if the model has stopped because of a +action> It also broadcasts a notification "Action" (see Stanford lessons about what that means).

time: a Double that represents the current ACT-R time. You can modify it if you want, although moving it back is not recommended.

lastAction(slot: slotname): returns an optional String with the value in the slotname of the action the model posted. Useful to determine what the action of the model is.

modifyLastAction(slot: slotname, value: String): modify the chunk in the action slot. This is a relative primitive way to communicate the results of the action back to the model. 

dm: an instance of the Declarative class that holds the contents of declarative memory of the model. dm.chunks is a Dictionary with all the chunks in memory, keyed by the chunk's name (so dm.chunks["additionfact1"] will give you the Chunk with name additionfact1, or nil if it does not exists).

procedural: an instance of the Procedural class that hold procedural memory

buffers: a dictionary that maps a buffer name onto a Chunk object. For example, buffers["goal"] has the current goal chunk, or nil when there is none

running: boolean that indicates whether or not the model is currently running

trace: a String that contains the current trace of the model. You can copy this to a text window in your App if you want to see the trace

modelText: a String that contains the text of the current model.

<h3>The Chunk class</h3>
The Chunk class is used to represent chunk objects, which are either  in declarative memory, or not. Chunks in buffers are normally not in declarative memory, and do not (yet) have a time stamp. You can create a chunk with Chunk(s: <chunk-name>, m: <model-class>)

The main class variables of a Chunk are:

name: the name of the chunk (set when you create the chunk)

model: which model does the chunk belong to (set when you create the chunk)

creationTime: when was the chunk added to dm. Nil when it is not in dm (yet).

slotvals: a dictionary with slot-value bindings. Slots are just Strings, but values of of enumeration type Value, which is defined in Support.swift

references: How many references had the chunk had? Used to calculate base-level activation when optimized learning is on

referenceList: List of timestamps when the chunk was references. Used when optimized learning is off

fixedActivation: if this has a non-nil value, it means that the chunk has a fixed activation. This is useful in cases where some of the knowledge in the model should not decay, in particular knowledge that you assume the model already has for a long time



