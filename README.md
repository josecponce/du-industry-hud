# DU Industry Hud

## Special Thanks
- Wolfe: for his great work on [du-luac](https://github.com/wolfe-labs/DU-LuaC)
- Jericho: for the tons of code I stole from his [DU-Industry-HUD](https://github.com/Jericho1060/DU-Industry-HUD)
  and [du-storage-monitoring](https://github.com/Jericho1060/du-storage-monitoring) projects. 

## Important Note
- This is derived from Jericho's [DU-Industry-HUD](https://github.com/Jericho1060/DU-Industry-HUD) and will likely 
 not be supported long term, so I recommend you use his instead.
- This also uses more parts (receivers/switches/etc) than the original and is more complex to setup.

## Features
- General Industry Info: 
  - Displays status information per industry type for all industries on the construct.
  - Navigate industry groups/types using Ctrl + Up/Down.
  - Navigate industries using Up/Down/Left/Right.
  - Navigate to industry group/type that builds the industry element used in the current row: Alt + Left
  - Navigate to industry group/type that contains industries being produced by the current row: Alt + Right
    - Only when output of current row is an industry element.
- Industry Markers/Stickers: Markers are displayed around the selected industry element to make it easier to find.
- Show/Hide Hud: Alt + 2. Also, useful to avoid key presses to be interpreted by the Hud.
- Industry Output Recipe Containers/Hubs:
  - Displays total quantity of the output element for every industry in the "General Industry Info" table.
  - Show/Hide Input/Output containers AR: Alt + 3. Highlights input and out containers/hubs for the output of the currently selected industry.
  - These features only work if additional instructions to follow containers/hubs naming convention were followed.
- Control:
  - Issue a Command:
    - Select industry in "General Industry Info" table.
    - Press Alt + Down. Prompt should appear in lua console.
    - Type command in lua console and hit Enter.
  - Available commands:
    - r: Run factory.
    - s force: Stop factory. If force is "true" then it'll stop the factory immediately, but it'll not
      force stop if stopping would cause loss of ingredients.
    - b N: Run factory in batch mode for N batches.
    - m N: Run factory in maintain mode for N units.
  - Only works if the additional instructions to set up control programming boards for your industries were followed.
  - IMPORTANT: No feedback is provided if command fails.

## Known Limitations
- In case of error in the control boards the switch needs to be manually turned off.
- Let me know if I missed anything else?????

## Parts Required
- Main/Hud Component (Required)
  - Programming Board: 1 for Main/Hud component
  - Emitter: 1. Optional, only if Control component is set up.
- Control Component (Optional, repeat for every 8 industries)
  - Programming Board: 1
  - Manual Switch: 1
  - Receiver: 1

## Setup Instructions
### Setup Main/Hud Component
- Deploy Programming Board
- Deploy 1 emitter. Optional, only if Control component is set up.
- Connect in the following order:
  - construct core
  - emitter
- Update lua parameters as needed.

### Setup Control Component
Repeat for every 8 Industries:
- Deploy programming board, 1 manual switch and 1 receiver.
- Connect in the following order:
  - switch to programming board: Full link
  - receiver:
    - Control link from programming board
    - Signal link to switch
  - industries: up to 8
- Update lua parameters:
  - Set `channelPrefix` to a short alphanumerical value. Should be different for each of the boards you set up in a single construct.
- Rename Industries connected to this board to being with the prefix set in the `channelPrefix` parameter in previous step.
  - Format is like: "channelPrefix_WhateverDescription". Note the underscore separator is not part of the `channelPrefix` parameter.
- Update other lua parameters as needed.
- Turn on the programming board once
  - This step is REQUIRED.
  - Do it directly on the board, not the switch.
  - The programming board will turn itself off right away, that's expected.
- Ensure the switch is off at this point.
  - You shouldn't touch the switch going forward unless a given switch is stuck, and you need to manually turn it off.
- Note no direct connection exists between this Programming Board and the Main one since communication happens via the emitter/receiver.

### Rename Containers/Hubs (Optional)
- Works only for single item containers/hubs.
- Rename all containers/hubs as follows:
  - Containers: <prefix>_<itemId>
  - Hubs: <prefix>_<itemId>_<containserSize>_<amountOfContainers>
- Where:
  - <prefix>: the prefix that enable monitoring, by default MONIT, see options to customize it
  - <itemId>: The ID of the item in the game database, you can search the ID of item here: https://du-lua.dev/#/items
  - <containerSize>: if a hub, the size of the containers linked (default to XS), valid options are xs, s, m, l, xl, xxl
  - <amountOfContainers>: if a hub, the amount of containers linked

## Developer Notes
### Compile Project
- Install [du-luac](https://github.com/wolfe-labs/DU-LuaC).
- Clone the lib repo on [github](https://github.com/josecponce/du-lib).
- Either copy or symlink the `src` folder from the lib repo inside the `src` folder in this repo with the name `du_lib`.
- Compile using dua-lua: `du-lua build`