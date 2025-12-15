
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Pack from '../src/models/Pack';
import Category from '../src/models/Category';
import Wallpaper from '../src/models/Wallpaper';

dotenv.config();

const syncCounts = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI is not defined');
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // Sync Pack Counts
        console.log('Syncing Pack counts...');
        const packs = await Pack.find({});
        for (const pack of packs) {
            const count = await Wallpaper.countDocuments({ packId: pack._id });
            if (pack.wallpaperCount !== count) {
                console.log(`Updating Pack "${pack.name}": ${pack.wallpaperCount} -> ${count}`);
                pack.wallpaperCount = count;
                await pack.save();
            }
        }
        console.log(`Synced ${packs.length} packs.`);

        // Sync Category Counts
        console.log('Syncing Category counts...');
        const categories = await Category.find({});
        for (const category of categories) {
            const count = await Wallpaper.countDocuments({ category: category._id });
            if (category.wallpaperCount !== count) {
                console.log(`Updating Category "${category.name}": ${category.wallpaperCount} -> ${count}`);
                category.wallpaperCount = count;
                await category.save();
            }
        }
        console.log(`Synced ${categories.length} categories.`);

        await mongoose.disconnect();
        console.log('Disconnected');
        process.exit(0);
    } catch (error) {
        console.error('Error syncing counts:', error);
        process.exit(1);
    }
};

syncCounts();
