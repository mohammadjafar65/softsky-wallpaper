"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.cloudinary = exports.deleteFromCloudinary = exports.uploadToCloudinary = exports.upload = void 0;
const multer_1 = __importDefault(require("multer"));
const cloudinary_1 = require("cloudinary");
Object.defineProperty(exports, "cloudinary", { enumerable: true, get: function () { return cloudinary_1.v2; } });
// Configure Cloudinary
cloudinary_1.v2.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});
// Multer configuration for memory storage
const storage = multer_1.default.memoryStorage();
const fileFilter = (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    }
    else {
        cb(new Error('Only image files are allowed!'));
    }
};
exports.upload = (0, multer_1.default)({
    storage,
    fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max file size
    },
});
// Upload image to Cloudinary
const uploadToCloudinary = async (buffer, folder = 'wallpapers') => {
    return new Promise((resolve, reject) => {
        console.log(`Starting Cloudinary upload to folder: awg/${folder}`);
        const uploadStream = cloudinary_1.v2.uploader.upload_stream({
            folder: `awg/${folder}`,
            resource_type: 'image',
            transformation: [
                { quality: 'auto:best' },
                { fetch_format: 'auto' },
            ],
        }, (error, result) => {
            if (error) {
                console.error("Cloudinary upload failed:", error);
                reject(error);
            }
            else if (result) {
                console.log("Cloudinary upload success:", result.public_id);
                // Generate thumbnail URL
                const thumbnailUrl = cloudinary_1.v2.url(result.public_id, {
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
        });
        uploadStream.end(buffer);
    });
};
exports.uploadToCloudinary = uploadToCloudinary;
// Delete image from Cloudinary
const deleteFromCloudinary = async (publicId) => {
    await cloudinary_1.v2.uploader.destroy(publicId);
};
exports.deleteFromCloudinary = deleteFromCloudinary;
//# sourceMappingURL=upload.js.map