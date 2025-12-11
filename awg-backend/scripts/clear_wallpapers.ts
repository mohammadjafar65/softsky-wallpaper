
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Wallpaper from '../src/models/Wallpaper';

dotenv.config();

const clearData = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI is not defined');
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const result = await Wallpaper.deleteMany({});
        console.log(`Deleted ${result.deletedCount} wallpapers`);

        await mongoose.disconnect();
        console.log('Disconnected');
        process.exit(0);
    } catch (error) {
        console.error('Error clearing data:', error);
        process.exit(1);
    }
};

clearData();
