<h1>roblox-path-plugin</h1>
The open source feature-rich Roblox Studio plugin for a variety of path-creating needs, such as railways, roads, fences and more!
<br/><br/>
<img width="1002" alt="image" src="https://github.com/Open-Source-Transport/roblox-path-plugin/assets/129159900/e1abf586-bbf0-4037-8704-3cd3518add1d">

<h2> Contents </h2>

* [Features](#features)
* [History](#history)
* [Installation](#installation)
* [Contributing](#contributing)
* [License](#license)

# Features

- Easy-to-use plugin widget GUI

- Automatic gap filling - utilises stravant's ResizeAlgin to provide gapfill with no extra setup required

- Automatic optimisation

- Cubic bezier curve paths

- Axis selection

- Banking (also known as superelevation or canting)

- Fast previews with automatic refresh rate scaling

- Connecting to existing paths, even ones not made by this plugin

Unlike other tools, this tool doesn't lock you down to a specific type of "path" - as long as you've got a model which has all the parts facing in the same direction, you can use it. It is therefore highly customisable.

More features are planned! If something you need is missing, feel free to [contribute](#contributing).

# History

In 2019, Anthony (@anthony0br) created a simple tool aimed at creating railway tracks using Bezier Curves called "Electrified Track Placer". Originally developed for a specific project, this was subsequently open sourced (released as a .rbxm) and used by many developers on Roblox, particularly in transport games.

Recently, a group of developers in this community have come together, creating "Open Source Transport", to improve and maintain this plugin!

# Installation

If you want to use this plugin now we suggest cloning the main branch and using Rojo to build this project then click "Save as local plugin" on the Plugin model in Roblox Studio.

Soon, releases will be available on the Github releases page and a release with automatic updates will be published on the Roblox plugin store.

# Limitations

Your 'segment' template needs to have all its BaseParts lined up in a single axis direction (the model can be rotated in any way).

This plugin works with 'box' shaped segments. If you use the banking feature, there will be gaps/steps visible, and there isn't much we can do about this. Therefore, it may not be advisable for roads with complicated geometry. A plugin which creates a surface from triangles, or a program like blender, may be more suitable.

Currently, bank angles aren't preserved between curves.

See Issues for more.

# Getting involved

We welcome contributions. This project is currently maintained by @anthony0br and @arandomollie, but there are several other active contributors. Read the [CONTRIBUTING.md](https://github.com/Open-Source-Transport/roblox-path-plugin/blob/main/CONTRIBUTING.md) file and get in touch!

# License

All current and future versions of this software are [licensed under GNU GPL-3.0](https://github.com/Open-Source-Transport/roblox-path-plugin/blob/main/LICENSE). We have put significant time and effort into this free resource - if you use our code in your projects, please open source them!
