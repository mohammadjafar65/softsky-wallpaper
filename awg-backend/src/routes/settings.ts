import { Router } from "express";
import fs from "fs/promises";
import path from "path";
import { authenticate, requireAdmin, AuthRequest } from "../middleware/auth";

type AppSettings = {
    appName: string;
    supportEmail: string;
    contactEmail: string;
    privacyPolicyUrl: string;
    termsUrl: string;
    androidPackageName: string;
    minAppVersion: string;
    latestAppVersion: string;
    forceUpdate: boolean;
    maintenanceMode: boolean;
    maintenanceMessage: string;
    freeDownloadLimitPerDay: number;
    proDownloadLimitPerDay: number;
    enableNotifications: boolean;
    enableSubscriptions: boolean;
    enableWideWallpapers: boolean;
    defaultNotificationTitle: string;
    defaultNotificationMessage: string;
    updatedAt?: string;
};

const router = Router();

const settingsPath =
    process.env.SETTINGS_FILE_PATH ||
    path.join(process.cwd(), "data", "settings.json");

const defaultSettings: AppSettings = {
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

const publicKeys: Array<keyof AppSettings> = [
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

async function readSettings(): Promise<AppSettings> {
    try {
        const raw = await fs.readFile(settingsPath, "utf8");
        return { ...defaultSettings, ...JSON.parse(raw) };
    } catch (error: any) {
        if (error.code !== "ENOENT") {
            console.error("Read settings error:", error);
        }
        return { ...defaultSettings };
    }
}

async function writeSettings(settings: AppSettings) {
    await fs.mkdir(path.dirname(settingsPath), { recursive: true });
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2), "utf8");
}

function toBoolean(value: unknown, fallback: boolean) {
    if (typeof value === "boolean") return value;
    if (value === "true") return true;
    if (value === "false") return false;
    return fallback;
}

function toNonNegativeNumber(value: unknown, fallback: number) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed < 0) return fallback;
    return Math.floor(parsed);
}

function sanitizeSettings(body: Partial<AppSettings>, current: AppSettings): AppSettings {
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
        freeDownloadLimitPerDay: toNonNegativeNumber(
            body.freeDownloadLimitPerDay,
            current.freeDownloadLimitPerDay
        ),
        proDownloadLimitPerDay: toNonNegativeNumber(
            body.proDownloadLimitPerDay,
            current.proDownloadLimitPerDay
        ),
        enableNotifications: toBoolean(body.enableNotifications, current.enableNotifications),
        enableSubscriptions: toBoolean(body.enableSubscriptions, current.enableSubscriptions),
        enableWideWallpapers: toBoolean(body.enableWideWallpapers, current.enableWideWallpapers),
        defaultNotificationTitle: String(
            body.defaultNotificationTitle ?? current.defaultNotificationTitle
        ).trim(),
        defaultNotificationMessage: String(
            body.defaultNotificationMessage ?? current.defaultNotificationMessage
        ).trim(),
        updatedAt: new Date().toISOString(),
    };
}

router.get("/public", async (req, res) => {
    try {
        const settings = await readSettings();
        const publicSettings = publicKeys.reduce((acc, key) => {
            acc[key] = settings[key] as never;
            return acc;
        }, {} as Partial<AppSettings>);

        res.json({ settings: publicSettings });
    } catch (error) {
        res.status(500).json({ error: "Failed to load settings" });
    }
});

router.get("/", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const settings = await readSettings();
        res.json({ settings });
    } catch (error) {
        res.status(500).json({ error: "Failed to load settings" });
    }
});

router.put("/", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const current = await readSettings();
        const settings = sanitizeSettings(req.body, current);
        await writeSettings(settings);
        res.json({ message: "Settings updated successfully", settings });
    } catch (error) {
        console.error("Update settings error:", error);
        res.status(500).json({ error: "Failed to update settings" });
    }
});

export default router;
