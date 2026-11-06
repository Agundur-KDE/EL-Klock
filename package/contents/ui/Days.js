// SPDX-License-Identifier: GPL-3.0-only
// Names: EL Wiki Special_Days (2026-11-06); Day of Alchemy also observed in Mercator.
var catalog = [
    {
        "name": "Acid Rain Day",
        "group": "BAD DAYS"
    },
    {
        "name": "Day of Alchemy",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Aleksei Stakhanov",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Alfred Nobel",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Armor",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Bones",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Evanescence",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Faster Respawns",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Fasting",
        "group": "BAD DAYS"
    },
    {
        "name": "Day of half Cooldowns",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Invasions",
        "group": "OTHER DAYS"
    },
    {
        "name": "Day of Joule",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Magic",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Mana",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Manufacturing",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of More Grief",
        "group": "OTHER DAYS"
    },
    {
        "name": "Day of Murphy",
        "group": "BAD DAYS"
    },
    {
        "name": "Day of Mushrooms",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of No Grief",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of No Rostogols",
        "group": "BAD DAYS"
    },
    {
        "name": "Day of Positivity",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Recycling",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Robin Tell",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Running",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Schools",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Stronger Animals and Monsters",
        "group": "OTHER DAYS"
    },
    {
        "name": "Day of Summoners",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Sun Tzu",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of Tailoring",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of the Brave",
        "group": "BAD DAYS"
    },
    {
        "name": "Day of the Dead",
        "group": "OTHER DAYS"
    },
    {
        "name": "Day of the Horses",
        "group": "GOOD DAYS"
    },
    {
        "name": "Day of the Print",
        "group": "GOOD DAYS"
    },
    {
        "name": "Decreased Harvesting Events Day",
        "group": "OTHER DAYS"
    },
    {
        "name": "Decreased Rare Manufacturing day",
        "group": "OTHER DAYS"
    },
    {
        "name": "Green Day",
        "group": "BAD DAYS"
    },
    {
        "name": "Healing Day",
        "group": "GOOD DAYS"
    },
    {
        "name": "Increased Harvesting Events Day",
        "group": "OTHER DAYS"
    },
    {
        "name": "Increased rare manufacturing day",
        "group": "GOOD DAYS"
    },
    {
        "name": "Labour Day",
        "group": "BAD DAYS"
    },
    {
        "name": "Leonard's Day",
        "group": "OTHER DAYS"
    },
    {
        "name": "No Drops Day",
        "group": "OTHER DAYS"
    },
    {
        "name": "Non Stop Day",
        "group": "GOOD DAYS"
    },
    {
        "name": "Peace Day",
        "group": "OTHER DAYS"
    },
    {
        "name": "Reconstruction Day",
        "group": "GOOD DAYS"
    },
    {
        "name": "Scholars Day",
        "group": "GOOD DAYS"
    },
    {
        "name": "Scientists Day",
        "group": "GOOD DAYS"
    },
    {
        "name": "Scotty's Vacation",
        "group": "OTHER DAYS"
    },
    {
        "name": "Solar Flares Day",
        "group": "BAD DAYS"
    }
];

function key(name) {
    return String(name || "").trim().toLowerCase().replace(/’/g, "\'").replace(/\s+/g, " ");
}

function selected(name, names) {
    return names.some(function(candidate) { return key(candidate) === key(name); });
}
