import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import { Request } from 'express';

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Multer configuration for memory storage
const storage = multer.memoryStorage();

const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed!'));
    }
};

export const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max file size
    },
});

// Upload image to Cloudinary
export const uploadToCloudinary = async (
    buffer: Buffer,
    folder: string = 'wallpapers'
): Promise<{ url: string; thumbnailUrl: string; publicId: string }> => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                folder: `awg/${folder}`,
                resource_type: 'image',
                transformation: [
                    { quality: 'auto:best' },
                    { fetch_format: 'auto' },
                ],
            },
            (error, result) => {
                if (error) {
                    reject(error);
                } else if (result) {
                    // Generate thumbnail URL
                    const thumbnailUrl = cloudinary.url(result.public_id, {
                        width: 480,
                        height: 854,
                        crop: 'fill',
                        quality: 'auto',
                        fetch_format: 'auto',
                    });

                    resolve({
                        url: result.secure_url,
                        thumbnailUrl,
                        publicId: result.public_id,
                    });
                }
            }
        );

        uploadStream.end(buffer);
    });
};

// Delete image from Cloudinary
export const deleteFromCloudinary = async (publicId: string): Promise<void> => {
    await cloudinary.uploader.destroy(publicId);
};

export { cloudinary };
