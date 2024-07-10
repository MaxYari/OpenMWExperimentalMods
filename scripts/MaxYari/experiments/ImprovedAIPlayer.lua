local core = require("openmw.core")
local ui = require("openmw.ui")

if core.API_REVISION < 63 then
    return ui.showMessage("Mercy: CAO requiers a newer version of OpenMW, please update.")
end
