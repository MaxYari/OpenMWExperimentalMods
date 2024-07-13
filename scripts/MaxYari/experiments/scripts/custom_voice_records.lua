local types = require("openmw.types")

local vf = "scripts\\MaxYari\\experiments\\voices\\"
local vvf = "Sound\\Vo\\"

-- Note that the format of this records is slightly different from vanilla to keep it shorter.
local records = {
   StandGround = {
      {
         race = "nord",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "NordFStandGround1.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFStandGround2.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFStandGround3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMStandGround1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMStandGround2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMStandGround3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFStandGround1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFStandGround2.mp3"
            }
         }
      },
   },
   CombatDowntime = {
      {
         race = "nord",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "NordFCombatDowntime1.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFCombatDowntime2.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFCombatDowntime3.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFCombatDowntime4.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFCombatDowntime5.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMCombatDowntime1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMCombatDowntime2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMCombatDowntime3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFCombatDowntime1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFCombatDowntime2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFCombatDowntime3.mp3"
            }
         }
      },
   },
   Retreat = {
      {
         race = "nord",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "NordFRetreat1.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFRetreat2.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFRetreat3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMRetreat1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMRetreat2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMRetreat3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFRetreat1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFRetreat2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFRetreat3.mp3"
            }
         }
      },
   },
   GetEm = {
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "Grab her!",
               sound = vvf .. "d\\m\\OP_DM001.mp3",
               targetGender = "female"
            },
            {
               text = "Grab him!",
               sound = vvf .. "d\\m\\OP_DM002.mp3",
               targetGender = "male"
            },
            {
               text = "She's over here!",
               sound = vvf .. "d\\m\\OP_DM003.mp3",
               targetGender = "female"
            },
            {
               text = "He's over here!",
               sound = vvf .. "d\\m\\OP_DM004.mp3",
               targetGender = "male"
            },
            {
               text = "There he is!",
               sound = vvf .. "d\\m\\OP_DM005.mp3",
               targetGender = "male"
            },
            {
               text = "There she is!",
               sound = vvf .. "d\\m\\OP_DM006.mp3",
               targetGender = "female"
            },
            {
               text = "Seize her!",
               sound = vvf .. "d\\m\\OP_DM007.mp3",
               targetGender = "female"
            },
            {
               text = "Seize him!",
               sound = vvf .. "d\\m\\OP_DM008.mp3",
               targetGender = "male"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "Grab her!",
               sound = vvf .. "d\\f\\OP_DF001.mp3",
               targetGender = "female"
            },
            {
               text = "Grab him!",
               sound = vvf .. "d\\f\\OP_DF002.mp3",
               targetGender = "male"
            },
            {
               text = "She's over here!",
               sound = vvf .. "d\\f\\OP_DF003.mp3",
               targetGender = "female"
            },
            {
               text = "He's over here!",
               sound = vvf .. "d\\f\\OP_DF004.mp3",
               targetGender = "male"
            },
            {
               text = "There he is!",
               sound = vvf .. "d\\f\\OP_DF005.mp3",
               targetGender = "male"
            },
            {
               text = "There she is!",
               sound = vvf .. "d\\f\\OP_DF006.mp3",
               targetGender = "female"
            },
            {
               text = "Seize her!",
               sound = vvf .. "d\\f\\OP_DF007.mp3",
               targetGender = "female"
            },
            {
               text = "Seize him!",
               sound = vvf .. "d\\f\\OP_DF008.mp3",
               targetGender = "male"
            }
         }
      }
   },
   Mercy = {
      {
         race = "nord",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "NordFMercy1.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercy2.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercy3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMMercy1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMMercy2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMMercy3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFMercy1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFMercy2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFMercy3.mp3"
            }
         }
      }
   },
   MercyDisarm = {
      {
         race = "nord",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "NordFMercyDisarm1.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisarm2.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisarm3.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisarm4.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisarm5.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisarm6.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMMercyDisarm1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMMercyDisarm2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMMercyDisarm3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFMercyDisarm1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFMercyDisarm2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFMercyDisarm3.mp3"
            }
         }
      }
   },
   MercyDisengage = {
      {
         race = "nord",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "NordFMercyDisengage1.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisengage2.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisengage3.mp3"
            },
            {
               text = "",
               sound = vf .. "NordFMercyDisengage4.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMMercyDisengage1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMMercyDisengage2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMMercyDisengage3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFMercyDisengage1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFMercyDisengage2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFMercyDisengage3.mp3"
            }
         }
      }
   },
   FriendDead = {
      {
         race = "dark elf",
         gender = "male",
         infos = {
            {
               text = "",
               sound = vf .. "DunMFriendDead1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMFriendDead2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunMFriendDead3.mp3"
            }
         }
      },
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFFriendDead1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFFriendDead2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFFriendDead3.mp3"
            }
         }
      }
   },
   Warcry = {
      {
         race = "dark elf",
         gender = "female",
         infos = {
            {
               text = "",
               sound = vf .. "DunFWarcry1.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFWarcry2.mp3"
            },
            {
               text = "",
               sound = vf .. "DunFWarcry3.mp3"
            }
         }
      }
   }
}

local function findRelevantInfos(recordType, race, gender, isBeast)
   local fittingInfos = {}
   local typerecords = records[recordType]
   if not typerecords then return fittingInfos end

   for _, infosGroup in ipairs(typerecords) do
      if infosGroup.race == race and infosGroup.gender == gender then
         fittingInfos = infosGroup.infos
         break
      end
   end

   return fittingInfos
end

return {
   records = records,
   findRelevantInfos = findRelevantInfos
}
