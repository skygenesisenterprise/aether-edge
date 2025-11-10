import { z } from "zod";

export const DeviceInfoSchema = z.object({
    hardwareId: z.string(),
    model: z.string(),
    manufacturer: z.string(),
    firmwareVersion: z.string(),
    serialNumber: z.string(),
    capabilities: z.array(z.string()),
    lastSeen: z.date().optional(),
    status: z.enum(["online", "offline", "maintenance"]),
});

export type DeviceInfo = z.infer<typeof DeviceInfoSchema>;

export class DeviceManager {
    private devices: Map<string, DeviceInfo> = new Map();

    public registerDevice(device: DeviceInfo): void {
        this.devices.set(device.hardwareId, {
            ...device,
            lastSeen: new Date(),
            status: "online"
        });
    }

    public getDevice(hardwareId: string): DeviceInfo | undefined {
        return this.devices.get(hardwareId);
    }

    public updateDeviceStatus(hardwareId: string, status: DeviceInfo["status"]): void {
        const device = this.devices.get(hardwareId);
        if (device) {
            device.status = status;
            device.lastSeen = new Date();
        }
    }

    public listDevices(): DeviceInfo[] {
        return Array.from(this.devices.values());
    }

    public removeDevice(hardwareId: string): boolean {
        return this.devices.delete(hardwareId);
    }

    public getDevicesByStatus(status: DeviceInfo["status"]): DeviceInfo[] {
        return this.listDevices().filter(device => device.status === status);
    }

    public isDeviceSupported(hardwareId: string): boolean {
        const device = this.getDevice(hardwareId);
        return device ? device.capabilities.includes("aether-edge") : false;
    }
}