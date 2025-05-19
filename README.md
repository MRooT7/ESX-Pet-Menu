# 🐾 FiveM Advanced Pet System

[Download](https://github.com/MRooT7/ESX-Pet-Menu/releases/tag/fivem)

A complete pet management system for FiveM servers, featuring realistic pet behaviors and full ESX integration.

![Pet System Demo]([https://i.imgur.com/example.jpg](https://cdn.discordapp.com/attachments/721323255146741762/1373876628865941554/image.png?ex=682c01d1&is=682ab051&hm=acd716d92b15ceeb86d99d01af52c7fe27a801b2d1baed27c80e550cf8389251&))

## Features

- 🐶 **15+ Preconfigured Pets** (Dogs, cats, lions, birds, and more)
- 🛒 **Item-Based Ownership** (Requires collar items)
- 🏎️ **Vehicle Support** (Pets automatically enter/exit vehicles)
- ⚡ **Optimized Performance** (Efficient pet handling)

## Installation

1. Download the latest release
2. Extract to your `resources` folder
3. Import `petsystem.sql` to your database
4. Configure `config.lua` to your needs
5. Add `start fivem-petsystem` to your server.cfg

## Dependencies

- [ESX Framework](https://github.com/esx-framework/esx_core)
- esx_menu_default
- MySQL Database

## Configuration

```lua
Config = {}

-- SHARED SETTINGS --
Config.MenuKey = 'F7' -- Key to open pet menu (both client/server)

-- Pet type to item collar mapping (server-side)
Config.PetItems = {
    cat = 'cat_collar',
    dog = 'dog_collar',
    rabbit = 'rabbit_collar',
    cow = 'cow_collar',
    deer = 'deer_collar',
    pig = 'pig_collar',
    lion = 'lion_collar',
    rat = 'rat_collar',
    chicken = 'chicken_collar',
    crow = 'crow_collar',
    pigeon = 'pigeon_collar',
    seagull = 'seagull_collar',
    chimp = 'monkey_collar'
}

-- Pet type to model mapping (client-side)
Config.PetModels = {
    cat = 'a_c_cat_01',
    dog = 'a_c_shepherd',
    rabbit = 'a_c_rabbit_01',
    cow = 'a_c_cow',
    deer = 'a_c_deer',
    pig = 'a_c_pig',
    lion = 'a_c_mtlion',
    rat = 'a_c_rat',
    chicken = 'a_c_hen',
    crow = 'a_c_crow',
    pigeon = 'a_c_pigeon',
    seagull = 'a_c_seagull',
    chimp = 'a_c_chimp'
}
