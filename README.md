# FS22_AnimalHelper

This mod allows you to easily fill up all levels for your animal husbandries. I started created this mod, because I found it a lot of effort to initialy fill up the husbandries after purchasing the animals. This is what the FS19 version of this mod does. Nothing less, nothing more. 

The FS22 version of the mod is changed to a more "permanent helper". The helper will tend to your animals daily at a fixed time (9 am). The helper will feed the animals, ride and clean your horses, top up the water and provide straw if needed.

## Costs
This mod uses the games economy to calculate prices for the food and straw used. Prices for training and cleaning the horses are (for now) fixed.

## FS19 Version
The FS19 version can be found in the FS19 branch. This version is no longer maintained.

## Usage
While playing, press LCtrl + LAlt + 9 (KeyBinding can be altered) to enable or disable the helpers. Press LCtrl + LAlt + 0 to open the settings dialog.

### Settings
You can alter some settings to adjust the mod to your desired gameplay wishes. The following settings can be altered (for now, list may change or expand):
* StartTime - The time the mod starts running and do its work
* FillStraw - Fill straw Yes/No. If you need slurry, you should not fill straw. See Issue  [#10](/../../issues/10), this might change in the future.
* DebugMode - Prints extra messages and runs helpers every hour instead of daily.

## History
Please refer to modDesc.xml for a complete changelog. The following releases are available:

* 01-2022 v22.0 - Updated mod to FS22. 
* 11-2020 v1.1.1 - Training of horses has been added.
* 11-2020 v1.1 - Scripts reworked to dynamically determine fillTypes to top up.
* xx-2018 v1.0 - Initial version

## Roadmap

The following features are planned to be implemented in a feature release:

1. Filling the different foodgroups with the different filltypes available, so you can reach a 100% productivity.
    1. Use the FillTypes available in your storage first to feed the animals. If no food is available, it will be bought.
    2. I will try to choose the filltype based on the price of the materials. The cheapest FillType will be the one used to fill the group.
2. Translation of the different messages/texts. (Help is appreciated)
3. By request: I'll try to use materials stored in your silos. If the food is available in the Silo, no costs will be calculated.
4. [#10](/../../issues/10) - Determine filling of straw yes/no by the availability of a Straw Pit

## Untested
I still have to test the mod. I cannot guarantee it will work errorfree. I played a bit with it for now, with only a few basic husbandries and it seems to work. But, as mentioned before, no guarantee can or wil be given this mod works correct. I hope to be able to test it some more soon.

## Multiplayer
For now, I have set Multiplayer support to false... I am not interested in multiplayer support, so this is untested.
Pull-Requests with changes allowing MultiPlayer support are welcome.

## Contibute
Like to contribute? Send a pull-request!
