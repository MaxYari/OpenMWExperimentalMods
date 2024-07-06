local vf = "scripts\\MaxYari\\experiments\\voices\\"
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
      }
   }
}

local function findRelevantInfos(recordType, race, gender)
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
