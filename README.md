# fs19-HappyAnimalsMod

[[_TOC-]]

This mod allows you to easily fill up all levels for your animal husbandries. I created this mod, because I found it a lot of effort to initialy fill up the husbandries after purchasing the animals. Keeping them filled up thereafter is part of my game :-) Thats why its bound to keyInput instead of continuously filling op the husbandries.

## Usage

While playing, press Ctrl + Alt + 9 for a complete refill.
Mod fills foodTypes, water and straw for all AnimalTypes that come with FS19 (Cows, Pigs, Chicken, Horses, Sheep)

### Training horses

After you have used the helper at least once in this game-session, the "helper" will train you horses on day change.

## History

Please refer to modDesc.xml for a complete changelog. The following releases are available:

* xx-2018 v1.0 - Initial version
* 11-2020 v1.1 - Scripts reworked to dynamically determine fillTypes to top up.
* 11-2020 v1.1.1 - Training of horses has been added.

## Roadmap

The following features are planned to be implemented in a feature release:

1. Calculating costs for the different materials used.
1. Filling the different foodgroups with the different filltypes available.
    1. I will try to choose the filltype based on the price of the materials. The cheapest FillType will be the one used to fill the group.
    1. If the above bullet prooves too difficult, the FoodGroup will be filled, defided evenly over the different filltypes for this group.
1. Use the seasons-pricing module for calculating the costs of the materials.

## Untested

I still have to test the mod. I cannot guarantee it will work errorfree. I played a bit with it for now, with only two husbandries (Cows and horses) and it seems to work. But, as mentioned before, no guarantee can or wil be given this mod works correct. I hope to be able to test it some more soon.

## Multiplayer

For now, I have set Multiplayer support to false... I am not interested in multiplayer support, so this is untested.
Pull-Requests with changes allowing MultiPlayer support are welcome.

## Contibute

Like to contribute? Send a pull-request!
