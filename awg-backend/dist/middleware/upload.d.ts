import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
export declare const upload: multer.Multer;
export declare const uploadToCloudinary: (buffer: Buffer, folder?: string) => Promise<{
    url: string;
    thumbnailUrl: string;
    publicId: string;
}>;
export declare const deleteFromCloudinary: (publicId: string) => Promise<void>;
export { cloudinary };
//# sourceMappingURL=upload.d.ts.map