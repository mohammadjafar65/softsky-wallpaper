import { AppDataSource } from "./src/data-source";
import { Wallpaper } from "./src/entities/Wallpaper";
import { IsNull } from "typeorm";

async function run() {
    await AppDataSource.initialize();
    const repo = AppDataSource.getRepository(Wallpaper);
    const wallpapers = await repo.find({ where: { sourceUrl: IsNull() }, take: 20 });
    console.log("Old wallpapers without sourceUrl:");
    wallpapers.forEach(w => console.log(`- ${w.title} (Cat: ${w.categoryId})`));
    process.exit(0);
}

run().catch(console.error);
