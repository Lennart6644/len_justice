Locales = Locales or {}

function Locale(key, ...)
    local language = Locales[Config.Language] or Locales.de
    local text = language[key] or Locales.de[key] or key
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end

function GetLocaleStrings()
    return Locales[Config.Language] or Locales.de
end
