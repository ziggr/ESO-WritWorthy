-- Parse a food or dring request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Provisioning = {
    RECIPES = nil     -- lazy-loaded in LoadData()
,   savedVarVersion = 2
}

local Provisioning = WritWorthy.Provisioning
local Util         = WritWorthy.Util
local Fail         = WritWorthy.Util.Fail
-- So it turns out that GetRecipeInfo() and related APIs only return data
-- if the current character knows that recipe. So we have to hardcode our
-- own 40KB copy of ZOS's table if we want to return useful data when showing
-- tooltips for any recipe we do not yet know.

                        -- Flag to generate Provisioning.COMPRESSED table.
                        -- Normally false. True causes a call to
                        -- SaveRecipeList()
Provisioning.ZZ_SAVE_DATA = false

                        -- Table from saved variables when above ZZ_SAVE_DATA
                        -- is true. Recipe:Compressed() strings for all 554
                        -- recipes ### Except the 3 that I'm still missing ###
Provisioning.COMPRESSED = {
  "33526\t1\t1\tFishy Stick\tfish\t1"
, "28358\t1\t2\tRoast Pig\twhite meat\t1"
, "33819\t1\t3\tChicken Breast\tpoultry\t1"
, "42804\t1\t4\tFlank Steak\tred meat\t1"
, "28289\t1\t5\tRoast Venison\tgame\t1"
, "28362\t1\t6\tGrilled Hare\tsmall game\t1"
, "28334\t1\t7\tRabbit Pasty\tflour\t1\tsmall game\t1"
, "28301\t1\t8\tTarragon Chicken\tseasoning\t1\tpoultry\t1"
, "28374\t1\t9\tHunter's Pie\tgame\t1\tsaltrice\t1"
, "33849\t1\t10\tStir-Fried Garlic Beef\tgarlic\t1\tred meat\t1"
, "28313\t1\t11\tRabbit Millet Pilaf\tmillet\t1\tsmall game\t1"
, "28386\t1\t12\tPan-Fried Trout\tflour\t1\tfish\t1"
, "28342\t1\t13\tBreton Pork Sausage\twhite meat\t1\tseasoning\t1"
, "33484\t1\t14\tWhiterun Cheese-Baked Trout\tcheese\t1\tfish\t1"
, "28398\t1\t15\tVenison Pasty\tgame\t1\tflour\t1"
, "33861\t1\t16\tCheese Pork Schnitzel\twhite meat\t1\tcheese\t1"
, "33502\t1\t17\tSalted Cod\tseasoning\t1\tfish\t1"
, "33563\t1\t18\tChicken and Biscuits\tmillet\t1\tpoultry\t1"
, "28350\t1\t19\tSenchal Curry Fish and Rice\tsaltrice\t1\tfish\t1"
, "33520\t1\t20\tElinhir Roast Antelope\tgame\t1\tmillet\t1"
, "33581\t1\t21\tHare in Garlic Sauce\tgarlic\t1\tsmall game\t1"
, "33873\t1\t22\tCamlorn Pork Sausage\twhite meat\t1\tgarlic\t1"
, "33885\t1\t23\tCrispy Cheddar Chicken\tcheese\t1\tpoultry\t1"
, "33801\t1\t24\tBruma Jugged Rabbit\tseasoning\t1\tsmall game\t1"
, "33903\t1\t25\tMammoth Snout Pie\tflour\t1\tred meat\t1"
, "57085\t1\t26\tRabbit Haunch with Cheese Grits\tcheese\t1\tsmall game\t1"
, "57088\t1\t27\tStros M'Kai Grilled Seagull\tgarlic\t1\tpoultry\t1"
, "33921\t1\t28\tSolstheim Elk and Scuttle\tgame\t1\tcheese\t1"
, "57098\t1\t29\tBlacklight Oxen Meatballs\tsaltrice\t1\tred meat\t1"
, "57101\t1\t30\tAkaviri Pork Fried Rice\twhite meat\t1\tsaltrice\t1"
, "43088\t1\t31\tMillet-Stuffed Pork Loin\twhite meat\t1\tmillet\t1"
, "57111\t1\t32\tCurried Kwama Scrib Risotto\tsaltrice\t1\tpoultry\t1"
, "57114\t1\t33\tGrilled Timber Mammoth Kebabs\tseasoning\t1\tred meat\t1"
, "43142\t1\t34\tArgonian Saddle-Cured Rabbit\tsaltrice\t1\tsmall game\t1"
, "57123\t1\t35\tKwama Egg Quiche\tflour\t1\tpoultry\t1"
, "57126\t1\t36\tDunmeri Jerked Horse Haunch\tgame\t1\tseasoning\t1"
, "57135\t1\t37\tThe Skald-King's Patty Melt\tcheese\t1\tred meat\t1"
, "57136\t1\t38\tOrcish Bratwurst on Bun\twhite meat\t1\tflour\t1"
, "57137\t1\t39\tCrawdad Quiche\tmillet\t1\tfish\t1"
, "68233\t1\t40\tGarlic-and-Pepper Venison Steak\tgame\t1\tgarlic\t1"
, "68234\t1\t41\tMillet and Beef Stuffed Peppers\tmillet\t1\tred meat\t1"
, "68235\t1\t42\tLilmoth Garlic Hagfish\tgarlic\t1\tfish\t1"
, "33837\t2\t1\tBaked Apples\tapples\t1"
, "28281\t2\t2\tBanana Surprise\tbananas\t1"
, "33825\t2\t3\tGrape Preserves\tjazbay grapes\t1"
, "33843\t2\t4\tMelon Jelly\tmelon\t1"
, "28293\t2\t5\tTomato Soup\ttomato\t1"
, "28366\t2\t6\tPumpkin Puree\tpumpkin\t1"
, "42807\t2\t7\tPumpkin Cheesecake\tcheese\t1\tpumpkin\t1"
, "28305\t2\t8\tBanana Millet Muffin\tmillet\t1\tbananas\t1"
, "28378\t2\t9\tBravil Melon Salad\tgarlic\t1\tmelon\t1"
, "33855\t2\t10\tDeshaan Honeydew Hors d'Ouevre\tsaltrice\t1\tmelon\t1"
, "28317\t2\t11\tFried Green Tomatoes\tseasoning\t1\ttomato\t1"
, "28390\t2\t12\tStuffed Grape Leaves\tmillet\t1\tjazbay grapes\t1"
, "42814\t2\t13\tPellitine Tomato Rice\tsaltrice\t1\ttomato\t1"
, "33490\t2\t14\tGarlic Pumpkin Seeds\tgarlic\t1\tpumpkin\t1"
, "33552\t2\t15\tRedoran Peppered Melon\tseasoning\t1\tmelon\t1"
, "33867\t2\t16\tCinnamon Gorapples\tseasoning\t1\tapples\t1"
, "33508\t2\t17\tCantaloupe Bread\tflour\t1\tmelon\t1"
, "33569\t2\t18\tGreen Bananas with Garlic\tgarlic\t1\tbananas\t1"
, "42790\t2\t19\tCinnamon Grape Jelly\tseasoning\t1\tjazbay grapes\t1"
, "33789\t2\t20\tCyrodilic Pumpkin Fritters\tmillet\t1\tpumpkin\t1"
, "33587\t2\t21\tStormhold Baked Bananas\tcheese\t1\tbananas\t1"
, "33879\t2\t22\tClan Mother's Banana Pilaf\tsaltrice\t1\tbananas\t1"
, "57083\t2\t23\tRimmen Raisin Cookies\tflour\t1\tjazbay grapes\t1"
, "33891\t2\t24\tApple Cobbler Supreme\tflour\t1\tapples\t1"
, "33909\t2\t25\tSkyrim Jazbay Crostata\tsaltrice\t1\tjazbay grapes\t1"
, "57086\t2\t26\tKragenmoor Pickled Pumpkin\tseasoning\t1\tpumpkin\t1"
, "57087\t2\t27\tSummer Sundas Soup\tmillet\t1\ttomato\t1"
, "33927\t2\t28\tMelon-Chevre Salad\tcheese\t1\tmelon\t1"
, "57099\t2\t29\tMage's Gorapple Porridge\tmillet\t1\tapples\t1"
, "57100\t2\t30\tMistral Banana Bread\tflour\t1\tbananas\t1"
, "43094\t2\t31\tOrcrest Garlic Apple Jelly\tgarlic\t1\tapples\t1"
, "57112\t2\t32\tHag Fen Pumpkin Pie\tflour\t1\tpumpkin\t1"
, "57113\t2\t33\tOrdinator's Beetle-Cheese Soup\tcheese\t1\ttomato\t1"
, "43154\t2\t34\tFresh Apples and Eidar Cheese\tcheese\t1\tapples\t1"
, "57124\t2\t35\tCombwort Flatbread\tflour\t1\ttomato\t1"
, "57125\t2\t36\tHoney Nut Treat\tmillet\t1\tmelon\t1"
, "57138\t2\t37\tHouse Hlaalu Pumpkin Risotto\tsaltrice\t1\tpumpkin\t1"
, "57139\t2\t38\tBananas in Moon-Sugar Syrup\tseasoning\t1\tbananas\t1"
, "57140\t2\t39\tGarlic Guar Stuffed Grape Leaves\tgarlic\t1\tjazbay grapes\t1"
, "68236\t2\t40\tFirsthold Fruit and Cheese Plate\tcheese\t1\tjazbay grapes\t1"
, "68237\t2\t41\tThrice-Baked Gorapple Pie\tsaltrice\t1\tapples\t1"
, "68238\t2\t42\tTomato Garlic Chutney\tgarlic\t1\ttomato\t1"
, "28321\t3\t1\tCarrot Soup\tcarrots\t1"
, "28354\t3\t2\tBaked Potato\tpotato\t1"
, "33813\t3\t3\tRoast Corn\tcorn\t1"
, "28325\t3\t4\tSteamed Radishes\tradish\t1"
, "33358\t3\t5\tBorscht\tbeets\t1"
, "33831\t3\t6\tGreen Salad\tgreens\t1"
, "28330\t3\t7\tCarrot Cheesecake\tcheese\t1\tcarrots\t1"
, "28297\t3\t8\tGilane Garlicky Greens\tgarlic\t1\tgreens\t1"
, "28370\t3\t9\tRadishes in Rice\tradish\t1\tsaltrice\t1"
, "42811\t3\t10\tBalmora Cabbage Biscuits\tflour\t1\tgreens\t1"
, "28309\t3\t11\tSpicy Beet Salad\tbeets\t1\tseasoning\t1"
, "28382\t3\t12\tPort Hunding Cheese Fries\tcheese\t1\tpotato\t1"
, "28338\t3\t13\tAlik'r Beets with Goat Cheese\tbeets\t1\tcheese\t1"
, "33478\t3\t14\tNibenese Garlic Carrots\tgarlic\t1\tcarrots\t1"
, "28394\t3\t15\tBattaglir Chowder\tmillet\t1\tgreens\t1"
, "42784\t3\t16\tRihad Beet and Garlic Salad\tbeets\t1\tgarlic\t1"
, "33496\t3\t17\tEidar Radish Salad\tradish\t1\tcheese\t1"
, "33557\t3\t18\tPotato Rice Blintzes\tsaltrice\t1\tpotato\t1"
, "28346\t3\t19\tGarlic Mashed Potatoes\tgarlic\t1\tpotato\t1"
, "33514\t3\t20\tChorrol Corn on the Cob\tcorn\t1\tseasoning\t1"
, "33575\t3\t21\tJerall View Inn Carrot Cake\tflour\t1\tcarrots\t1"
, "42796\t3\t22\tRoasted Beet and Millet Salad\tbeets\t1\tmillet\t1"
, "33795\t3\t23\tTwice-Baked Potatoes\tseasoning\t1\tpotato\t1"
, "33593\t3\t24\tIndoril Radish Tartlets\tradish\t1\tflour\t1"
, "33897\t3\t25\tCyrodilic Cornbread\tcorn\t1\tflour\t1"
, "57089\t3\t26\tCheesemonger's Salad\tcheese\t1\tgreens\t1"
, "57090\t3\t27\tToasted Millet Salad\tradish\t1\tmillet\t1"
, "33915\t3\t28\tVvardenfell Ash Yam Loaf\tflour\t1\tpotato\t1"
, "57102\t3\t29\tSavory Thorn Cornbread\tcorn\t1\tsaltrice\t1"
, "57103\t3\t30\tDragonstar Radish Kebabs\tradish\t1\tseasoning\t1"
, "32160\t3\t31\tWest Weald Corn Chowder\tcorn\t1\tmillet\t1"
, "57115\t3\t32\tBaby Carrots in Moon-Sugar Glaze\tseasoning\t1\tcarrots\t1"
, "57116\t3\t33\tVelothi Cabbage Soup\tsaltrice\t1\tgreens\t1"
, "43124\t3\t34\tPickled Carrot Slurry\tsaltrice\t1\tcarrots\t1"
, "57127\t3\t35\tSkingrad Cabbage Soup\tseasoning\t1\tgreens\t1"
, "57128\t3\t36\tGarlic Radishes a la Kvatch\tradish\t1\tgarlic\t1"
, "57141\t3\t37\tTaneth Chili Cheese Corn\tcorn\t1\tcheese\t1"
, "57142\t3\t38\tThe Secret Chef's Beet Crostata\tbeets\t1\tflour\t1"
, "57143\t3\t39\tNord Warrior Potato Porridge\tmillet\t1\tpotato\t1"
, "68239\t3\t40\tHearty Garlic Corn Chowder\tcorn\t1\tgarlic\t1"
, "68240\t3\t41\tBravil's Best Beet Risotto\tbeets\t1\tsaltrice\t1"
, "68241\t3\t42\tTenmar Millet-Carrot Couscous\tmillet\t1\tcarrots\t1"
, "28348\t4\t1\tMelon Carpaccio\tmelon\t1\tred meat\t1"
, "28299\t4\t2\tRed Deer Stew\tgame\t1\ttomato\t1"
, "28373\t4\t3\tPunkin Bunny\tpumpkin\t1\tsmall game\t1"
, "28360\t4\t4\tApple Baked Fish\tapples\t1\tfish\t1"
, "28311\t4\t5\tMonkeypig Cutlets\twhite meat\t1\tbananas\t1"
, "28385\t4\t6\tGrape-Glazed Bantam Guar\tjazbay grapes\t1\tpoultry\t1"
, "42808\t4\t7\tPeacock Pie\tpoultry\t1\tflour\t1\tjazbay grapes\t1"
, "33480\t4\t8\tYellow Oxen Loaf\tmillet\t1\tbananas\t1\tred meat\t1"
, "28397\t4\t9\tArgonian Pumpkin Stew\tsaltrice\t1\tpumpkin\t1\tfish\t1"
, "42793\t4\t10\tColovian Roast Turkey\tpoultry\t1\tmillet\t1\ttomato\t1"
, "33505\t4\t11\tPork and Bitter Melon\twhite meat\t1\tmelon\t1\tsaltrice\t1"
, "33567\t4\t12\tBaked Sole with Bananas\tflour\t1\tbananas\t1\tfish\t1"
, "33846\t4\t13\tPumpkin-Stuffed Fellrunner\tsaltrice\t1\tpoultry\t1\tpumpkin\t1"
, "33523\t4\t14\tRedguard Venison Pie\ttomato\t1\tgame\t1\tflour\t1"
, "33585\t4\t15\tParmesan Eels in Watermelon\tmelon\t1\tcheese\t1\tfish\t1"
, "33864\t4\t16\tVenison Stuffed Grape Leaves\tsaltrice\t1\tjazbay grapes\t1\tgame\t1"
, "33804\t4\t17\tAunt Alessia's Pork Chops\twhite meat\t1\ttomato\t1\tgarlic\t1"
, "33889\t4\t18\tMinotaur Slumgullion\tmillet\t1\tpumpkin\t1\tred meat\t1"
, "43158\t4\t19\tBlack Marsh Wamasu Loin\tseasoning\t1\tjazbay grapes\t1\tred meat\t1"
, "57092\t4\t20\tChicken-and-Banana Fried Rice\tsaltrice\t1\tpoultry\t1\tbananas\t1"
, "57093\t4\t21\tMother Mara's Savory Rabbit Stew\ttomato\t1\tgarlic\t1\tsmall game\t1"
, "33913\t4\t22\tOyster Tomato Orzo\tsaltrice\t1\ttomato\t1\tfish\t1"
, "57105\t4\t23\tGazelle Cutlet with Minced Pumpkin\tseasoning\t1\tgame\t1\tpumpkin\t1"
, "57106\t4\t24\tElsweyr Fondue\tmelon\t1\tcheese\t1\tred meat\t1"
, "33931\t4\t25\tAshlander Nix-Hound Chili\twhite meat\t1\tgarlic\t1\tpumpkin\t1"
, "57118\t4\t26\tSeared Slaughterfish with Mammoth Cheese\tjazbay grapes\t1\tcheese\t1\tfish\t1"
, "57119\t4\t27\tColovian Beef Noodle Soup\ttomato\t1\tflour\t1\tred meat\t1"
, "43097\t4\t28\tKhajiiti Sweet-Stuffed Duck\tpoultry\t1\tcheese\t1\tbananas\t1"
, "57130\t4\t29\tCloudy Dregs Inn Bouillabaisse\ttomato\t1\tflour\t1\tfish\t1"
, "57131\t4\t30\tCorinthean Roast Kagouti\tmillet\t1\tapples\t1\tred meat\t1"
, "57144\t4\t31\tSweet Horker Stew\tsaltrice\t1\tjazbay grapes\t1\tred meat\t1"
, "57145\t4\t32\tLillandril Summer Sausage\twhite meat\t1\tmelon\t1\tseasoning\t1"
, "57146\t4\t33\tColdharbour Daedrat Snacks\tgarlic\t1\tapples\t1\tsmall game\t1"
, "68242\t4\t34\tMistral Banana-Bunny Hash\tseasoning\t1\tbananas\t1\tsmall game\t1"
, "68243\t4\t35\tMelon-Baked Parmesan Pork\twhite meat\t1\tmelon\t1\tcheese\t1"
, "68244\t4\t36\tSolitude Salmon-Millet Soup\ttomato\t1\tmillet\t1\tfish\t1"
, "28353\t5\t1\tSalmon with Radish Slaw\tradish\t1\tfish\t1"
, "28304\t5\t2\tBeet-Glazed Pork\twhite meat\t1\tbeets\t1"
, "33403\t5\t3\tStuffed Capon\tcorn\t1\tpoultry\t1"
, "33528\t5\t4\tBeef Stew\tcarrots\t1\tred meat\t1"
, "28316\t5\t5\tShepherd's Pie\tgame\t1\tpotato\t1"
, "33409\t5\t6\tRabbit Loin with Bitter Greens\tgreens\t1\tsmall game\t1"
, "33537\t5\t7\tStuffed Venison Haunch\tcheese\t1\tgame\t1\tgreens\t1"
, "33487\t5\t8\tRabbit Gnocchi Ragu\tflour\t1\tpotato\t1\tsmall game\t1"
, "33416\t5\t9\tBeef and Beets Pasty\tmillet\t1\tbeets\t1\tred meat\t1"
, "42786\t5\t10\tFalkreath Meat Loaf\tcheese\t1\tgame\t1\tcarrots\t1"
, "33498\t5\t11\tHighland Rabbit Stew\tmillet\t1\tgreens\t1\tsmall game\t1"
, "33560\t5\t12\tHunt-Wife's Beef Radish Stew\tradish\t1\tseasoning\t1\tred meat\t1"
, "33839\t5\t13\tShornhelm Ox-Tail Soup\tmillet\t1\tcarrots\t1\tred meat\t1"
, "33516\t5\t14\tFrostfall Pork Roast\tradish\t1\tseasoning\t1\twhite meat\t1"
, "33578\t5\t15\tRabbit Corn Chowder\tcorn\t1\tsaltrice\t1\tsmall game\t1"
, "33857\t5\t16\tFricasseed Rabbit with Radishes\tradish\t1\tseasoning\t1\tsmall game\t1"
, "33797\t5\t17\tNarsis Bantam Guar Hash\tsaltrice\t1\tpoultry\t1\tbeets\t1"
, "33596\t5\t18\tMudcrab Corn Fritters\tcorn\t1\tgarlic\t1\tfish\t1"
, "43092\t5\t19\tNecrom Beetle-Cheese Poutine\tcheese\t1\tgame\t1\tpotato\t1"
, "57091\t5\t20\tRumare Slaughterfish Pie\tflour\t1\tgreens\t1\tfish\t1"
, "57094\t5\t21\tPsijic Order Pigs-in-a-Blanket\tcorn\t1\tmillet\t1\twhite meat\t1"
, "33906\t5\t22\tAsh-Hopper Dumplings on Scathecraw\tpoultry\t1\tflour\t1\tgreens\t1"
, "57104\t5\t23\tCraglorn Skavenger Stew\tmillet\t1\tcarrots\t1\tsmall game\t1"
, "57107\t5\t24\tRaven Rock Baked Ash Yams\twhite meat\t1\tsaltrice\t1\tpotato\t1"
, "33924\t5\t25\tGrilled Camel on Cornbread\tcorn\t1\tmillet\t1\tgame\t1"
, "57117\t5\t26\tPotato-Stuffed Roast Pheasant\tsaltrice\t1\tpoultry\t1\tpotato\t1"
, "57120\t5\t27\tGoblin-Style Grilled Rat\tseasoning\t1\tbeets\t1\tsmall game\t1"
, "33900\t5\t28\tGrandmam's Roast Rabbit\tsaltrice\t1\tcarrots\t1\tsmall game\t1"
, "57129\t5\t29\tWild-Boar-and-Beets\twhite meat\t1\tbeets\t1\tseasoning\t1"
, "57132\t5\t30\tHammerfell Antelope Stew\tradish\t1\tgarlic\t1\tgame\t1"
, "57147\t5\t31\tKwama Egg Omelet\tpoultry\t1\tcheese\t1\tcarrots\t1"
, "57148\t5\t32\tBreton Bubble-and-Squeak\tflour\t1\tgame\t1\tgreens\t1"
, "57149\t5\t33\tSilverside Perch Pudding\tmillet\t1\tbeets\t1\tfish\t1"
, "68245\t5\t34\tSticky Pork and Radish Noodles\tradish\t1\tflour\t1\twhite meat\t1"
, "68246\t5\t35\tGarlic Cod with Potato Crust\tgarlic\t1\tpotato\t1\tfish\t1"
, "68247\t5\t36\tBraised Rabbit with Spring Vegetables\tseasoning\t1\tgreens\t1\tsmall game\t1"
, "28357\t6\t1\tLast Seed Salad\tcarrots\t1\tapples\t1"
, "28308\t6\t2\tSweet Potatoes\tpotato\t1\tbananas\t1"
, "33405\t6\t3\tMid Year Green Salad\tgreens\t1\tjazbay grapes\t1"
, "33531\t6\t4\tMelon-Radish Salad\tradish\t1\tmelon\t1"
, "28320\t6\t5\tTomato Borscht\tbeets\t1\ttomato\t1"
, "33411\t6\t6\tPumpkin Corn Fritters\tcorn\t1\tpumpkin\t1"
, "33540\t6\t7\tFalinesti Forbidden Fruit\tradish\t1\tmelon\t1\tseasoning\t1"
, "33493\t6\t8\tHearthfire Harvest Pilaf\tcorn\t1\tsaltrice\t1\tapples\t1"
, "33555\t6\t9\tHearty Sun's Dusk Soup\ttomato\t1\tgarlic\t1\tcarrots\t1"
, "42799\t6\t10\tHearthfire Vegetable Salad\tsaltrice\t1\tbeets\t1\tpumpkin\t1"
, "33511\t6\t11\tApple Mashed Potatoes\tgarlic\t1\tpotato\t1\tapples\t1"
, "33573\t6\t12\tElsweyr Corn Fritters\tcorn\t1\tjazbay grapes\t1\tflour\t1"
, "33852\t6\t13\tSun's Height Pudding\tgarlic\t1\tbeets\t1\tbananas\t1"
, "42759\t6\t14\tApple-Eidar Cheese Salad\tcheese\t1\tgreens\t1\tapples\t1"
, "33591\t6\t15\tSweet Dune Gnocchi\tjazbay grapes\t1\tflour\t1\tpotato\t1"
, "33870\t6\t16\tCreamcheese Frosted Gorapple Cake\tcheese\t1\tcarrots\t1\tapples\t1"
, "33810\t6\t17\tForge-Wife's Spudmelon Pie\tmelon\t1\tflour\t1\tpotato\t1"
, "33895\t6\t18\tBlackwood Stuffed Banana Leaves\tmillet\t1\tgreens\t1\tbananas\t1"
, "54377\t6\t19\tSpinner's Taboo Salad\tsaltrice\t1\tmelon\t1\tbeets\t1"
, "57095\t6\t20\tAshlander Ochre Mash\tseasoning\t1\tcarrots\t1\tpumpkin\t1"
, "57096\t6\t21\tOrcish No-Rhubarb Salad\tradish\t1\tgarlic\t1\tapples\t1"
, "33916\t6\t22\tSun-Dried Caravan Provisions\tseasoning\t1\tbeets\t1\tapples\t1"
, "57108\t6\t23\tSavory Banana Cornbread\tcorn\t1\tgarlic\t1\tbananas\t1"
, "57109\t6\t24\tDrunken Goat Cheese with Radishes\tradish\t1\tjazbay grapes\t1\tcheese\t1"
, "28332\t6\t25\tSavory Mid Year Preserves\tmelon\t1\tgarlic\t1\tcarrots\t1"
, "57121\t6\t26\tEidar Banana-Radish Vichyssoise\tradish\t1\tcheese\t1\tbananas\t1"
, "57122\t6\t27\tKhajiiti Apple Spanakopita\tflour\t1\tgreens\t1\tapples\t1"
, "43155\t6\t28\tEvery-Morndas Casserole\tmelon\t1\tcheese\t1\tpotato\t1"
, "57133\t6\t29\tSavory-Sweet Fried Kale\tjazbay grapes\t1\tgarlic\t1\tgreens\t1"
, "57134\t6\t30\tLate-Summer Corn Slaw\tcorn\t1\tmillet\t1\tpumpkin\t1"
, "57150\t6\t31\tBoiled Creme Treat\tradish\t1\tsaltrice\t1\tpumpkin\t1"
, "57151\t6\t32\tSweetroll\tcorn\t1\tseasoning\t1\tbananas\t1"
, "57152\t6\t33\tArenthia's Empty Tankard Frittata\ttomato\t1\tgarlic\t1\tpotato\t1"
, "68248\t6\t34\tChevre-Radish Salad with Pumpkin Seeds\tradish\t1\tcheese\t1\tpumpkin\t1"
, "68249\t6\t35\tGrapes and AshYam Falafel\tjazbay grapes\t1\tmillet\t1\tpotato\t1"
, "68250\t6\t36\tLate Hearthfire Vegetable Tart\tflour\t1\tbeets\t1\tpumpkin\t1"
, "57080\t7\t1\tCorinthe Corn Beef\tcorn\t1\tbananas\t1\tfrost mirriam\t1\tred meat\t1"
, "57081\t7\t2\tSweet Skeever Gumbo\tfrost mirriam\t1\tapples\t1\tbeets\t1\tsmall game\t1"
, "57082\t7\t3\tRiekling Suckling Bristleback\twhite meat\t1\tgreens\t1\tfrost mirriam\t1\tpumpkin\t1"
, "57084\t7\t4\tSummerset Rainbow Pie\tfrost mirriam\t1\tbananas\t1\tbeets\t1\tsmall game\t1"
, "33802\t7\t5\tDawnstar Sun's Dusk Chowder\tcorn\t1\tpumpkin\t1\tfrost mirriam\t1\tred meat\t1"
, "33594\t7\t6\tNibenese Fricasseed Fawn\tfrost mirriam\t1\tgreens\t1\tgame\t1\tapples\t1"
, "33856\t7\t7\tVvardenfell Cliff Racer Ragout\ttomato\t1\tpoultry\t1\tfrost mirriam\t1\tcarrots\t1"
, "55922\t7\t8\tTwenty-Four-Raven Pie\tjazbay grapes\t1\tpoultry\t1\tfrost mirriam\t1\tgreens\t1"
, "33886\t7\t9\tGold Coast Mudcrab Fries\tpotato\t1\tmelon\t1\tfrost mirriam\t1\tfish\t1"
, "33892\t7\t10\tStirk Pork-and-Beets\twhite meat\t1\tfrost mirriam\t1\tbeets\t1\tbananas\t1"
, "28331\t7\t11\tHorker Loaf\tcorn\t1\tmelon\t1\tfrost mirriam\t1\tred meat\t1"
, "57110\t7\t12\tMarkarth Short Pig\twhite meat\t1\tpotato\t1\tfrost mirriam\t1\tapples\t1"
, "33808\t7\t13\tParrot-and-Pumpkin Salad\tgreens\t1\tpoultry\t1\tfrost mirriam\t1\tpumpkin\t1"
, "33868\t7\t14\tDirenni Hundred-Year Rabbit Bisque\tcorn\t1\tjazbay grapes\t1\tfrost mirriam\t1\tsmall game\t1"
, "33919\t7\t15\tCaramelized Goat Nibbles\tradish\t1\tjazbay grapes\t1\tgame\t1\tfrost mirriam\t1"
, "33796\t7\t17\tBraised Sweetmeats\tradish\t1\tbananas\t1\tfrost mirriam\t1\tred meat\t1"
, "43128\t7\t18\tSlow-Simmered Rabbit Goulash\tcarrots\t1\ttomato\t1\tfrost mirriam\t1\tsmall game\t1"
, "33928\t7\t19\tPlanked Abecean Longfin\tfrost mirriam\t1\tapples\t1\tbeets\t1\tfish\t1"
, "33910\t7\t20\tSalmon Steak Supreme\tapples\t1\tcarrots\t1\tfrost mirriam\t1\tfish\t1"
, "33904\t7\t21\tImperial Stuffed Piglet\twhite meat\t1\tjazbay grapes\t1\tfrost mirriam\t1\tradish\t1"
, "33922\t7\t22\tDuck Soup\ttomato\t1\tpoultry\t1\tfrost mirriam\t1\tpotato\t1"
, "28333\t7\t23\tHircine's Meat Loaf\tcorn\t1\tfrost mirriam\t1\tgame\t1\tapples\t1"
, "43089\t7\t24\tUltimate Riverhold Beef Pasty\tradish\t1\ttomato\t1\tfrost mirriam\t1\tred meat\t1"
, "43143\t7\t25\tThe Emperor's Venison Fricassee\tfrost mirriam\t1\tmelon\t1\tgame\t1\tcarrots\t1"
, "33898\t7\t26\tPotentate's Supreme Cioppino\tcorn\t1\tpumpkin\t1\tfrost mirriam\t1\tfish\t1"
, "57153\t7\t27\tThe Secret Chef's Pork Roast\twhite meat\t1\tjazbay grapes\t1\tfrost mirriam\t1\tpotato\t1"
, "68251\t7\t28\tCapon Tomato-Beet Casserole\tfrost mirriam\t1\tpoultry\t1\tbeets\t1\ttomato\t1"
, "68252\t7\t29\tJugged Rabbit in Preserves\tbananas\t1\tcarrots\t1\tfrost mirriam\t1\tsmall game\t1"
, "68253\t7\t30\tLongfin Pasty with Melon Sauce\tgreens\t1\tmelon\t1\tfrost mirriam\t1\tfish\t1"
, "68254\t7\t31\tWithered Tree Inn Venison Pot Roast\tfrost mirriam\t1\tcarrots\t1\tgame\t1\tapples\t1"
, "28401\t8\t1\tNut Brown Ale\tbarley\t1"
, "33600\t8\t2\tRed Rye Beer\trye\t1"
, "33933\t8\t3\tGolden Lager\twheat\t1"
, "28405\t8\t4\tBog-Iron Ale\tyeast\t1"
, "33606\t8\t5\tMazte\trice\t1"
, "33939\t8\t6\tSurilie Syrah Wine\tsurilie grapes\t1"
, "28409\t8\t7\tClarified Syrah Wine\tisinglass\t1\tsurilie grapes\t1"
, "33612\t8\t8\tFour-Eye Grog\twheat\t1\tseaweed\t1"
, "33945\t8\t9\tLemon Flower Mazte\trice\t1\tlemon\t1"
, "28413\t8\t10\tTawny Port\tyeast\t1\tmetheglin\t1"
, "33618\t8\t11\tRed Hippocras\tginger\t1\tsurilie grapes\t1"
, "33951\t8\t12\tOld Clear-Eye Whiskey\tbarley\t1\tisinglass\t1"
, "28417\t8\t13\tEltheric Hooch\tseaweed\t1\trye\t1"
, "33624\t8\t14\tBarley Nectar\tbarley\t1\thoney\t1"
, "33957\t8\t15\tGossamer Mazte\trice\t1\tisinglass\t1"
, "28421\t8\t16\tHoney Rye\thoney\t1\trye\t1"
, "33630\t8\t17\tMermaid Whiskey\tbarley\t1\tseaweed\t1"
, "33963\t8\t18\tGinger Wheat Beer\twheat\t1\tginger\t1"
, "28425\t8\t19\tSour Mash\tbarley\t1\tlemon\t1"
, "33636\t8\t20\tSpiced Mazte\trice\t1\tginger\t1"
, "33969\t8\t21\tMulled Wine\tmetheglin\t1\tsurilie grapes\t1"
, "28429\t8\t22\tRye-in-your-Eye\tmetheglin\t1\trye\t1"
, "33642\t8\t23\tSorry, Honey Lager\twheat\t1\thoney\t1"
, "33975\t8\t24\tNereid Wine\tseaweed\t1\tsurilie grapes\t1"
, "28433\t8\t25\tGods-Blind-Me\tyeast\t1\tisinglass\t1"
, "57158\t8\t26\tCheydinhal Sherry\thoney\t1\tsurilie grapes\t1"
, "57161\t8\t27\tColovian Amber Ale\twheat\t1\tmetheglin\t1"
, "28437\t8\t28\tSweet Scamp Mazte\trice\t1\thoney\t1"
, "57170\t8\t29\tSour Gin Fizz\tyeast\t1\tlemon\t1"
, "57173\t8\t30\tWhiskey Sour\tlemon\t1\trye\t1"
, "28402\t8\t31\tComely Wench Whiskey\tginger\t1\trye\t1"
, "57182\t8\t32\tRimmen Sour Bock\twheat\t1\tlemon\t1"
, "57185\t8\t33\tFrothy Sargassum\tyeast\t1\tseaweed\t1"
, "33652\t8\t34\tArenthian Brandy\tlemon\t1\tsurilie grapes\t1"
, "34032\t8\t35\tSummer Sky Pale Ale\twheat\t1\tisinglass\t1"
, "57194\t8\t36\tArgonian Mud-Nectar\trice\t1\tseaweed\t1"
, "57200\t8\t37\tAlabaster Honey Rum\tyeast\t1\thoney\t1"
, "57201\t8\t38\tCrystal Tower Whiskey\tisinglass\t1\trye\t1"
, "57202\t8\t39\tPalace of Kings Ginger Beer\tbarley\t1\tginger\t1"
, "68255\t8\t40\tKragenmoor Zinger Mazte\trice\t1\tmetheglin\t1"
, "68256\t8\t41\tColovian Ginger Beer\tyeast\t1\tginger\t1"
, "68257\t8\t42\tMarkarth Mead\tbarley\t1\tmetheglin\t1"
, "28441\t9\t1\tJasmine Tea\tjasmine\t1"
, "33648\t9\t2\tMint Chai\tmint\t1"
, "33981\t9\t3\tRose Herbal Tea\trose\t1"
, "28445\t9\t4\tLotus Tea\tlotus\t1"
, "33654\t9\t5\tBitter Tea\tbittergreen\t1"
, "33987\t9\t6\tComberry Chai\tcomberry\t1"
, "28449\t9\t7\tHoneyberry Tea\tcomberry\t1\thoney\t1"
, "33660\t9\t8\tMorning Reveille Tea\tmint\t1\tginger\t1"
, "33993\t9\t9\tSweetsting Tea\tlotus\t1\tmetheglin\t1"
, "28453\t9\t10\tSourflower Tea\tlotus\t1\tlemon\t1"
, "33666\t9\t11\tGreen Scourgut Tea\tseaweed\t1\tbittergreen\t1"
, "33999\t9\t12\tGingerose Tea\tginger\t1\trose\t1"
, "28457\t9\t13\tBitterlemon Tea\tlemon\t1\tbittergreen\t1"
, "33672\t9\t14\tTreacleberry Tea\tcomberry\t1\tmetheglin\t1"
, "34005\t9\t15\tSeaflower Tea\tlotus\t1\tseaweed\t1"
, "28461\t9\t16\tThrassian Chai\tseaweed\t1\tjasmine\t1"
, "33678\t9\t17\tEnlightenment Tea\tlotus\t1\tisinglass\t1"
, "34011\t9\t18\tMead de Menthe\tmint\t1\tmetheglin\t1"
, "28465\t9\t19\tMaormer Tea\tseaweed\t1\trose\t1"
, "33684\t9\t20\tSpiceberry Chai\tcomberry\t1\tginger\t1"
, "34017\t9\t21\tTorval Mint Tea\tmint\t1\thoney\t1"
, "28469\t9\t22\tPuckermint Tea\tmint\t1\tlemon\t1"
, "33690\t9\t23\tWinter Rose Tea\tisinglass\t1\trose\t1"
, "34023\t9\t24\tPink Profundity\tisinglass\t1\tjasmine\t1"
, "28473\t9\t25\tTwo-Zephyr Tea\tlemon\t1\trose\t1"
, "57159\t9\t26\tSweet Slaughterfish Tea\tcomberry\t1\tseaweed\t1"
, "57160\t9\t27\tVivec's Gingergreen Chai\tginger\t1\tbittergreen\t1"
, "28477\t9\t28\tSweet Dreams Tea\tlotus\t1\thoney\t1"
, "57171\t9\t29\tJasminger Tea\tginger\t1\tjasmine\t1"
, "57172\t9\t30\tCamlorn Mint Tea\tmint\t1\tisinglass\t1"
, "33602\t9\t31\tAetherial Tea\tmetheglin\t1\tjasmine\t1"
, "57183\t9\t32\tClan Mother's Cordial\tcomberry\t1\tisinglass\t1"
, "57184\t9\t33\tMournhold Twister\thoney\t1\tbittergreen\t1"
, "28482\t9\t34\tKhenarthi's Wings Chai\thoney\t1\tjasmine\t1"
, "46061\t9\t35\tBitter Ritual Tea\tisinglass\t1\tbittergreen\t1"
, "57195\t9\t36\tFive-Fireball Infusion\tlotus\t1\tginger\t1"
, "57203\t9\t37\tComberry Citrus Quencher\tcomberry\t1\tlemon\t1"
, "57204\t9\t38\tPirate Queen Mint Tea\tmint\t1\tseaweed\t1"
, "57205\t9\t39\tFalkreath Rosy Mead\tmetheglin\t1\trose\t1"
, "68258\t9\t40\tHeart's Day Rose Tea\thoney\t1\trose\t1"
, "68259\t9\t41\tSoothing Bard's-Throat Tea\tlemon\t1\tjasmine\t1"
, "68260\t9\t42\tMuthsera's Remorse\tmetheglin\t1\tbittergreen\t1"
, "28481\t10\t1\tGinkgo Tonic\tginkgo\t1"
, "33696\t10\t2\tAcai Tonic Infusion\tacai berry\t1"
, "34029\t10\t3\tGuarana Tonic\tguarana\t1"
, "28485\t10\t4\tGinseng Tonic\tginseng\t1"
, "33702\t10\t5\tBlack Coffee\tcoffee\t1"
, "34035\t10\t6\tMate Infusion\tyerba mate\t1"
, "28489\t10\t7\tTonsil Tingle Tonic\thoney\t1\tginkgo\t1"
, "33708\t10\t8\tMeady-Matey Infusion\tyerba mate\t1\tmetheglin\t1"
, "34041\t10\t9\tYellow Goblin Tonic\tlemon\t1\tginseng\t1"
, "28493\t10\t10\tIsinmate Infusion\tyerba mate\t1\tisinglass\t1"
, "33714\t10\t11\tKelp Kaveh\tseaweed\t1\tcoffee\t1"
, "34047\t10\t12\tSweetberry Tonic\tacai berry\t1\thoney\t1"
, "28497\t10\t13\tTaneth Coffee\thoney\t1\tcoffee\t1"
, "33720\t10\t14\tGinkgo Twist Tonic\tmetheglin\t1\tginkgo\t1"
, "34053\t10\t15\tYerba Zinger Tonic\tyerba mate\t1\tginger\t1"
, "28501\t10\t16\tBusy Bee Brew\tmetheglin\t1\tcoffee\t1"
, "33726\t10\t17\tGinseng Sling\thoney\t1\tginseng\t1"
, "34059\t10\t18\tAthlete's Guzzle\tacai berry\t1\tlemon\t1"
, "28505\t10\t19\tBerrymead Tonic\tacai berry\t1\tmetheglin\t1"
, "33732\t10\t20\tPirate's Jig Tonic\tseaweed\t1\tguarana\t1"
, "34065\t10\t21\tDancing Grandma\tisinglass\t1\tginkgo\t1"
, "28509\t10\t22\tRihad Qishr\tginger\t1\tcoffee\t1"
, "33738\t10\t23\tSeaberry Tonic\tacai berry\t1\tseaweed\t1"
, "34071\t10\t24\tCrystal Clarity\tisinglass\t1\tginseng\t1"
, "28513\t10\t25\tBlue Road Marathon\tisinglass\t1\tguarana\t1"
, "57162\t10\t26\tSweet Persistence\tyerba mate\t1\thoney\t1"
, "57163\t10\t27\tInfernal Infusion\tginger\t1\tginseng\t1"
, "28517\t10\t28\tShimmerene Tonic\tacai berry\t1\tisinglass\t1"
, "57174\t10\t29\tLemonic Invigoration\tlemon\t1\tguarana\t1"
, "57175\t10\t30\tDreugh Spit\tseaweed\t1\tginseng\t1"
, "28444\t10\t31\tGrandpa's Bedtime Tonic\tginger\t1\tguarana\t1"
, "57186\t10\t32\tSload Slime\tseaweed\t1\tginkgo\t1"
, "57187\t10\t33\tSoothing Sundas Tonic\tyerba mate\t1\tlemon\t1"
, "33698\t10\t34\tSipping Imga Tonic\tlemon\t1\tginkgo\t1"
, "46063\t10\t35\tSailor's Second Wind\tyerba mate\t1\tseaweed\t1"
, "57196\t10\t36\tWamasu Spew\tmetheglin\t1\tginseng\t1"
, "57206\t10\t37\tHasphat's Sticky Guar Tonic\thoney\t1\tguarana\t1"
, "57207\t10\t38\tNocturnal's Everblack Coffee\tisinglass\t1\tcoffee\t1"
, "57208\t10\t39\tFyr's Hyperagonal Potation\tacai berry\t1\tginger\t1"
, "68261\t10\t40\tFredas Night Infusion\tmetheglin\t1\tguarana\t1"
, "68262\t10\t41\tOld Hegathe Lemon Kaveh\tlemon\t1\tcoffee\t1"
, "68263\t10\t42\tHagraven's Tonic\tginger\t1\tginkgo\t1"
, "28411\t11\t1\tCloudrest Golden Ale\tyeast\t1\tlotus\t1"
, "33614\t11\t2\tClamberskull\trice\t1\tbittergreen\t1"
, "33947\t11\t3\tSkingrad Muscat\tcomberry\t1\tsurilie grapes\t1"
, "28415\t11\t4\tJasmine Moonshine\tbarley\t1\tjasmine\t1"
, "33620\t11\t5\tCreme de Menthe\tmint\t1\trye\t1"
, "33953\t11\t6\tRose Lager\twheat\t1\trose\t1"
, "28419\t11\t7\tClarified Rose Lager\twheat\t1\tisinglass\t1\trose\t1"
, "33626\t11\t8\tHorker's Breath\tmint\t1\tyeast\t1\tginger\t1"
, "33959\t11\t9\tSujamma\tbarley\t1\tcomberry\t1\tlemon\t1"
, "28423\t11\t10\tBitter Remorse Ale\twheat\t1\tginger\t1\tbittergreen\t1"
, "33632\t11\t11\tSpriggan Sap\trye\t1\tlotus\t1\tlemon\t1"
, "33965\t11\t12\tTruth-Glimpse\tmint\t1\tbarley\t1\tisinglass\t1"
, "28427\t11\t13\tSweet Lemonale\twheat\t1\tcomberry\t1\tlemon\t1"
, "33638\t11\t14\tDouble Clarified Mazte\trice\t1\tisinglass\t1\tbittergreen\t1"
, "33971\t11\t15\tSanguine's Temptation\tbarley\t1\tlotus\t1\thoney\t1"
, "28431\t11\t16\tSummer Mazte\trice\t1\tlemon\t1\trose\t1"
, "33644\t11\t17\tRiften Rye\tmetheglin\t1\trye\t1\tbittergreen\t1"
, "33977\t11\t18\tNight-Grog\tginger\t1\tcomberry\t1\tyeast\t1"
, "28435\t11\t19\tRosy Island Ale\tseaweed\t1\tyeast\t1\trose\t1"
, "57164\t11\t20\tWizard's Whiskey\tmint\t1\twheat\t1\tlemon\t1"
, "57167\t11\t21\tSweet and Sour Port\tmetheglin\t1\tbittergreen\t1\tsurilie grapes\t1"
, "28439\t11\t22\tAnequina Stout\tbarley\t1\tlemon\t1\tbittergreen\t1"
, "57176\t11\t23\tBlack Night Cordial\trice\t1\tcomberry\t1\tseaweed\t1"
, "57179\t11\t24\tSylph Gin\thoney\t1\tlotus\t1\tyeast\t1"
, "33420\t11\t25\tComberry Bourbon\tmetheglin\t1\trye\t1\tcomberry\t1"
, "57188\t11\t26\tHoneyhips Brown Ale\tbarley\t1\thoney\t1\trose\t1"
, "57191\t11\t27\tHunt-Wife's Grog\tisinglass\t1\tyeast\t1\tbittergreen\t1"
, "46062\t11\t28\tOld Sweetheart Stout\tmint\t1\thoney\t1\twheat\t1"
, "33984\t11\t29\tBreton Pint of Bitters\tbarley\t1\tisinglass\t1\tbittergreen\t1"
, "57197\t11\t30\tBlue Banekin Beer\tginger\t1\tyeast\t1\tjasmine\t1"
, "57209\t11\t31\tSaint Pelin's Tawny Port\tlemon\t1\tyeast\t1\trose\t1"
, "57210\t11\t32\tYokudan Sorrow Bourbon\tseaweed\t1\trye\t1\tlotus\t1"
, "57211\t11\t33\tClavicus Vines Chenin Blanc\tmetheglin\t1\tjasmine\t1\tsurilie grapes\t1"
, "68264\t11\t34\tPort Hunding Pinot Noir\tmint\t1\tseaweed\t1\tsurilie grapes\t1"
, "68265\t11\t35\tDragontail Blended Whisky\trye\t1\tlotus\t1\thoney\t1"
, "68266\t11\t36\tBravil Bitter Barley Beer\tbarley\t1\tginger\t1\tbittergreen\t1"
, "28452\t12\t1\tTimber Mammoth Ale\tbarley\t1\tginseng\t1"
, "33663\t12\t2\tKaveh Stout\tcoffee\t1\trye\t1"
, "33996\t12\t3\tStand-Me-Up Lager\twheat\t1\tguarana\t1"
, "28456\t12\t4\tGinkgo Lightning\tyeast\t1\tginkgo\t1"
, "33669\t12\t5\tAcai Dry Mazte\trice\t1\tacai berry\t1"
, "34002\t12\t6\tYerba Syrah Wine\tyerba mate\t1\tsurilie grapes\t1"
, "28460\t12\t7\tBravil Mead\trice\t1\tyerba mate\t1\thoney\t1"
, "33675\t12\t8\tWest Weald Wallop\tacai berry\t1\tisinglass\t1\tsurilie grapes\t1"
, "34008\t12\t9\tElinhir Qishr\tcoffee\t1\tyeast\t1\tginger\t1"
, "28464\t12\t10\tGinkgo Double Brandy\trice\t1\thoney\t1\tginkgo\t1"
, "33681\t12\t11\tGinger Port\tginger\t1\tyerba mate\t1\tsurilie grapes\t1"
, "34014\t12\t12\tDrowned Sailor Ale\tseaweed\t1\tyeast\t1\tginseng\t1"
, "28468\t12\t13\tFulmination Ale\tginger\t1\tyeast\t1\tginkgo\t1"
, "33687\t12\t14\tVvardenfell Flin\tseaweed\t1\trye\t1\tginseng\t1"
, "34020\t12\t15\tSour Guar Shein\tguarana\t1\tlemon\t1\tsurilie grapes\t1"
, "28472\t12\t16\tPyandonea Merlot\tseaweed\t1\tginseng\t1\tsurilie grapes\t1"
, "33693\t12\t17\tVigilance Gold Ale\twheat\t1\tcoffee\t1\tlemon\t1"
, "34026\t12\t18\tImperial Stout\tbarley\t1\tguarana\t1\tmetheglin\t1"
, "28476\t12\t19\tDark Seducer\tacai berry\t1\thoney\t1\trice\t1"
, "57165\t12\t20\tStalwart Stout\tbarley\t1\tyerba mate\t1\tisinglass\t1"
, "57166\t12\t21\tBoethiah's Breath\trye\t1\tginger\t1\tguarana\t1"
, "28487\t12\t22\tNarsis Wickwheat Ale\twheat\t1\tyerba mate\t1\tisinglass\t1"
, "57177\t12\t23\tSpicy Wyress Wine\tginkgo\t1\tginger\t1\tsurilie grapes\t1"
, "57178\t12\t24\tWhite-Eye Whiskey\tacai berry\t1\trye\t1\tlemon\t1"
, "28443\t12\t25\tBlacklight Ginger Mazte\trice\t1\tguarana\t1\tginger\t1"
, "57189\t12\t26\tJephre's Earthbone Beer\tacai berry\t1\twheat\t1\tlemon\t1"
, "57190\t12\t27\tKvatch Watch Grenache\tseaweed\t1\tcoffee\t1\tsurilie grapes\t1"
, "33697\t12\t28\tSurilie Bros. White Merlot\tlemon\t1\tginkgo\t1\tsurilie grapes\t1"
, "46058\t12\t29\tCrow's Nest Rye\tseaweed\t1\trye\t1\tcoffee\t1"
, "57198\t12\t30\tNecrom Nights Mazte\trice\t1\tmetheglin\t1\tginseng\t1"
, "57212\t12\t31\tHappy Ogrim Amber Ale\twheat\t1\thoney\t1\tginkgo\t1"
, "57213\t12\t32\tPsijic Sage's Mazte\trice\t1\tyerba mate\t1\tisinglass\t1"
, "57214\t12\t33\tStendarr's Vigilance Ginger Ale\tbarley\t1\tcoffee\t1\tginger\t1"
, "68267\t12\t34\tWide-Eye Double Rye\trye\t1\tisinglass\t1\tginseng\t1"
, "68268\t12\t35\tCamlorn Sweet Brown Ale\tacai berry\t1\tmetheglin\t1\tbarley\t1"
, "68269\t12\t36\tFlowing Bowl Green Port\tseaweed\t1\tyerba mate\t1\tsurilie grapes\t1"
, "28492\t13\t1\tLillandril Tonic Tea\tginkgo\t1\tjasmine\t1"
, "33711\t13\t2\tBlackwood Mint Chai\tmint\t1\tacai berry\t1"
, "34044\t13\t3\tHerbflower Tea\tyerba mate\t1\trose\t1"
, "28496\t13\t4\tTsaesci Tea\tlotus\t1\tginseng\t1"
, "33717\t13\t5\tBitter Kaveh\tcoffee\t1\tbittergreen\t1"
, "34050\t13\t6\tComberry Tonic\tcomberry\t1\tguarana\t1"
, "28500\t13\t7\tPondwater Tea\tseaweed\t1\tlotus\t1\tginseng\t1"
, "33723\t13\t8\tJasrana Tea Tonic\tguarana\t1\tlemon\t1\tjasmine\t1"
, "34056\t13\t9\tDibella's Kiss Tea\tmetheglin\t1\tginkgo\t1\tbittergreen\t1"
, "28504\t13\t10\tCornerclub Kaveh\tcoffee\t1\tcomberry\t1\tlemon\t1"
, "33729\t13\t11\tCelestial Tonic Tea\tacai berry\t1\tmetheglin\t1\tjasmine\t1"
, "34062\t13\t12\tAzura's Rose Tea\tguarana\t1\tisinglass\t1\trose\t1"
, "28508\t13\t13\tMintmead Kaveh\tmint\t1\tcoffee\t1\tmetheglin\t1"
, "33735\t13\t14\tSweet Scented Infusion\thoney\t1\tyerba mate\t1\tjasmine\t1"
, "34068\t13\t15\tPink Wisdom Tea\tacai berry\t1\tisinglass\t1\trose\t1"
, "28512\t13\t16\tJasminkgo Tonic\tginkgo\t1\thoney\t1\tjasmine\t1"
, "33741\t13\t17\tSilver Lotusberry Tea\tacai berry\t1\tlotus\t1\tisinglass\t1"
, "34074\t13\t18\tTingle Tonic Tea\tmint\t1\tyerba mate\t1\tginger\t1"
, "28516\t13\t19\tSerene Awareness\tcoffee\t1\tlotus\t1\tlemon\t1"
, "57168\t13\t20\tMidnight Ritual Tea\tseaweed\t1\tcomberry\t1\tginkgo\t1"
, "57169\t13\t21\tChthonic Tonic\tmetheglin\t1\tginseng\t1\tjasmine\t1"
, "33458\t13\t22\tCenturion's Friend Kaveh\tseaweed\t1\tcoffee\t1\tjasmine\t1"
, "57180\t13\t23\tElven Maiden Tea\tmint\t1\tguarana\t1\tmetheglin\t1"
, "57181\t13\t24\tStrapping Lad Tonic\tginseng\t1\thoney\t1\trose\t1"
, "33650\t13\t25\tMage's Mead\tmetheglin\t1\tlotus\t1\tginkgo\t1"
, "57192\t13\t26\tFirst Kiss Tea\tmint\t1\thoney\t1\tginseng\t1"
, "57193\t13\t27\tSenchal Dancer Tonic\tisinglass\t1\tyerba mate\t1\tjasmine\t1"
, "34030\t13\t28\tTelvanni Tea\tacai berry\t1\tlotus\t1\thoney\t1"
, "46060\t13\t29\tTen Ogres Tonic\tmetheglin\t1\tyerba mate\t1\trose\t1"
, "57199\t13\t30\tGinger Guar Smoothie\tguarana\t1\tcomberry\t1\tginger\t1"
, "57215\t13\t31\tBalfiera Herbal Tonic\tlemon\t1\tcomberry\t1\tginseng\t1"
, "57216\t13\t32\tMint Mudcrab Mojito\tmint\t1\tguarana\t1\tseaweed\t1"
, "57217\t13\t33\tTonal Architect Tonic\tacai berry\t1\tmetheglin\t1\tbittergreen\t1"
, "68270\t13\t34\tHonest Lassie Honey Tea\thoney\t1\tcomberry\t1\tginseng\t1"
, "68271\t13\t35\tRosy Disposition Tonic\tacai berry\t1\tginger\t1\trose\t1"
, "68272\t13\t36\tCloudrest Clarified Coffee\tcoffee\t1\tcomberry\t1\tisinglass\t1"
, "57155\t14\t1\tGreef\tmint\t1\tguarana\t1\tyeast\t1\tbervez juice\t1"
, "57156\t14\t2\tRed Queen's Eye-Opener\tjasmine\t1\tcoffee\t1\tbervez juice\t1\tsurilie grapes\t1"
, "57157\t14\t3\tAqua Vitae\tbervez juice\t1\trye\t1\tcomberry\t1\tyerba mate\t1"
, "34027\t14\t4\tAbecean Brandy\tmint\t1\tacai berry\t1\tbervez juice\t1\tsurilie grapes\t1"
, "33434\t14\t5\tEnemies Explode\tbervez juice\t1\tguarana\t1\tcomberry\t1\tyeast\t1"
, "33694\t14\t6\tMonkeypants Mazte\trice\t1\tbervez juice\t1\tyerba mate\t1\tjasmine\t1"
, "33979\t14\t7\tSeven Year Beer\twheat\t1\tginkgo\t1\tbervez juice\t1\tbittergreen\t1"
, "33739\t14\t8\tVaermina's Nightmare\tbervez juice\t1\trye\t1\tyerba mate\t1\tjasmine\t1"
, "33436\t14\t9\tTranquility Pale Ale\tbarley\t1\tbervez juice\t1\tlotus\t1\tacai berry\t1"
, "33456\t14\t10\tHopscotch\tmint\t1\trye\t1\tbervez juice\t1\tcoffee\t1"
, "28514\t14\t11\tTen-Foot Beer\tbervez juice\t1\tguarana\t1\tlotus\t1\tyeast\t1"
, "34072\t14\t12\tRude Awakening\trice\t1\tcoffee\t1\tbervez juice\t1\trose\t1"
, "33459\t14\t13\tBerveza Vitae\twheat\t1\tbervez juice\t1\tcomberry\t1\tyerba mate\t1"
, "28518\t14\t14\tOrsinium Pink Zinfandel\trose\t1\tguarana\t1\tbervez juice\t1\tsurilie grapes\t1"
, "33438\t14\t15\tFifth Legion Porter\twheat\t1\tginseng\t1\tbervez juice\t1\trose\t1"
, "33603\t14\t16\tCardiac Arrest\trice\t1\tcoffee\t1\tlotus\t1\tbervez juice\t1"
, "28403\t14\t17\tAnimate-the-Dead\tmint\t1\tbervez juice\t1\tyeast\t1\tginseng\t1"
, "33440\t14\t18\tXanmeer Brandy\tbittergreen\t1\tginkgo\t1\tbervez juice\t1\tsurilie grapes\t1"
, "46057\t14\t20\tHello Handsome Porter\tbarley\t1\tginkgo\t1\tbervez juice\t1\tjasmine\t1"
, "33982\t14\t21\tHigh Rock Rose and Rye\tginseng\t1\trye\t1\tbervez juice\t1\trose\t1"
, "28483\t14\t22\tMalacath's Hammer\twheat\t1\tacai berry\t1\tbervez juice\t1\tbittergreen\t1"
, "33699\t14\t23\tKagouti Kick Mazte\trice\t1\tguarana\t1\tbervez juice\t1\tjasmine\t1"
, "28510\t14\t24\tTears of Joy\tbervez juice\t1\tginseng\t1\tyeast\t1\tbittergreen\t1"
, "33646\t14\t25\tNumidium Brandy\trice\t1\tbervez juice\t1\tlotus\t1\tginkgo\t1"
, "34033\t14\t26\tYsgramor's Harbinger Lager\tbarley\t1\tguarana\t1\tcomberry\t1\tbervez juice\t1"
, "46059\t14\t27\tRislav's Righteous Red Kvass\tacai berry\t1\trye\t1\tbervez juice\t1\trose\t1"
, "68273\t14\t28\tSenche-Tiger Single Malt\twheat\t1\tcoffee\t1\tbervez juice\t1\tbittergreen\t1"
, "68274\t14\t29\tVelothi View Vintage Malbec\tmint\t1\tginkgo\t1\tbervez juice\t1\tsurilie grapes\t1"
, "68275\t14\t30\tOrcrest Agony Pale Ale\tbarley\t1\tbervez juice\t1\tlotus\t1\tyerba mate\t1"
, "68276\t14\t31\tLusty Argonian Maid Mazte\trice\t1\tginkgo\t1\tbervez juice\t1\tjasmine\t1"
, "64221\t15\t1\tPsijic Ambrosia\tfrost mirriam\t1\tbervez juice\t1\tperfect roe\t1"
, "71056\t15\t2\tOrzorga's Red Frothgar\tmint\t1\tclear water\t1\tcomberry\t1\thoney\t1"
, "87687\t15\t3\tBowl of \"Peeled Eyeballs\"\tseasoning\t1\tjazbay grapes\t1\tflour\t1\tsurilie grapes\t1"
, "87690\t15\t4\tWitchmother's Party Punch\tlotus\t1\trye\t1\tbervez juice\t1\tlemon\t1"
, "87695\t15\t5\tGhastly Eye Bowl\trose\t1\tfleshfly larva||fleshfly larvae\t1\tbananas\t1\tworms\t1"
, "87699\t15\t6\tDouble Bloody Mara\tnirnroot\t1\ttomato\t1\tdaedra heart\t1\tfrost mirriam\t1"
, "87697\t15\t7\tWitchmother's Potent Brew\trice\t1\tsmall game\t1\tbervez juice\t1\tnightshade\t1"
, "112426\t15\t8\tBergama Warning Fire\tlotus\t1\tcoffee\t1\tyerba mate\t1\tdragonthorn\t1"
, "112433\t15\t9\tBetnikh Twice-Spiked Ale\tbarley\t1\thoney\t1\tyeast\t1\trice\t1"
, "112440\t15\t10\tSnow Bear Glow-Wine\tjazbay grapes\t1\tyeast\t1\thoney\t1"
, "101879\t15\t11\tHissmir Fish-Eye Rye\trye\t1\tfish\t1\tcorn flower\t1\tbervez juice\t1\tlemon\t1"
, "71057\t16\t2\tOrzorga's Tripe Trifle Pocket\twhite meat\t1\tcolumbine\t1\tguts\t1\tbeets\t1"
, "71058\t16\t3\tOrzorga's Blood Price Pie\tpotato\t1\tviolet coprinus\t1\tguts\t1\tred meat\t1"
, "71059\t16\t4\tOrzorga's Smoked Bear Haunch\twhite cap\t1\tfrost mirriam\t1\tperfect roe\t1\ttomato\t1\tred meat\t1"
, "87685\t16\t5\tSweet Sanguine Apples\thoney\t1\tapples\t1"
, "87686\t16\t6\tCrisp and Crunchy Pumpkin Snack Skewer\tsmall game\t1\tflour\t1\tpotato\t1\tpumpkin\t1"
, "87691\t16\t7\tCrunchy Spider Skewer\tcrawlers\t1\tseasoning\t1\tacai berry\t1\tspider egg\t1"
, "87696\t16\t8\tFrosted Brains\twhite meat\t1\tyeast\t1\thoney\t1\tstinkhorn\t1"
, "112425\t16\t9\tLava Foot Soup-and-Saltrice\tsaltrice\t1\tflour\t1\tscrib jelly\t1\tpotato\t1"
, "112434\t16\t10\tJagga-Drenched \"Mud Ball\"\tseasoning\t1\tcoffee\t1\tflour\t1\tcheese\t1"
, "112435\t16\t11\tOld Aldmeri Orphan Gruel\tbarley\t1\tpumpkin\t1\trose\t1"
, "112438\t16\t12\tRajhin's Sugar Claws\tcorn\t1\tflour\t1\thoney\t1"
, "112439\t16\t13\tAlcaire Festival Sword-Pie\tseasoning\t1\tflour\t1\tred meat\t1"
}

