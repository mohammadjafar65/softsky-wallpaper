"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const promises_1 = __importDefault(require("fs/promises"));
const path_1 = __importDefault(require("path"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const settingsPath = process.env.SETTINGS_FILE_PATH ||
    path_1.default.join(process.cwd(), "data", "settings.json");
const defaultSettings = {
    appName: "SoftSky Wallpaper",
    supportEmail: "support@softsky.studio",
    contactEmail: "contact@softsky.studio",
    privacyPolicyUrl: "https://softskyadmin.softsky.studio/privacy-policy.html",
    termsUrl: "https://softskyadmin.softsky.studio/terms",
    androidPackageName: "com.awg.awg_wallpaper",
    minAppVersion: "1.0.0",
    latestAppVersion: "1.0.0",
    forceUpdate: false,
    maintenanceMode: false,
    maintenanceMessage: "SoftSky is under maintenance. Please try again shortly.",
    freeDownloadLimitPerDay: 20,
    proDownloadLimitPerDay: 0,
    enableNotifications: true,
    enableSubscriptions: true,
    enableWideWallpapers: true,
    defaultNotificationTitle: "Fresh wallpapers are live",
    defaultNotificationMessage: "Open SoftSky to explore the newest collection.",
};
const publicKeys = [
    "appName",
    "supportEmail",
    "contactEmail",
    "privacyPolicyUrl",
    "termsUrl",
    "androidPackageName",
    "minAppVersion",
    "latestAppVersion",
    "forceUpdate",
    "maintenanceMode",
    "maintenanceMessage",
    "freeDownloadLimitPerDay",
    "proDownloadLimitPerDay",
    "enableNotifications",
    "enableSubscriptions",
    "enableWideWallpapers",
];
async function readSettings() {
    try {
        const raw = await promises_1.default.readFile(settingsPath, "utf8");
        return { ...defaultSettings, ...JSON.parse(raw) };
    }
    catch (error) {
        if (error.code !== "ENOENT") {
            console.error("Read settings error:", error);
        }
        return { ...defaultSettings };
    }
}
async function writeSettings(settings) {
    await promises_1.default.mkdir(path_1.default.dirname(settingsPath), { recursive: true });
    await promises_1.default.writeFile(settingsPath, JSON.stringify(settings, null, 2), "utf8");
}
function toBoolean(value, fallback) {
    if (typeof value === "boolean")
        return value;
    if (value === "true")
        return true;
    if (value === "false")
        return false;
    return fallback;
}
function toNonNegativeNumber(value, fallback) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed < 0)
        return fallback;
    return Math.floor(parsed);
}
function sanitizeSettings(body, current) {
    return {
        ...current,
        appName: String(body.appName ?? current.appName).trim() || current.appName,
        supportEmail: String(body.supportEmail ?? current.supportEmail).trim(),
        contactEmail: String(body.contactEmail ?? current.contactEmail).trim(),
        privacyPolicyUrl: String(body.privacyPolicyUrl ?? current.privacyPolicyUrl).trim(),
        termsUrl: String(body.termsUrl ?? current.termsUrl).trim(),
        androidPackageName: String(body.androidPackageName ?? current.androidPackageName).trim(),
        minAppVersion: String(body.minAppVersion ?? current.minAppVersion).trim(),
        latestAppVersion: String(body.latestAppVersion ?? current.latestAppVersion).trim(),
        forceUpdate: toBoolean(body.forceUpdate, current.forceUpdate),
        maintenanceMode: toBoolean(body.maintenanceMode, current.maintenanceMode),
        maintenanceMessage: String(body.maintenanceMessage ?? current.maintenanceMessage).trim(),
        freeDownloadLimitPerDay: toNonNegativeNumber(body.freeDownloadLimitPerDay, current.freeDownloadLimitPerDay),
        proDownloadLimitPerDay: toNonNegativeNumber(body.proDownloadLimitPerDay, current.proDownloadLimitPerDay),
        enableNotifications: toBoolean(body.enableNotifications, current.enableNotifications),
        enableSubscriptions: toBoolean(body.enableSubscriptions, current.enableSubscriptions),
        enableWideWallpapers: toBoolean(body.enableWideWallpapers, current.enableWideWallpapers),
        defaultNotificationTitle: String(body.defaultNotificationTitle ?? current.defaultNotificationTitle).trim(),
        defaultNotificationMessage: String(body.defaultNotificationMessage ?? current.defaultNotificationMessage).trim(),
        updatedAt: new Date().toISOString(),
    };
}
router.get("/public", async (req, res) => {
    try {
        const settings = await readSettings();
        const publicSettings = publicKeys.reduce((acc, key) => {
            acc[key] = settings[key];
            return acc;
        }, {});
        res.json({ settings: publicSettings });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to load settings" });
    }
});
router.get("/", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const settings = await readSettings();
        res.json({ settings });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to load settings" });
    }
});
router.put("/", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const current = await readSettings();
        const settings = sanitizeSettings(req.body, current);
        await writeSettings(settings);
        res.json({ message: "Settings updated successfully", settings });
    }
    catch (error) {
        console.error("Update settings error:", error);
        res.status(500).json({ error: "Failed to update settings" });
    }
});
exports.default = router;
//# sourceMappingURL=settings.js.map