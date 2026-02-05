# Pilot Academy: Ranks and Relations

This mod introduces the Pilot Academy, alloWing you to train pilots and improve faction relations through trade operations.

## Features

- **Intuitive UI**: Easily manage all Academy operations.
- **Pilot Training**: Train pilots effectively using trade operations.
- **Faction Relations**: Improve your standing with other factions through trade.
- **Wing Organization**: Organize your trainees into Wings for efficient management.
- **Goal Selection**: Prioritize either pilot training or improving relations.
- **Faction Limiting**: Restrict training and relation-building activities to specific factions for each Wing.
- **Researchable Upgrades**:
  - Expand to 9 Wings.
  - Train pilots up to the 5-star rank.
  - Automatically hire cadets from selected factions.
  - Automatically assign trained pilots to your ships based on priority.

## Limitations

- The Academy currently only supports small (S-class) ships.

## Requirements

- **X4: Foundations**: Version 8.00HF3 or newer.
- **UI Extensions and HUD**: Version 8.036 or higher by [kuertee](https://next.nexusmods.com/profile/kuertee?gameId=2659).
  - Available on Nexus Mods: [UI Extensions and HUD](https://www.nexusmods.com/x4foundations/mods/552)
- **Mod Support APIs**: Version 1.93 or higher by [SirNukes](https://next.nexusmods.com/profile/sirnukes?gameId=2659).
  - Available on Steam: [SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274)
  - Available on Nexus Mods: [Mod Support APIs](https://www.nexusmods.com/x4foundations/mods/503)

## Caution

This is a complex mod and may have undiscovered issues. Please report any problems on the Nexus Mods or Steam Workshop pages.

## Installation

- **Steam Workshop**: [Pilot Academy: Ranks and Relations](https://steamcommunity.com/sharedfiles/filedetails/?id=)
- **Nexus Mods**: [Pilot Academy: Ranks and Relations](https://www.nexusmods.com/x4foundations/mods/)

## Training procedure

- After the location of `Academy` is set, player will have possibility to create a first `Wing`.
- When `Wing` is created any count of `Wingmans` can be added to the `Wing`.
- Immediately after `Wing` creation the special order will search for the best deal to grow in rank and relation.
- Every turn after sell the current rank of each pilots will be checked against a target level.
- If rank is reached the presence of `Cadets` on an `Academy` station will be checked, and first candidate will be transferred on a ship.
- If no `Cadets` detected, the `Auto Hire` option will be checked, and if it is enable - the new `Cadet` will be hared to a ship with paying out appropriate fee.
- If no `Cadets` available and no `Auto Hire` is enabled - script will repeat these checks in 3 minutes.
- Otherwise the pilot on a ship will be swapped with cadet, and then moved to the `Academy` station.
- In case of `Assign` option is not  set to `manual`, and if last assign turn was finished at least 2 minutes ago - the `Auto assign` procedure will be initiated.
- Based on a setting for the `Assign` will be selected ship with a pilot who has a loves rank (and below target rank level)
- If such ship will be found, the `Trained Pilot` will be assigned as a pilot, and existing pilot will be transferred to an `Academy` station as a new `Cadet`.
- Every 3 minutes the `Auto Assign` procedure will be repeat to check for existing `Trained Pilots`.

## Usage

After installation, a new icon will appear on the left menu panel. Clicking it opens the `Academy` management window.

There are three type of tabs on an `Academy` window:

- `Academy Settings`;
- `Cadets and Pilots`;
- Wings management tabs, including `Add new Wing`.

### Academy Settings tab

The `Academy settings` tab includes controls for location, target skill level, auto-hiring, and auto-assigning pilots.

![Academy settings tab shoWing location selection, target skill level slider, and auto-hire/auto-assign controls.](docs/images/initial_screen.png)

#### Academy Location

The `Academy` uses an assigned player-owned or other faction's owned station as living quarters for cadets and pilots.

In the early game, when you may not own any station, you can use other factions' wharfs, shipyards, or trading stations, depending on your reputation with them.

![Locations dropdown displaying available stations from other factions.](docs/images/locations_other_factions.png)

You can choose any available station.

![Other faction station selection with rental cost information.](docs/images/selected_location_other_faction.png)

If you use another faction's station, you will be charged a daily rental fee.

If you own any stations, other factions' stations will not appear in the location list.

![Locations menu filtered to show only player-owned stations.](docs/images/locations_player_owned.png)

You can select any of your own stations, though using the HQ is not recommended to avoid interference with terraforming projects.

![Selected player-owned station.](docs/images/selected_location_player_owned.png)

##### Resetting the Academy location

At any type player can reset the `Academy` location, by pressing the button with current station info and then new station can be selected from dropdown.
After pressing the `Update` button location will be changed and `Cadets` and `Trained Pilots` will be moved to a new station with `Academy`.

#### Auto Hire Cadets

After completing the appropriate research, you can enable the auto hire feature.

![Auto-hire configuration screen with faction selection checkboxes to automatically recruit new cadets.](docs/images/auto_hire_options.png)

This will automatically hire new cadets from the selected factions, and you will be charged the standard hiring fees.

#### Auto Assign Trained Pilots

Once researched, you can enable auto assign in the `Academy` interface. This allows you to set priorities for assigning pilots who have reached the target rank, based on ship role and size.

![Auto-assign settings panel with ship class filters and priority options to automatically deploy trained pilots to the player's fleet.](docs/images/auto_assign_options.png)

When auto assign is active, trained pilots will replace existing pilots on your ships who have a lower rank than the target. The replaced pilots will be reassigned to the `Academy` as cadets.

### Cadets and Pilots

This tab displays a list of your cadets and trained pilots. Initially, both lists will be empty.

![Cadets and Pilots tab shoWing empty cadet and pilot rosters.](docs/images/personnel_initial_screen.png)

#### Hiring Cadets

You can manually hire cadets in two ways:

- From the global Personnel Management screen.

  ![Hiring cadets from the Personnel Management screen.](docs/images/appoint_as_cadet_from_personnel.png)

- From the crew tab of your existing ships.

  ![Hiring cadets from another player ship.](docs/images/appoint_as_cadet_from_crew.png)

Use the `Appoint as cadet` option in the context menu.

Cadets will take some time to transfer from their original location and will be grayed out while in transit.

![Example of a cadet list.](docs/images/personnel_with_cadets.png)

You can also use the context menu to manage them like any other employee.

![Personnel context menu.](docs/images/personnel_context_menu.png)

#### Managing Trained Pilots

If auto-assign is not used, trained pilots will return to the `Academy`.

![List of trained pilots.](docs/images/personnel_with_pilots.png)

You can then manage them in the same way as cadets.

### Wings

All training functionality of the `Academy` itself is based on a `Wings`. Each `Wing` can contain any amount of `Wingmans`. I.e. you have to select one ship as `Wing Leader` and then add to it any number of direct subordinates with `Mimic` directive.

Initially you can manage 3 Wings. To increase count of available Wings you have to finish appropriate research.

To start - lets open `Add new Wing` tab.

#### Add new Wing

![Add new Wing.](docs/images/create_wing_initial_screen.png)

##### Primary Goal

At first you have to select a `Primary Goal` for the exact `Wing`:

- `Increase Rank` - i.e. work with any faction to make as many as possible trade turns  in time;
- `Gain Reputation` - to make a deals with specific factions to focus on increasing reputations with them.

![Primary Goal selection dropdown.](docs/images/create_wing_select_goal.png)

##### Trade data refresh interval

As situation on a marlin is not stale, to be most effective in training, `Wing commander` have to re-check the market data. You can set most appropriate for you value, from 5 minutes to one hour.

![Trade data refresh interval selection dropdown.](docs/images/create_wing_trade_refresh_interval.png)

##### Wing Leader selection

And there is a main part of `Wing` creation - selection of the `Wing Leader` - simple use the appropriate dropdown, which will display to you all your unassigned S-class ships, sorted by they `pilots` ranks.

![Wing Leader selection dropdown.](docs/images/create_wing_select_wing_leader.png)

##### Create the Wing

Simple press the `Create` button to finalize `Wing` adding process.

#### Wing management tab

Immediately after `Wing` creation the current tab focus will be swithed on that newly created `Wing`. For the first one it will be `Alpha`.

![Wing Alpha details after creation.](docs/images/wing_alpha_after_creation.png)

##### Add Wingman's

You can add any number of `Wingmans` to the existing `Wing` at any time on appropriate `Wing ...` tab using the `Add Wingman` dropdown.

![Add Wingman dropdown.](docs/images/wing_alpha_add_wingman.png)

Note: It is require several seconds to reflect added `Wingman` in a `Wingmans` list after selection via dropdown.

![Wing Alpha tab with Wing Leader and assigned Wingman.](docs/images/wing_alpha_with_wingman.png)

##### Wing Leader and Wingman's Context Menus and Hotkey.

You can use standard `I` key (or other, depending on your settings) to open `Information` window in case if `Wing Leader` or `Wingman` is selected on `Wing` tab.

The same action is available via `Context menu`

![Context menu for a Wing Leader.](docs/images/wing_leader_context_menu.png)

For `Wingman` in addition is available `Remove Assignment` action.

![Context menu for a Wingman.](docs/images/wingman_context_menu.png)

### Research

Previously mentioned researchable upgrades are available in the standard `Research` interface under the `Pilot Academy RnR` groups of researches:

- `Pilot Academy: R&R. Five wings`: Extends the `Academy` capacity to support five wings;
- `Pilot Academy: R&R. Nine wings`: Extends the `Academy` capacity to support nine wings;
- `Pilot Academy: R&R. 3-star pilots`: Allows training of 3-star pilots in the Academy;
- `Pilot Academy: R&R. 4-star pilots`: Allows training of 4-star pilots in the Academy;
- `Pilot Academy: R&R. 5-star pilots`: Allows training of 5-star pilots in the Academy;
- `Pilot Academy: R&R. Auto hire`: Adds possibility to automate cadet hiring from desired factions;
- `Pilot Academy: R&R. Auto assign`: Adds possibility to automate pilot assignment to ships outside the Academy.

![Group of Academy features upgrade researches.](docs/images/researches.png)

### Options

In addition there is an options menu available via `Extension Options` menu, where you can configure the current debug level for the mod. By default it is set to `No debug`.

![Extension options menu with Academy item.](docs/images/extension_options.png)
![Academy Options with Debug level dropdown.](docs/images/debug_level.png)

### Notifications

There are several notifications implemented to keep you informed about important events related to the `Academy` operations. They are will be shown in the standard notifications area (ticker):

- When a pilot finished training as has reached the target rank the "Pilot %s has reached the target skill level %s." will be shown

  ![Notification: "Pilot has reached a new rank."](docs/images/notifications_pilot_reached_rank.png)

- When no free cadets are available at the academy to replace trained pilot appropriate warning "No free cadets available for pilots swapping!" will be shown.

  ![Notification: "No free cadets available at academy."](docs/images/notifications_no_free_cadets_at_academy.png)

- If new cadet will be hired, appropriate information will be show "Cadet %s has been hired for %s {1001,101}."

- In case of no free space on a ship to transfer `Cadet` identified then the "No free crew capacity on %s to do pilot swapping!" warning will be shown.

- When a new cadet is assigned to a Wing the "Cadet %s assigned as pilot on %s." will be shown

  ![Notification: "Cadet has been assigned to a Wing."](docs/images/notifications_cadet_assigned.png)

- When a trained pilot is moved back to the academy the "Pilot %s has been moved back to Academy. You can now assign them to any new task." notification will arrive to a ticker.

  ![Notification: "Trained pilot has been moved back to the academy."](docs/images/notifications_pilot_moved_back.png)

- With `Auto Assign` when `Trained Pilot` will arrive on a new ship player will see a message "Pilot %s assigned as a new pilot on %s."
- And after moving the "old" onw to an `Academy" player will be notified with "Pilot %s appointed as new Academy cadet."

- In case of an errors in `Cadets` and `Trained Pilots` transfers and swaps several warning messages will be displayed:

 - "Can't perform pilot swapping on %s! Please do it manually!"
 - "Can't return pilot %s to the Academy! Please do it manually!"
 - "No free capacity at Academy to return pilot %s! Please resolve it!"
 - "Can't move new pilot %s to %s!"
  
- And hoping that warning will not be displayed - "Can't assign Academy training order on wing %s with leader ship %s! Please report the issue!"

## Video

[Video demonstration of the mod (Version 1.00)](https://www.youtube.com/watch?v=)

## Credits

- **Author**: Chem O`Dun, on [Nexus Mods](https://next.nexusmods.com/profile/ChemODun/mods?gameId=2659) and [Steam Workshop](https://steamcommunity.com/id/chemodun/myworkshopfiles/?appid=392160)
- *"X4: Foundations"* is a trademark of [Egosoft](https://www.egosoft.com).

## Acknowledgements

- [EGOSOFT](https://www.egosoft.com) — for the X series.
- [kuertee](https://next.nexusmods.com/profile/kuertee?gameId=2659) — for the `UI Extensions and HUD` that makes this extension possible.
- [SirNukes](https://next.nexusmods.com/profile/sirnukes?gameId=2659) — for the `Mod Support APIs` that power the UI hooks.

## Changelog

### [1.00] - 2024-02-10

- **Added**
  - Initial public version