-- Recipe --------------------------------------------------------------------

Provisioning.Recipe  = {}
local Recipe = Provisioning.Recipe
function Recipe:New(args)
    local o = {
        fooddrink_item_id = args.fooddrink_item_id  -- int(33526)
    ,   fooddrink_name    = args.fooddrink_name     -- "Fishy Stick"
    ,   rl_index          = args.rl_index           -- int(1)
    ,   recipe_index      = args.recipe_index       -- int(1)
    ,   mat_table         = {}                      -- "ingr_name" ==> int(ingr_ct)
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

function Recipe:FromIndex(rl_index, recipe_index)
    local o = Recipe:New({ rl_index     = rl_index
                         , recipe_index = recipe_index
                         })
    local _, fooddrink_name, mat_ct = GetRecipeInfo(rl_index, recipe_index)
                        -- Recipe unknown by this character.
                        -- API says nothing about the unknown.
    if not fooddrink_name then return nil end
    o.fooddrink_name = fooddrink_name

    local fooddrink_link = GetRecipeResultItemLink(
                                  rl_index
                                , recipe_index
                                , LINK_STYLE_DEFAULT )
    local _, _, _, fooddrink_item_id = ZO_LinkHandler_ParseLink(fooddrink_link)
    fooddrink_item_id = tonumber(fooddrink_item_id)
    o.fooddrink_item_id = fooddrink_item_id
                        -- Not a known recipe
    if not fooddrink_item_id then return nil end

    for ingr_index = 1,mat_ct do
        local ingr_name, _, ingr_ct = GetRecipeIngredientItemInfo(
                              rl_index
                            , recipe_index
                            , ingr_index)
        if 0 < ingr_ct and ingr_name ~= "" then
            ingr_name = WritWorthy.ToLinkKey(ingr_name)
            o.mat_table[ingr_name] = ingr_ct

                        -- Remember ingredient name/link so that we can
                        -- paste all that into WritWorthy_Link.lua
            local ingr_link = GetRecipeIngredientItemLink(
                                  rl_index
                                , recipe_index
                                , ingr_index)
            WritWorthy.savedVariables.provisioning_ingredient_links[ingr_name] = ingr_link
        end
    end
    return o
end

-- Return a single string representation of this recipe and its ingredients.
function Recipe:Compress()
    local s = string.format( "%s\t%s\t%s\t%s"
                            , tostring(self.fooddrink_item_id)
                            , tostring(self.rl_index)
                            , tostring(self.recipe_index)
                            , self.fooddrink_name
                            )
    for ingr_name, ingr_ct in pairs(self.mat_table) do
        s = s .. string.format( "\t%s\t%s"
                              , WritWorthy.ToLinkKey(ingr_name)
                              , tostring(ingr_ct))
    end
    return s
end

-- Inflate from a Compress() string
function Recipe:FromCompressed(s)
    local w = { zo_strsplit("\t", s) }
    local o = Recipe:New({ fooddrink_item_id = tonumber(w[1])
                         , rl_index          = tonumber(w[2])
                         , recipe_index      = tonumber(w[3])
                         , fooddrink_name    =          w[4]
                         })
    if not o.fooddrink_item_id then
        return Fail("WritWorthy bug: cannot decompress:\""..tostring(s).."\"")
    end
    for i = 5,#w,2 do
        local ingr_name =          w[i]
        local ingr_ct   = tonumber(w[i+1])
        o.mat_table[ingr_name] = ingr_ct
    end
    return o
end


-- Provisioning --------------------------------------------------------------

-- Lazy-fetch recipe details from the above compressed list.
--
-- There's no reason to load this amount of data EVERY time you launch
-- ESO, you often go days between hovering a cursor over a
-- Provisioning Master Writ.
--
function Provisioning.LoadData()
    if Provisioning.RECIPES then return Provisioning.RECIPES end

    if Provisioning.ZZ_SAVE_DATA then
        Provisioning.SaveRecipeList()
        return Provisioning.RECIPES
    end

    local recipes = {}
    local recipe_ct = 0
    for _, compressed in ipairs(Provisioning.COMPRESSED) do
        local recipe = Recipe:FromCompressed(compressed)
        if recipe then
            recipes[recipe.fooddrink_item_id] = recipe
            recipe_ct = recipe_ct + 1
        end
    end
    local c = 0
    -- for k,v in pairs(recipes) do
    --     c = c + 1
    -- end
    -- d(string.format("WritWorthy: %d recipes in table", c))
    d(string.format("WritWorthy: %d recipes loaded", recipe_ct))
    Provisioning.RECIPES = recipes
    return Provisioning.RECIPES
end

-- Scan all known-to-this-character recipes and write their indices to
-- savedVariables. Zig can then copy the table from savedVariables and
-- paste it above as COMPRESSED.
function Provisioning.SaveRecipeList()
    if not WritWorthy.savedVariables.provisioning_ingredient_links then
        WritWorthy.savedVariables.provisioning_ingredient_links = {}
    end

    local recipe_ct      = 0
    local save_strings   = {}
    local recipes        = {}
    local recipe_list_ct = GetNumRecipeLists()
    for rl_index = 1,recipe_list_ct do
        local rl_name, rl_recipe_ct = GetRecipeListInfo(rl_index)
        for recipe_index = 1,rl_recipe_ct do
            local recipe = Recipe:FromIndex(rl_index, recipe_index)
            if recipe then
                recipe_ct = recipe_ct + 1
                recipes[recipe.fooddrink_item_id] = recipe
                table.insert(save_strings, recipe:Compress())
            end
        end
    end
    d(string.format("WritWorthy: %d recipes saved.", recipe_ct))
    WritWorthy.savedVariables.provisioning_recipes = save_strings
    Provisioning.RECIPES = recipes
end

-- Find a recipe by fooddrink_item_id
--
-- First time this runs, we decompress a list of all 554 recipe names.
-- Takes 1+ second!
--
-- Second-and-later times this runs, it's O(1) instantaneous.
--
-- returns a Recipe{} instance.
--
function Provisioning.FindRecipe(fooddrink_item_id)
    local data   = Provisioning.LoadData()
    local recipe = data[fooddrink_item_id]
    if not recipe then
        return Fail("WritWorthy: recipe not found:"..tostring(fooddrink_item_id))
    end
    return recipe
end

Provisioning.Parser = {}
local Parser = Provisioning.Parser

function Parser:New()
    local o = {
        recipe = nil -- Recipe{}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseItemLink(item_link)
    local fields = Util.ToWritFields(item_link)
    self.recipe = Provisioning.FindRecipe(fields.writ1)
    if not self.recipe then return nil end
    return self
end

function Parser:ToMatList()
    local MatRow = WritWorthy.MatRow
    if not self.recipe then return Fail("WritWorthy bug: self.recipe is nil") end
    local ml     = {}
    for ingr_name, ingr_ct in pairs(self.recipe.mat_table) do
        local mr = MatRow:FromName(ingr_name, ingr_ct)
        if not mr then
            return Fail("WritWorthy: ingredient not known:".. tostring(ingr_name))
        end
        table.insert(ml, mr)
    end
    self.mat_list = ml
    return ml
end

