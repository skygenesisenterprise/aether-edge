import { db, hostMeta, HostMeta } from "@server/db";
import { setHostMeta } from "@server/lib/hostMeta";

const keyTypes = ["device"] as const;
export type LicenseKeyType = (typeof keyTypes)[number];

const keyTiers = ["device"] as const;
export type LicenseKeyTier = (typeof keyTiers)[number];

export type LicenseStatus = {
    isDeviceLicensed: boolean;
    isLicenseValid: boolean;
    deviceId: string;
    tier?: LicenseKeyTier;
    hardwareId?: string;
};

export type LicenseKeyCache = {
    licenseKey: string;
    licenseKeyEncrypted: string;
    valid: boolean;
    iat?: Date;
    type?: LicenseKeyType;
    tier?: LicenseKeyTier;
    terminateAt?: Date;
    hardwareId?: string;
};

export class License {
    private serverSecret!: string;

    constructor(private hostMeta: HostMeta) {}

    public async check(): Promise<LicenseStatus> {
        return {
            deviceId: this.hostMeta.hostMetaId,
            isDeviceLicensed: true, // Device version is always licensed for hardware
            isLicenseValid: true,
            tier: "device"
        };
    }

    public setServerSecret(secret: string) {
        this.serverSecret = secret;
    }

    public async isUnlocked() {
        return true; // Device version is always unlocked for hardware integration
    }

    public async validateDevice(hardwareId: string): Promise<boolean> {
        // For hardware device validation
        // This can be extended with specific hardware validation logic
        return true;
    }

    public getDeviceCapabilities() {
        return {
            maxTunnels: 100,
            supportsHardwareAcceleration: true,
            supportsEmbeddedMode: true,
            supportsOfflineMode: true,
            maxConcurrentConnections: 50
        };
    }
}

await setHostMeta();